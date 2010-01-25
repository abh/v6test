package V6::User;
use Moose;
use List::Util qw(first);
use namespace::clean -except => 'meta';

has 'identities' => (
    isa      => "ArrayRef[V6::User::Identity]",
    is       => "rw",
    required => 1,
); 

has 'sites' => (
    is      => 'rw',
    isa     => 'ArrayRef[V6::Site]',
    default => sub { [] },
);

sub name { 
    my $self = shift;
    return "" unless scalar $self->identities > 0;
    my ($name) = map { $_->name } first { $_->name } @{ $self->identities };
    warn "NAME: ", Data::Dump::pp($name);
    return $name || '';
}

1;
