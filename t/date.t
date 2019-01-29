#!/usr/bin/env perl6

use v6;
use lib <lib>;
use Inline::Python3;
use Test;

plan 2;

my $main = PyModule('__main__');

$main.run: 'import datetime';
my $main_date = $main.datetime.date(2017, 3, 1);

is $main_date.isoformat, '2017-03-01', 'can marshall datetime.date object';

my $main_datetime = $main.datetime.datetime(2017, 3, 1, 10, 7, 5);

is $main_datetime.isoformat, '2017-03-01T10:07:05', 'datetime.datetime';
