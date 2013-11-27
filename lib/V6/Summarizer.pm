package V6::Summarizer;
use Moose;
use V6::DB;
use Clone qw(clone);
use Geo::IP;
use Data::Dump qw(pp);
use DateTime ();
use namespace::clean;

my $gi = Geo::IP->new(GEOIP_STANDARD);

has version => (
    is   => 'ro',
    isa  => 'Int',
    lazy_build => 1,
);

sub _build_version {
    my $self = shift;

    #my $db = V6::DB->mongodb;
    my $version = 1;

    return $version;
}

sub process_entry {
    my ($self, $entry) = @_;

    # TODO: check that site is valid...
    return unless $entry->{site};

    #print "I: ", pp($entry), "\n";

    for my $t (qw(ipv4 ipv6 ipv64)) {
        $entry->{$t} = undef
          if ($entry->{$t}
              and $entry->{$t} =~ m/^(undefined|error)$/);
    }

    # TODO: check against the hostname for the test
    return if !($entry->{ipv4} and $entry->{ipv4_ip});

    # TODO: filter on site's preferences


    my $can_ipv6  = $entry->{ipv6}  ? 1 : 0;
    my $can_ipv64 = $entry->{ipv64} ? 1 : 0;

    # TODO: get country
    my $country   = $gi->country_code_by_addr($entry->{ipv4_ip});
    $country      = $country && lc $country;

    my $site      = $entry->{site};
    my $dt        = DateTime->from_epoch(epoch => $entry->{time});
    my $date      = $dt->ymd;

    # TODO: user agent?

    my %data = ( ipv4 => 1, ipv6 => $can_ipv6, ipv64 => $can_ipv64 );

    my $mdb = V6::DB->instance->mongodb;
    my $daily_coll = $mdb->get_collection('counts_daily');
    my $count_coll = $mdb->get_collection('counts');

    for my $site ('*', $site) {
        for my $country ('*', $country) {
            my %d = ( %data, site => $site, country => $country );

            #print "O: ", pp(\%d), "\n";

            $daily_coll->update({ %d, date => $date },
                                {'$inc' => { count => 1 } },
                                {'upsert' => 1 }
                               );

            $count_coll->update({ %d, year => $dt->year, month => $dt->month },
                                {'$inc' => { count => 1 } },
                                {'upsert' => 1 }
                               );
        }
    }
}

sub has_data {
    my ($self, $args) = @_;
    my $site = $args->{site_id} || '*';
    my $coll = V6::DB->mongodb->get_collection('counts');
    my @data = $coll->query({ site => $site, country => '*' })->limit(1);
    return 1 if @data;
    return 0;
}

sub stats_by_month {
    my ($self, $args) = @_;

    my $site = $args->{site_id} || '*';

    my $coll = V6::DB->mongodb->get_collection('counts');
    my @data = $coll->query({ site => $site, country => '*' })->all;
    #warn pp(\@data);

    my %o;
    for my $d (@data) {
        my $k = sprintf "%04i-%02i", $d->{year}, $d->{month};

        $o{ $k }->{total} += $d->{count};

        if ( !$d->{ipv64} ) {
            $o{ $k }->{no_ipv64} += $d->{count};
        }
        if ( $d->{ipv6} ) {
            $o{ $k }->{ipv6} += $d->{count};
        }
    }

    my @stats;
    my %totals;
    for my $date (sort keys %o) {
        my $d = $o{$date};
        for my $k (keys %$d) {
            next if $k =~ m/_percent$/;

            $totals{ $k } += $d->{$k};

            next if $k eq 'total';
            my $total = $d->{total} || 1;
            my $percent = 100 / $total * $d->{$k};
            $d->{ "${k}_percent" } = sprintf "%1.1f", $percent;
        }
        push @stats, { date => $date, %$d };
    }

    for my $k (keys %totals) {
        next if $k =~ m/_percent$/;
        next if $k eq 'total';
        my $total = $totals{total} || 1;
        my $percent = 100 / $total * $totals{$k};
        $totals{ "${k}_percent" } = sprintf "%1.1f", $percent;
    }

    push @stats, { date => 'totals', %totals };

    warn pp(\@stats);

    return \@stats;
}

__PACKAGE__->meta()->make_immutable();
no Moose;


1;

