use v6.c;
use LibraryMake;
use Shell::Command;

class Build {
    my $libdir = 'resources/libraries';
    
    method build($dir) {
	my %vars = get-vars($dir);
	%vars<source> = 'source';
	%vars<pyhelper> = to-library-path('pyhelper');
	%vars<perl6> = to-library-path('perl6');

	my $pyconfig = query-pyconfig-path;
	%vars<cflags> = chomp qqx/$pyconfig --cflags/;
	%vars<ldflags> = chomp qqx/$pyconfig --ldflags/;

	mkdir $libdir;

	process-makefile($dir, %vars);
	shell(%vars<MAKE>);
    }

    sub to-library-path($lib) {
	$*VM.platform-library-name("$libdir/$lib".IO)	
    }

    sub query-pyconfig-path {
	my $pyconfig = %*ENV<PYTHON_CONFIG> // do {
	    my $locate-pyconfig = 'which python3-config';
	    qqx/$locate-pyconfig/.lines.first;
	} // die 'error: failed to find the python3.*-config';

	if $pyconfig.&run('--help', :out, :err).exitcode != 0 {
	    die "error: failed to find the executable '$pyconfig'"	
	}

	$pyconfig
    }    
}
