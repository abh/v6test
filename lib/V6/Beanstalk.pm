package V6::Beanstalk;

use strict;
use warnings;

use base 'Beanstalk::Client';

use V6::Config;

require JSON::XS;

my $config = V6::Config->new;

my $client; # singleton when no args passed to ->new

sub new {
    my $proto = shift;
    return $client if $client and !@_;
    my %args = (
        ttr      => 30,
        priority => 100,
        delay    => 0,
        server   => $config->beanstalk_server,
        encoder  => sub { JSON::XS::encode_json([shift]) },
        decoder  => sub { JSON::XS::decode_json(shift)->[0] },
        @_,
    );
    (@_ ? my $c : $client) = $proto->SUPER::new(\%args);
}

1;
