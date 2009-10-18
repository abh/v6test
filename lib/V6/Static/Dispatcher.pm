package V6::Static::Dispatcher;
use strict;
use base 'MojoX::Dispatcher::Static';

sub serve {
    my ($self, $c, $rel) = @_;

    my $devel = $c->app->mode eq 'development' ? 1 : 0;

    if (!$devel and $rel =~ m{^(js/v\d+)/v6test\.js}) {
        $rel = "$1/v6test-min.js";
    }
    my $rv = $self->SUPER::serve($c, $rel);
    return $rv if $rv;
    if (!$devel) {
        my $res = $c->res;
        $res->headers->header('Cache-Control', 'maxage=7200');
    }
    return;
}


1;

