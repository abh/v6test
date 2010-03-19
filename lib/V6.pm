package V6;

use strict;
use warnings;

our $VERSION = '0.10';

use Mojolicious '0.999922';
use base 'Mojolicious';

use V6::Config;
use V6::Static::Dispatcher;

use V6::DB;
use V6::User;
use V6::User::Identity;
use V6::Util ();

__PACKAGE__->attr( config => sub { V6::Config->new }  );

# This method will run for each request
sub dispatch {
    my $self = shift;

    my $scope = V6::DB->db->new_scope;

    my $rv = $self->SUPER::dispatch(@_);

    my $l = $scope->live_objects;
    
    if ( 1 ) {
        my @live_objects = $l->live_objects;

        my $msg = "Loaded " . scalar(@live_objects) . " objects:\n" . V6::Util::format_leak_table(@live_objects);
        
        $self->log->debug($msg);
        
        @live_objects = ();
    }
    
    undef $scope;
    
    {
        # anything still live at this point is a leak
        if ( my @leaked_objects = $l->live_objects ) {
            $self->log->warn("leaked objects:\n" . V6::Util::format_leak_table(@leaked_objects));
        }
    }

    $l->clear();

    return $rv;
}

# This method will run once at server start
sub startup {
    my $self = shift;

    # force loading the config on startup
    $self->config;

    $self->secret( $self->config->secret );

    $self->static(bless $self->static, 'V6::Static::Dispatcher');

    $self->session->default_expiration( 86400 * 7 );
    $self->session->cookie_name('state');
    $self->session->cookie_domain($self->config->base_domain);

    # Default to ".ep" templates
    $self->renderer->default_handler('ep');

    $self->routes->namespace('V6::Controller');

    $self->types->type(html => 'text/html; charset=UTF-8');

    # Routes
    my $r = $self->routes;

    $r->route('/')->to(controller => 'home', action => 'index');

    $r->route('/c/:action')->to(controller => 'counter');

    # Default route
    $r->route('/:controller/:action')->to(action => 'index');
}


1;
