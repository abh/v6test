package V6::Config;
use strict;
use warnings;
use JSON::XS;
use File::Slurp qw(read_file);

my $json = JSON::XS->new->relaxed(1);

sub load {
    my ($class, $app) = @_;

    my $file = $app->home . '/config.json';

    my $data = $json->decode(scalar read_file($file));

    return $data;
}


1;
