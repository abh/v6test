package V6::Controller;

use strict;
use warnings;

use Data::Dump qw(pp);

use base 'Mojolicious::Controller';

sub config {
    shift->app->config;
}

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
        # TODO: use Mojo::URL, like ...
        # my $base     = $self->req->url->base->clone;
        # my $location = Mojo::URL->new->base($base);
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
    $self->stash('js' => []) unless $self->stash('js');

    $self->stash->{user} = $self->user;
    my $session = $self->session;
    use Data::Dump qw(pp);
    warn pp($session);
    return $self->SUPER::render(@_);
}

sub token {
    my $self = shift;

    return '' unless $self->session->{user_id};
    
    $session->{token} ||= do {
        my $sha1 = Digest::SHA1->new;
        $sha1->add($$, time, rand(time));
        $sha1->hexdigest();
    };

    return $session->{token};
}

sub user {
    my $self = shift;
    my $user_id = $self->session->{'user_id'} or return;
    #warn "GOT USER_ID: $user_id";
    my $user = V6::User->lookup($user_id);
    warn "ERROR:", pp($@) if $@ and !$@->{missing} ;
    return $user;
}

sub render_json {
    my ($self, $json) = @_;
    $self->{template} = 'render.json';
    $self->stash->{json} = $json;
    return $self->render();
}

1;
