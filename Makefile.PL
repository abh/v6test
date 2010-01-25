#!/usr/bin/env perl

use 5.008001;

use strict;
use warnings;

# Son, when you participate in sporting events,
# it's not whether you win or lose, it's how drunk you get.
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'V6',
    VERSION_FROM => 'lib/V6.pm',
    AUTHOR       => 'Ask Bjørn Hansen <ask@develooper.com>',
    EXE_FILES => ['script/v6'],
    PREREQ_PM => { 'Mojo' => '0.9003',
                   'MojoX::Session::Store::MongoDB' => 0.51,
                   'MojoX::Session' => 0.15,
                   'File::Slurp' => 0,
                   'JSON::XS'    => 2.20,
                   'MongoDB'     => 0.20,
                   'Beanstalk::Client' => 1.05,
                   'Moose'       => 0,
                   'MooseX::Singleton' => 0,
                   'MooseX::Declare' => 0,
                   'Data::Transformer' => 0,
                   'File::HomeDir' => 0,
                   'File::Find::Rule' => 0,
                   'Net::API::RPX' => 0,
                   'IO::Socket::SSL' => 0,  # For Net::API::RPX
    },
    test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t'}
);

# Devel::Cover support
sub MY::postamble {
    qq/
testcover :
\tcover -delete && \
\tHARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) test && \
\tcover
/
}
