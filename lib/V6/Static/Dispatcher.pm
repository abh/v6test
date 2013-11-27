package V6::Static::Dispatcher;
use strict;
use Mojo::Base 'Mojolicious::Static';

sub serve {
    my ($self, $c, $rel) = @_;

    my $devel = $c->app->mode eq 'development' ? 1 : 0;

    if (!$devel and $rel =~ m{^(js/v\d+)/v6test\.js}) {
        $rel = "$1/v6test-min.js";
    }
    my $rv = $self->SUPER::serve($c, $rel);
    return $rv if $rv;

    my $res = $c->res;
    if ($rel eq 'i/t.gif') {
        my $no_cache = 's-max-age=0,max-age=0,private,no-cache';
        if ($c->req->headers->header('X-Varnish') and $c->app->config->proxy_mode) {
            $res->headers->header('Cache-Control', 's-maxage=315360000');
            $res->headers->header('X-Pass-Cache-Control',
                                  $no_cache
                                 );
        }
        else {
            $res->headers->header('Cache-Control', $no_cache);
        }
    }
    elsif (!$devel and $rel =~ m{js/.*\.js$}) {
        $res->headers->header('Cache-Control', 'max-age=7200');
    }
    elsif ($rel =~ m{(-min\.(css|js)|^favicon.ico)$}) {
        $res->headers->header('Cache-Control', 'max-age=7200');
    }
    return;
}


1;
