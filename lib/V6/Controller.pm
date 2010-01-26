package V6::Controller;

use strict;
use warnings;

use Data::Dump qw(pp);

use MojoX::Session;
use MojoX::Session::Transport::Cookie;
use MojoX::Session::Store::MongoDB;

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
    $self->stash('widget_target' => '') unless $self->stash('widget_target');
    $self->stash('session' => $self->session) unless $self->stash('session');
    return $self->SUPER::render(@_);
}

sub session {
    my $self = shift;
    return $self->{_session} if $self->{_session};

    my $store = MojoX::Session::Store::MongoDB->new(
        {   database   => 'v6test',
            collection => 'sessions',
        }
    );

    my $transport = MojoX::Session::Transport::Cookie->new
      (domain => $self->app->config->base_domain);

    my $session = MojoX::Session->new
      (
       tx => $self->tx,
       store     => $store,
       transport => $transport,
       ip_match  => 0,
       expires_delta => 86400 * 3,
      );

    if ($session->load) {
        if ($session->is_expired) {
            $session->flush;
            $session->create;
        }
        else {
            $session->extend_expires;
        }
    }
    else {
        $session->create;
    }

    $session->data(
        token => do {
            my $sha1 = Digest::SHA1->new;
            $sha1->add($$, time, rand(time));
            $sha1->hexdigest();
        })
      unless $session->data('token');

    $session->flush();

    $self->stash(session => $session);

    return $self->{_session} = $session;
}

sub user {
    my $self = shift;
    my $user_id = $self->session->data('user_id') or return;
    my $s = V6::DB->db->new_scope;
    my $user = V6::User->lookup($user_id);
    warn "USER: $user";
    my $user = eval { V6::DB->db->lookup($user_id) };
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
