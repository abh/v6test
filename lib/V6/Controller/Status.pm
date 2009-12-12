package V6::Controller::Status;

use strict;
use warnings;

use base 'V6::Controller';

sub index {
    my $self = shift;
    $self->res->headers->header('Cache-Control', 'private,max-age=0');
    # talk to beanstalkd
    # talk to mongodb
    return $self->render();
}

1;
