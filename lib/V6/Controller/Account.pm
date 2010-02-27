package V6::Controller::Account;

use strict;
use warnings;

use base 'V6::Controller';
use V6::DB;
use V6::User;
use V6::User::Identity;
use V6::Site;

use V6::Util qw(utf8_safe_tree);

use Net::API::RPX ();

use V6::Util qw(uniq);
use Data::Dump qw(pp);

use namespace::clean -except => 'meta';

my $rpx = Net::API::RPX->new({api_key => V6->config->rpx_api_key});
use Data::Dumper qw(Dumper);
warn Dumper(\$rpx);

my %trusted_providers = map { $_ => 1 } qw(Google Yahoo!);

sub index {
    my $self = shift;
    if ($self->user) {
        return $self->render('account/show');
    }
    $self->session;
    $self->session->flush;
    return $self->render();
}

sub logout {
    my $self = shift;
    $self->user(undef);
    $self->session->data(user_id => 0);
    $self->session->flush;
    
    return $self->redirect('/');
}

sub show {
    my $self = shift;
    # TODO: require login if no user
}

sub add {
    my $self = shift;
    my $token = $self->req->param('token');
    my $session_token = $self->session->data('token');
    unless ($token and $session_token and $token eq $session_token) {
        return $self->render_json({ error => 'Invalid token' });
    }
    my $name  = $self->req->param('name');

    my $user = $self->user;

    my $db = V6::DB->db;

    #if (my ($user_site) = grep { $_->site->url eq $url } @{ $user->user_sites } ) {
    #    $self->stash->{user_site} = $user_site;
    #    return $self->render_json({ url => $user_site->site->url, verified => $user_site->verified });
    #}
    
    # lookup if we already have a higher level page on the same domain and it's verified
    #  - add verified site and pass user there

    my $site = V6::Site->new({ name => $name, urls => [] });
    push @{ $user->sites }, $site;

    $db->store($site);
    $db->store($user);

    my $list = $self->render_partial('account/site_list');

    return $self->render_json({ name => $site->name, id => $site->id, site_list => $list });
}

sub verify_site {
    my $self = shift;
    my $url  = $self->req->param('url');
    my $user = $self->user;
}

sub token {
    my $self = shift;

    my $res = $self->res;
    my $req = $self->req;

    $res->headers->header('Cache-Control', 'private,max-age=0');

    my $token = $req->param('token');

    my $user_data = $token && eval { $rpx->auth_info({ token => $token }) };
    warn $@ if $@;

    $user_data = $user_data && $user_data->{profile};

    if (!$user_data) {
        $self->stash->{template} = 'account/login_error';
        return $self->render;
    }

    utf8_safe_tree($user_data);

    use Data::Dumper qw(Dumper);
    warn "USER DATA: ", Dumper(\$user_data);

    my $session = $self->session(1);

    # if user is already logged in and there's different user data
    #    does the new identifier already exist?
    #    yes? 
    #      login new identifier
    #    no?
    #      ask if new login should be added

    my $identity = eval { V6::DB->db->lookup("identity:" . $user_data->{identifier}) };
    my $user;
    unless ($identity) {
        $user = V6::User->new({identities => []});
        $identity = V6::User::Identity->new(
            data       => $user_data,
            identifier => $user_data->{identifier},
            user       => $user,
        );
        $user->identities([$identity]);
    }
    else {
        unless ($identity->user) {
            $user = V6::User->new({identities => []});
            $identity->user( $user );
        }
        $user = $identity->user;
        $user->identities([uniq @{$identity->user->identities}]);
        
        $identity->data($user_data);
    }

    V6::DB->db->store($identity);
    my $user_id = V6::DB->db->store($user);    

    #my $verified_email = $trusted_providers{$user_data->{providerName}}
    #  && $user_data->{verifiedEmail};

    $session->data(user_id => $user_id);
    $session->flush;

    my $url = $req->param('r') || '/account';
    return $self->redirect($url);

}


1;
