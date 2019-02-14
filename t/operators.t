#!/usr/bin/env perl6

use v6.c;
use Test;
use Inline::Python3;
use Inline::Python3::PyModule;
use Inline::Python3::PyOperators;

start-python;

my $main = PyModule('__main__');

with try PyModule('numpy') {
    given (.arange(10), (0..9)) -> ($x, $y) {
	is $x.list, $y;
	is ($x ?** 2).list, $y.map(* ** 2);

	is (??~ $x).list, (-10..-1).reverse;
	is (??+ $x).list, $y;
	is (??- $x).list, $y.map(- *);

	is ($x ?* 2).list, $y.map(* * 2);
	is ($x ?/ 2).list, $y.map(* / 2);
	is ($x ?% 2).list, $y.map(* % 2);
	is ($x ??// 5).list, $y.map(* / 5).map(&floor);

	is ($x ?+ 2).list, $y.map(* + 2);
	is ($x ?- 2).list, $y.map(* - 2);
	is ($x ?>> 2).list, (0, 0, 0, 0, 1, 1, 1, 1, 2, 2);
	is ($x ?<< 2).list, (0,  4,  8, 12, 16, 20, 24, 28, 32, 36);

	is ($x ?& 5).list, (0, 1, 0, 1, 4, 5, 4, 5, 0, 1);

	is ($x ??^ 5).list, (5,  4,  7,  6,  1,  0,  3,  2, 13, 12);
	is ($x ??| 5).list, (5,  5,  7,  7,  5,  5,  7,  7, 13, 13);

	is ($x ?== 5).list, $y.map(* == 5);
	is ($x ?!= 5).list, $y.map(* != 5);

	is ($x ?<= 5).list, $y.map(* <= 5);
	is ($x ?< 5).list, $y.map(* < 5);	
	is ($x ?> 5).list, $y.map(* > 5);
	is ($x ?>= 5).list, $y.map(* >= 5);

	ok (Any ?is Any);
	ok (32 ?is-not Any);

	ok (3 ?in $x);
	ok (-1 ?not-in (1,2,3));

	nok (??not True);
	
	ok (False ?or True);
	nok (False ?or False);

	nok (False ?and False);
	nok (False ?and True);
	ok (True ?and True);
    }
}    

done-testing;
