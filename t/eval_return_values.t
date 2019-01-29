#!/usr/bin/env perl6

use v6.c;
use Inline::Python3;
use Test;

subtest {
    my $py = PyModule('__main__');
    is $py.run('5', :eval), 5;
    is $py.run('u"Python"', :eval), 'Python';
    is $py.run('"Python"', :eval), 'Python';
}, "Direct run values";

done-testing;
