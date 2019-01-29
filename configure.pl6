#!/usr/bin/env perl6
use v6;
use LibraryMake;

my %vars = get-vars('.');

my $default-pyconfig = '/usr/bin/python3-config';

my $msg = "please input the path to python3-config
(default: $default-pyconfig):\n";

my $pyconfig = do given (prompt $msg) {
    $_.Bool ?? $_ !! $default-pyconfig	
}

if $pyconfig.&run('--help', :out, :err).exitcode != 0 {
    die "error: failed to find the executable '$pyconfig'"
}

%vars<source> = 'source';
%vars<pyhelper> = $*VM.platform-library-name('resources/libraries/pyhelper'.IO);
%vars<perl6> = $*VM.platform-library-name('resources/libraries/perl6'.IO);
%vars<cflags> = chomp qqx/$pyconfig --cflags/;
%vars<ldflags> = chomp qqx/$pyconfig --ldflags/;

mkdir 'resources' unless 'resources'.IO.e;
mkdir 'resources/libraries' unless 'resources/libraries'.IO.e;

process-makefile('.', %vars);
shell(%vars<MAKE>);
