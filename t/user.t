#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use V6::User;
#use V6::User::Identity;
use V6::DB;
use Data::Dump qw(pp);
use KiokuDB::Backend::MongoDB;

use Text::SimpleTable;
 
sub format_table {
    my @objects = @_;
    require Text::SimpleTable;
    my $t = Text::SimpleTable->new( [ 60, 'Class' ], [ 8, 'Count' ] );
    my %counts;
    $counts{ref($_)}++ for @objects;
    foreach my $class ( sort { $counts{$b} <=> $counts{$a} } keys %counts ) {
        $t->row( $class, $counts{$class} );
    }
    return $t->draw;
}

my $db = V6::DB->db;

{
    ok(my $scope    = $db->new_scope, 'new scope');
    ok(my $user     = V6::User->new({ identities => [], foo => 'bar' }), "new user");
    ok($db->store($user), 'storing user');
    
#ok(my $identity = V6::User::Identity->new(identifier => 'http://test.develooper.com/', data => {}), "new identity");
#ok($user->identities([$identity]), "set identity on user");
#is($user, $identity->user, "identity has user");

    undef $user;
    undef $scope;

    my $l = $db->live_objects;
    my @live_objects = $l->live_objects;
    my $msg = "Loaded " . scalar(@live_objects) . " objects:\n" . format_table(@live_objects);
    warn "MSG: $msg";

}

{
    # anything still live at this point is a leak
    if ( my @leaked_objects = $db->live_objects ) {
        warn join "\n", map { pp($_) }  @leaked_objects;
        warn("leaked objects:\n" . format_table(@leaked_objects));
    }
}


done_testing();
