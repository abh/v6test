package V6::Controller::Site;
use strict;
use warnings;

use base 'V6::Controller';
use V6::DB;
use V6::User;
use V6::User::Site;
use V6::User::Identity;
use V6::Site;

use namespace::clean -except => 'meta';

sub index {
    my $self = shift;
    my $site_id = $self->param('site');


    my $db = V6::DB->db;
    my $user = $self->user;

    my $site = eval { V6::Site->lookup($site_id) };
    return 404 unless $site;

    $self->stash('is_owner', $user && scalar grep { $site_id eq $_->id } @{ $user->sites } );
    $self->stash('site', $site);

    return 404 unless $self->stash('is_owner') or $site->public_stats;

    return $self->render;
    
}

sub code {
    my $self = shift;
    my $site_id = $self->param('site');

    my $site = eval { V6::Site->lookup($site_id) };
    return 404 unless $site;

    my $config = { };
    
    for my $f (qw(include_jquery ip_type)) {
        $config->{$f} = $self->param($f);
    }
    $self->stash(config => $config);
    $self->stash(site   => $site);

    my $code = $self->render_partial('_common/code');

    return $self->render_json({ code => $code });
}

1;

