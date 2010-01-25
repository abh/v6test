package V6::DB;
use MooseX::Singleton;
use KiokuDB;
use MongoDB;
use KiokuDB::Backend::MongoDB;
use Carp qw(croak);


has mongodb => (
    is   => 'ro',
    isa  => 'MongoDB::Database',
    lazy_build => 1,
);

sub _build_mongodb {

    # TODO: get db connection info from config...
    my $mongodb = MongoDB::Connection->new(host => 'localhost', port => 27017);

    my $db = $mongodb->get_database('v6test');
}

sub collection {
    my $self = shift;
    croak("no collection specified") unless @_;
    return $self->mongodb->get_collection(shift);
}

has db => (
    is   => 'ro',
    isa  => 'KiokuDB',
    lazy_build => 1,
);

sub _build_db {
    my $self       = shift;
    my $collection = $self->collection('kioku');
    my $mongo = KiokuDB::Backend::MongoDB->new('collection' => $collection);

    my $d = KiokuDB->new(backend => $mongo);

    return $d;
}


1;
