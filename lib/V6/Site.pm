package V6::Site;
use Moose;
use Data::Dump qw(pp);
use V6::Summarizer;
use namespace::clean -except => 'meta';

sub lookup {
    my ($class, $id) = @_;
    return unless $id;
    $id = "site:$id" unless $id =~ m/^site:/;
    my $obj = eval { V6::DB->db->lookup($id) };
    warn "ERROR: ", pp($@) if $@ and !$@->message->message->{missing};
    return $obj;
}

sub kiokudb_object_id {
    my $self = shift;
    return "site:" . $self->id;
}

has id => (
    isa    => 'Str',
    is     => 'ro',
    lazy_build => 1,
);

with "V6::Schema::ID",
     "KiokuDB::Role::UUIDs" => { alias => { "generate_uuid" => "_build_id" } }; 

# ==============

has 'name' => (
    isa      => 'Str',
    is       => 'rw',
    required => 1,
);

has 'urls' => (
    traits   => ['Array'],
    isa      => "ArrayRef[Str]",
    is       => "rw",
    required => 1,
);

has 'public_stats' => (
    isa      => "Bool",
    is       => "rw",
    default  => 0,
);

sub stats_by_month {
    my $self = shift;
    my $summ = V6::Summarizer->new;
    return $summ->stats_by_month({ site_id => $self->id });
}

__PACKAGE__->meta->make_immutable;

1;
