#!/usr/bin/env perl6

use v6;
use lib <lib>;
use Inline::PythonObjects::PyInterface;
use Inline::PythonObjects;
use Test;

my $main = PyModule('__main__');

is $main.run('5', :eval), 5;
is $main.run('5.5', :eval), 5.5;
is $main.run('u"Python"', :eval), 'Python';
is-deeply $main.run('[1, 2]', :eval), [1, 2];
is-deeply $main.run('[1, [2, 3]]', :eval), [1, [2, 3]];
is-deeply $main.run('{u"a": 1, u"b": 2}', :eval), {a => 1, b => 2};
is-deeply $main.run('{u"a": 1, u"b": {u"c": 3}}', :eval), {a => 1, b => {c => 3}};
is-deeply $main.run('[1, {u"b": {u"c": 3}}]', :eval), [1, {b => {c => 3}}];
ok $main.run('None', :eval) === Any, 'py None maps to p6 Any';

is $main.run('
# coding=utf-8
u"Püthon"
', :eval), 'Püthon';

# not work
# Malformed UTF-8 at line 1 col 2

# is $main.run('
# # coding=utf-8
# "Püthon".encode("latin-1")
# ', :eval).decode('latin-1'), 'Püthon';

done-testing;

# vim: ft=perl6
