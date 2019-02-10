#!/usr/bin/env perl6

use v6.c;
use Inline::Python3;
use Inline::Python3::PyModule;

use Test;

start-python;

my $main = PyModule('__main__');

is $main.run('5', :eval), 5;
is $main.run('5.5', :eval), 5.5;
is $main.run('"Python"', :eval), 'Python';

subtest {
    for $main.run('[1, 2]', :eval).item -> $/ {
	is $/.elems, 2;
	is $0, 1;
	is $1, 2;
    }
}, 'simple list';

subtest {
    for $main.run('[1, [2, 3]]', :eval).item -> $/ {
	is $/.elems, 2;
	is $0, 1;

	is $1.elems, 2;
	is $1[0], 2;
	is $1[1], 3;	
    }
}, 'nested list';

subtest {
    for $main.run('{"a": 1, "b": 2}', :eval).item -> $/ {
	is $/.elems, 2;
	is $<a>, 1;
	is $<b>, 2;
    } 
}, 'simple map';

subtest {
    for $main.run('{"a": 1, "b": {"c": 3}}', :eval).item -> $/ {
	is $/.elems, 2;
	is $<a>, 1;
	is $<b>.elems, 1;
	is $<b><c>, 3;
    }
}, 'nested map';


subtest {
    for $main.run('[1, {"b": {"c": 3}}]', :eval).item -> $/ {
	is $/.elems, 2;
	is $0, 1;
	is $1.elems, 1;
	is $1<b>.elems, 1;
	is $1<b><c>, 3;
    }
}, 'mixed structure';

ok $main.run('None', :eval) === Any, 'py None maps to p6 Any';

is $main.run('
# coding=utf-8
u"Püthon"
', :eval), 'Püthon';

done-testing;
