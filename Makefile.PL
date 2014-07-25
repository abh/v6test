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
    PREREQ_PM => { 'Mojolicious' => '4',
                   'File::Slurp' => 0,
                   'JSON::XS'    => 2.20,

                   'MongoDB'     => 0.30,

                   'KiokuDB'     => 0.41,
                   'KiokuDB::Backend::MongoDB' => 0.01,

                   'Beanstalk::Client' => 1.05,
                   'Moose'       => 0,
                   'MooseX::Singleton' => 0.22,
                   'DateTime'          => 0,
                   'Data::Transformer' => 0,
                   'File::HomeDir' => 0,
                   'File::Find::Rule' => 0,

                   # For Net::API::RPX
                   'Net::API::RPX' => 0,
                   'IO::Socket::SSL' => 0,
                   'LWP::Protocol::https' => 0,

                   'Log::Dispatch' => 0,
                   'Log::Dispatch::File::Stamped' => 0,

                   'Geo::IP'    => 0,
                   'Data::Dump' => 0,
                   'Clone'      => 0,

                   # For testing
                   'Scope::Guard' => 0,
                   'Text::SimpleTable' => 0,
    },
    test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t'}
);


sub MY::postamble {
    return <<'MAKE_FRAG';

.PHONY: testcover

testcover:
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) test
	cover

linux: v6test_linux_amd64

v6test_linux_amd64: *.go
	gox -osarch="linux/amd64"

push: linux
	rsync -avP v6test_linux_amd64 v6test@lax11.ntppool.net:bin/



MAKE_FRAG
}

