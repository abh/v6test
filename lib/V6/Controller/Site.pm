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
    my $site_id = $self->param('site') 
      or return $self->render_not_found;

    my $db = V6::DB->db;
    my $user = $self->user;

    my $site = eval { V6::Site->lookup($site_id) };
    return $self->render_not_found unless $site;

    my $is_owner = $user && $user->is_owner($site_id);
    $self->stash('is_owner', $is_owner);
    $self->stash('site', $site);

    return $self->render_not_found
      unless $self->stash('is_owner') or $site->public_stats;

    return $self->render;
    
}

sub code {
    my $self = shift;
    my $site_id = $self->param('site');

    my $site = eval { V6::Site->lookup($site_id) };
    return $self->render_not_found unless $site;

    my $config = { };
    
    for my $f (qw(include_jquery ip_type)) {
        $config->{$f} = $self->param($f);
    }
    $self->stash(config => $config);
    $self->stash(site   => $site);

    my $code = $self->render_partial('_common/code');

    return $self->render_json({ code => $code });
}


sub statistics {
    my $self = shift;
    my $site_id = $self->param('site');

    my $site = eval { V6::Site->lookup($site_id) };
    return $self->render_not_found unless $site;

    return $self->render_json( { error => 'Forbidden' } )
      unless ($site->public_stats or ($self->user and $self->user->is_owner($site)));

    my $stats = $site->stats_by_month;

    use Data::Dump qw(pp);
    #warn pp($stats);

    if ($self->param('html')) {
        $self->stash('stats' => $stats);
        return $self->render('site/statistics');
    }

    return $self->render_json( { stats => $stats } );
}


1;

