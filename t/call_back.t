#!/usr/bin/env perl6

use v6;
use Inline::Python3;
use Inline::Python3::PyModule;
use Test;

start-python;

my $main = PyModule('__main__');

$main.run(q:to/PYTHON/, :import);
from logging import warn
def test(obj):
    try:
        obj.ok(1)
    except Exception as e:
        warn(e)
    for i in range(5):
        retval = obj.test('Perl6')
        obj.ok(retval == 'Perl6')
        retval = obj.test('Perl6')
        obj.ok(retval == 'Perl6')
        retval = obj.test('Perl', 6)
        obj.ok(retval == ['Perl', 6])
PYTHON

class Foo {
    method ok($value) {
        ok($value);
    }
    method test(*@args) {
        return |@args;
    }
}

my $foo = Foo.new;

$foo.ok(1);

$main.test($foo);

done-testing;
