#!/usr/bin/env perl6

use v6.c;
use Inline::Python3;
use Inline::Python3::PyModule;

use Test;

start-python;

my $string = PyModule('string', :import);

is $string.capwords('foo bar'), 'Foo Bar';

is py.string.capwords('foo bar'), 'Foo Bar';

done-testing;
