#! /usr/bin/env perl6

use v6.c;
use Test;
use Inline::Python3;
use Inline::Python3::PyModule;

start-python;

my $main = PyModule('__main__');

$main.run(q:to/end/);
class Foo:
    count = 6
    def __init__(self):
        Foo.count += 1
    @staticmethod
    def const():
        return Foo.count
end

is $main<Foo>.count, 6, "access static variable without class instance";

is $main<Foo>.const, 6, "access static method without class instance";

is $main.Foo.count, 7, "access static variable with class instance";

is $main.Foo.const, 8, "access static method with class instance";

isnt $main<Foo><const>, 8, "access staticmethod without calling it";

$main.run(q:to/end/);
class Bar:
    def __init__(self, index):
        self.index = index
    def instance_method(self):
        return self.index
end

lives-ok {
    $main.Bar(1);
}, "instantiate class by dot function call";

dies-ok {
    $main.Bar;
}, "instantiate class by dot function call without enough parameters";

done-testing;
