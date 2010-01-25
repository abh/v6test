package V6::Controller::Stats;

use strict;
use warnings;

use base 'V6::Controller';
use V6::DB;

sub index {
    my $self = shift;
    $self->res->headers->header('Cache-Control', 'private,max-age=0');

    my $coll = V6::DB->collection('results');

    my $data = {};

    $data->{count} = $coll->count;
    $self->stash('data', $data);
    return $self->render(data => $data);
}

1;
