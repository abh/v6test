package V6::Controller::Home;

use strict;
use warnings;

use base 'V6::Controller';

# This action will render a template
sub index {
    my $self = shift;
    $self->render();
}

1;
