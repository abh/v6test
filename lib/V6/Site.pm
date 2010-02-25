package V6::Site;
use Moose;
use Data::Dump qw(pp);
use namespace::clean -except => 'meta';

with 'KiokuDB::Role::UUIDs';

with "V6::Schema::ID";

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

sub id { shift->url }

# ==============


has 'url' => (
    isa      => "Str",
    is       => "ro",
    required => 1,
);

has 'public_stats' => (
    isa      => "Bool",
    is       => "rw",
    default  => 0,
);


__PACKAGE__->meta->make_immutable;

1;
