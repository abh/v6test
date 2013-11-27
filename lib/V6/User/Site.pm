package V6::User::Site;
use Moose;
use namespace::clean -except => 'meta';

has 'site' => (
    isa      => "V6::Site",
    is       => "ro",
    required => 1,
);

has 'user' => (
    isa      => "V6::User",
    is       => "ro",
    required => 1,
);

has 'verified' => (
    isa      => "Bool",
    is       => "rw",
    default  => 0,
);

__PACKAGE__->meta->make_immutable;

1;
