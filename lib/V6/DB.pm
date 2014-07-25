package V6::DB;
use MooseX::Singleton;
use KiokuDB;
use MongoDB;
use KiokuDB::Backend::MongoDB;
use V6::Config;
use Carp qw(croak);
use namespace::clean;

has mongodb => (
    is   => 'ro',
    isa  => 'MongoDB::Database',
    lazy_build => 1,
);

sub _build_mongodb {

    my $mongodb = MongoDB::Connection->new( %{ V6::Config->new->mongodb_config },
					    find_master => 1 );

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

sub disconnect {
    my $self = shift;
    warn "$$ disconnecting";
    $self->db(undef);
    $self->_clear_instance;
}

1;
