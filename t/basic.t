#!/usr/bin/env perl

use strict;
use warnings;

#use Mojo::Client;
#use Mojo::Transaction::Single;
use Test::More tests => 1;

use_ok('V6');

# Prepare client and transaction
#my $client = Mojo::Client->new;
#my $tx     = Mojo::Transaction::Single->new_get('/');

# Process request
#$client->process_app('V6', $tx);

# Test response
#is($tx->res->code, 200);
#is($tx->res->headers->content_type, 'text/html');
#like($tx->res->content->asset->slurp, qr/Mojolicious Web Framework/i);
