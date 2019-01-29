#!/usr/bin/env perl6

use v6;
use lib <lib>;
use Inline::Python3;
use Test;

plan 3;

my $main = PyModule('__main__');

$main.run(q:heredoc/PYTHON/);
import logging
def call_something(something, param):
    return something(param)

def return_code(name):
    return lambda param: "%s %s" % (name, param)
PYTHON

sub something($suffix) {
    return 'Perl ' ~ $suffix;
}

is $main.call_something(&something, 6), 'Perl 6';
is $main.return_code('Perl')(5), 'Perl 5';
my $sub = $main.return_code('Foo');
is $main.call_something($sub, 1), 'Foo 1';

# vim: ft=perl6
