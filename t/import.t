#!/usr/bin/env perl6

use v6.c;
use Inline::Python3;
use Test;

my $string = PyModule('string', :import);

is $string.capwords('foo bar'), 'Foo Bar';

done-testing;
