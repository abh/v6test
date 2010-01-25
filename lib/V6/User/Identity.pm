package V6::User::Identity;
use Moose;
use namespace::clean -except => 'meta';

with qw(V6::Schema::ID);

sub id_for_user {
    my ( $self, $id ) = @_;
    return "identity:$id"
}

sub kiokudb_object_id {
    my $self = shift;
    $self->id_for_user($self->id);
}

sub id { shift->identifier }

has 'identifier' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

has 'user' => (
    isa => 'V6::User',
    is  => 'rw',
    required => 1,
);

has 'data' => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
);

sub name {
    my $self = shift;
    return $self->data->{name}->{formatted}
      || $self->data->{displayName};
}

1;

