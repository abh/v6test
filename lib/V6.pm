package V6;

use strict;
use warnings;

use base 'Mojolicious';

use V6::Config;

__PACKAGE__->attr( config => sub { V6::Config->load(shift) }  );

# This method will run once at server start
sub startup {
    my $self = shift;

    # force loading the config on startup
    $self->config;

    # Default to ".ep" templates
    $self->renderer->default_handler('ep');

    $self->routes->namespace('V6::Controller');

    # Routes
    my $r = $self->routes;

    $r->route('/')->to(controller => 'home', action => 'index');

    $r->route('/c/:action')->to(controller => 'counter');

    # Default route
    $r->route('/:controller/:action')->to(action => 'index');
}

1;
