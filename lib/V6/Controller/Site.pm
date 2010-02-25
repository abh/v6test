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
    my $site_url = $self->param('site');
    warn "URL: ", $site_url;

    my $db = V6::DB->db;
    my $user = $self->user;

    my ($user_site) = grep { $_->site->url eq $url } @{ $user->user_sites };
    # if verified, show the details page
    
    # not verified, so:
    #   show the user-id / meta information

    # link to "check" page
    
    
}

sub verification_html {

}

sub check {
    # get user_id from session
    # get url from parameter
    # check verification, get meta tag / get html page

    # if valid,
    #    mark verified 
    #    go to details page

    # if not valid
    #    mark bad
    #    go to show verification info page

}

1;

