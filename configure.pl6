#!/usr/bin/env perl6
use v6;
use LibraryMake;

my %vars = get-vars('.');

my $python-config = ('/usr/bin/python3-config', '/usr/bin/python3-config').first({run($_, '--help', :err).exitcode == 0});

%vars<source> = 'source';
%vars<pyhelper> = $*VM.platform-library-name('resources/libraries/pyhelper'.IO);
%vars<perl6> = $*VM.platform-library-name('resources/libraries/perl6'.IO);
%vars<cflags> = chomp qqx/$python-config --cflags/;
%vars<ldflags> = chomp qqx/$python-config --ldflags/;

mkdir 'resources' unless 'resources'.IO.e;
mkdir 'resources/libraries' unless 'resources/libraries'.IO.e;

process-makefile('.', %vars);
shell(%vars<MAKE>);

# vim: ft=perl6
