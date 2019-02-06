use Inline::Python3;
use Inline::Python3::PyModule;
use Inline::Python3::Interpolation;

use Test;

start-python;

subtest {
    ~&~ 'x = 789';
    is PyModule('__main__').x, 789;
}

is ~> '[1, 2, 3]', (1, 2, 3);

is (~> '1'), 1;

is (~> '1.5'), 1.5;

subtest {
    my $x = 6;
    is (~> '$x'), 6;
    is (~> '$x * 2'), 12;
}

subtest {
    my $ls = (1, 2, 4);

    is (~> '$ls'), (1, 2, 4);

    is (~> '$ls * 2'), (1, 2, 4, 1, 2, 4)
}

subtest {
    my $x = 666;

    subtest {
	my $x = 888;
	is (~> '$x'), 888;
    }
}

done-testing;
