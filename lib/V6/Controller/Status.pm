package V6::Controller::Status;

use strict;
use warnings;

use base 'V6::Controller';

# This action will render a template
sub index {
    my $self = shift;
    $self->res->headers->header('Cache-Control', 'private,max-age=0');
    return $self->render();
}

1;
