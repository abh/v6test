package V6;
our $VERSION = '0.10';

use Mojo::Base 'Mojolicious';

use V6::Config;

use V6::Static::Dispatcher;

use V6::DB;
use V6::User;
use V6::User::Identity;
use V6::Util ();

my $_config;
sub config {
    return $_config ||= do { V6::Config->new }
}

# This method will run for each request
sub dispatch {
    my $self = shift;

    my $scope = V6::DB->db->new_scope;

    my $rv = $self->SUPER::dispatch(@_);

    my $l = $scope->live_objects;

    if ( 0 ) {
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

    $self->secrets( [ $self->config->secret ] );

    $self->static(bless $self->static, 'V6::Static::Dispatcher');

    $self->sessions->default_expiration( 86400 * 7 );
    $self->sessions->cookie_name('state');
    $self->sessions->cookie_domain($self->config->base_domain);

    # Default to ".ep" templates
    $self->renderer->default_handler('ep');

    @{$self->routes->namespaces} = qw(V6::Controller);

    $self->types->type(html => 'text/html; charset=UTF-8');

    # Routes
    my $r = $self->routes;

    $r->route('/')->to(controller => 'home', action => 'index');

    $r->route('/c/:action')->to(controller => 'counter');

    #$r->route('/account/token')->to(controller => 'account', action => 'token');

    # Default route
    $r->route('/:controller/:action')->to(action => 'index');
}


1;
