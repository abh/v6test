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
    AUTHOR       => 'A Good Programmer <nospam@cpan.org>',
    EXE_FILES => ['script/v6'],
    PREREQ_PM => { 'Mojo' => '0.9003',
                   'File::Slurp' => 0,
                   'JSON::XS'    => 2.20,
                   'MongoDB'     => 0.20,
                   'Beanstalk::Client' => 1.05,
                   'Moose'       => 0,
                   'MooseX::Singleton' => 0,
                   'File::HomeDir' => 0,
    },
    test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t'}
);

# Devel::Cover support
sub MY::postamble {
    qq/
testcover :
\t cover -delete && \
   HARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) test && \
   cover
/
}
