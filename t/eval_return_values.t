#!/usr/bin/env perl6

use v6;
use lib <lib>;
use Inline::PythonObjects;
use Test;

plan 1;

subtest {
    my $py = PyModule('__main__');
    is $py.run('5', :eval), 5;
    is $py.run('u"Python"', :eval), 'Python';
    is $py.run('"Python"', :eval), 'Python';
}, "Direct run values";

# subtest {
#     is EVAL('5', :lang<Python>), 5;
#     is EVAL('u"Python"', :lang<Python>), 'Python';
#     is EVAL('"Python"', :lang<Python>).decode('latin-1'), 'Python';
# }, "EVAL returns values";

# vim: ft=perl6
