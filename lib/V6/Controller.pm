package V6::Controller;

use strict;
use warnings;

use base 'Mojolicious::Controller';

#sub config {
#    shift->app->config;
#}

sub redirect {
    my $self = shift;
    return $self->_redirect(302, @_);
}

sub perm_redirect {
    my $self = shift;
    return $self->_redirect(301, @_);
}

sub _redirect {
    my $self = shift;
    my $code = shift;
    my $url  = shift;

    unless ($url =~ m{^https?://}) {
        $url = $self->app->config->base_url . $url;
    }
 
    $self->res->code($code);
    $self->res->headers->location($url);
    $self->stash->{template} = 'redirect.html';
    my $msg = qq[
    <HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
    <TITLE>301 Moved</TITLE></HEAD><BODY><H1>301 Moved</H1>
    The document has moved <A HREF="$url">here</A>.</BODY></HTML>
    ];
    return $self->render_text($msg); 
}

sub render {
    my $self = shift;

    my $rv = eval { $self->SUPER::render(@_) };
    my $err = $@;

    my $content_type = $self->res->headers->header('Content-Type')
      or return $rv;
    $content_type .= "; charset=" . 'utf-8'
      if $content_type =~ m/^text/ and $content_type !~ m/charset=/;
    $self->res->headers->header('Content-Type', $content_type);

    die $err if $err;

    return $rv;
}

1;
