package V6::DB;
use strict;
use MongoDB;

# TODO: get db connection info from config...
my $mongodb = MongoDB::Connection->new(host => 'localhost', port => 27017);
my $db   = $mongodb->get_database('v6test');
my $coll = $db->get_collection('results');

sub collection {
    return $coll;
}



1;
