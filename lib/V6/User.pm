package V6::User;
use Moose;
use List::Util qw(first);
use Data::Dump qw(pp);
use namespace::clean -except => 'meta';

has id => (
    isa    => 'Str',
    is     => 'ro',
    lazy_build => 1,
);

with "V6::Schema::ID",
     "KiokuDB::Role::UUIDs" => { alias => { "generate_uuid" => "_build_id" } }; 

sub lookup {
    my ($class, $id) = @_;
    return unless $id;
    $id = "user:$id" unless $id =~ m/^user:/;
    my $user = eval { V6::DB->db->lookup($id) };
    warn "ERROR:", pp($@) if $@ and !$@->{missing};
    return $user;
}

sub id_for_user {
    my ( $self, $id ) = @_;
    warn "ID FOR USER: $id";
    return "user:$id"
}

sub kiokudb_object_id {
    my $self = shift;
    $self->id_for_user($self->id);
}

has 'identities' => (
    traits   => ['Array'],
    isa      => "ArrayRef[V6::User::Identity]",
    is       => "rw",
    required => 1,
); 

sub BUILD {
    my ($self, $params) = @_;
    if ($self->identities) {
        $self->_check_identities($self->identities);
    }
}

after 'identities' => sub {
    my ( $self, $identities ) = @_;
    $self->_check_identities($identities)
};

sub _check_identities {
    my ( $self, $identities ) = @_;
    warn "IDENTITIES are: ", ref $identities, pp($identities);
    if ($identities) {
        for my $identity ( @{$identities} ) {
            $identity->user($self);
        }
    }
}

has 'sites' => (
    is      => 'rw',
    isa     => 'ArrayRef[V6::Site]',
    default => sub { [] },
);

sub name { 
    my $self = shift;
    return "" unless scalar $self->identities > 0;
    my ($name) = map { $_->name } first { $_->name } @{ $self->identities };
    return $name || '';
}

__PACKAGE__->meta->make_immutable;

1;
