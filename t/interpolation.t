use Inline::Python3;
use Inline::Python3::PyModule;

use Test;

start-python;

subtest {
    ~>> 'x = 789';
    is PyModule('__main__').x, 789;
}

is-deeply (~> '[1, 2, 3]').list, (1, 2, 3);

is (~> '1'), 1;

is (~> '1.5'), 1.5;

subtest {
    my $x = 6;
    is (~> '$x'), 6;
    is (~> '$x * 2'), 12;
}

subtest {
    my $ls = (1, 2, 4);

    is-deeply (~> '$ls').list, (1, 2, 4);

    is-deeply (~> '$ls * 2').list, (1, 2, 4, 1, 2, 4)
}

subtest {
    my $x = 666;

    subtest {
	my $x = 888;
	is (~> '$x'), 888;
    }
}

subtest {
    ~>> q:to/end/;
    def func(x, y):
        return x + y
    end

    my ($x, $y) = 1, 2;
    is ~> 'func($x, $x)', 2;
    is ~> 'func($x, $y)', 3;
}

done-testing;
