#!/usr/bin/env perl6

use v6;
use lib <lib>;
use Inline::PythonObjects;
use Test;

my $main = PyModule('__main__');

$main.run(q:heredoc/PYTHON/);
class Foo(object):
    @staticmethod
    def test(x):
        return x
    def __init__(self, a, b):
        self.a = a
        self.b = b
    def concat(self, c):
        return self.a + c + self.b
PYTHON

is($main.Foo.test(1), 1);
is($main.Foo.test(x => 1), 1);
my $foo = $main.Foo(a => 'aa', b => 'bb');
is($foo.concat(c => '~'), 'aa~bb');

done-testing;

# vim: ft=perl6
