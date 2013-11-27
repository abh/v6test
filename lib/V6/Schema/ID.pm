package V6::Schema::ID;
use Moose::Role;

with qw(KiokuDB::Role::ID);

sub kiokudb_object_id { shift->id };

requires "id";

1;
