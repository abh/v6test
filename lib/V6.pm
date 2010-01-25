package V6;

use strict;
use warnings;

our $VERSION = '0.10';

use base 'Mojolicious';

use V6::Config;
use V6::Static::Dispatcher;

use V6::DB;
use V6::User;
use V6::User::Identity;

__PACKAGE__->attr( config => sub { V6::Config->new }  );

# This method will run once at server start
sub startup {
    my $self = shift;

    # force loading the config on startup
    $self->config;

    $self->static(bless $self->static, 'V6::Static::Dispatcher');

    # Default to ".ep" templates
    $self->renderer->default_handler('ep');

    $self->routes->namespace('V6::Controller');

    $self->types->type(html => 'text/html; charset=utf-8');

    # Routes
    my $r = $self->routes;

    $r->route('/')->to(controller => 'home', action => 'index');

    $r->route('/c/:action')->to(controller => 'counter');

    # Default route
    $r->route('/:controller/:action')->to(action => 'index');
}

1;
