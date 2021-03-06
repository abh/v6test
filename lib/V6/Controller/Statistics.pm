package V6::Controller::Statistics;

use strict;
use warnings;

use base 'V6::Controller';
use V6::DB;
use V6::Summarizer;

sub index {
    my $self = shift;
    $self->res->headers->header('Cache-Control', 's-maxage=120');

    my $coll = V6::DB->collection('results');

    my $summ = V6::Summarizer->new;
    my $stats = $summ->stats_by_month();

    use Data::Dump qw(pp);
    warn "==========";
    pp($stats);

    $self->stash('stats', $stats);
    return $self->render();
}

1;
