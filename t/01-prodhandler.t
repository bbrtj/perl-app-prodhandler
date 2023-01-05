use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Script;
use File::Path qw(rmtree);
use File::Copy qw(copy);

# Keep this commented out to avoid wide character print warnings. The testing
# code seems to work properly anyway
# use utf8;

use constant SCRIPT_PATH => 'bin/prodhandler';
use constant TESTDIR => 't/testdir';

sub files_content_same
{
	my (@files) = @_;

	die 'expected two filenames'
		unless @files == 2;

	my @contents;
	for my $filename (@files) {
		if (ref $filename eq 'SCALAR') {
			# this is not a file, but a string
			push @contents, $$filename;
		}
		elsif (open my $fh, '<', $filename) {
			local $/ = undef;
			push @contents, scalar readline $fh;
		}
		else {
			fail "file $filename failed to open: $!";
			return;
		}
	}

	is $contents[0], $contents[1], "files seem to have the same content: @files";
}

my $output;

rmtree TESTDIR;
mkdir TESTDIR;
copy('t/prodhandler.conf', TESTDIR . '/prodhandler.conf');

script_runs([SCRIPT_PATH, TESTDIR], {
	stdout => \$output,
}, 'script runs ok');

# no output in normal generation
is $output, '', 'output ok';

my %compare = (
	TESTDIR . '/restore/t__data__f3.txt' => 't/data/f3.txt',
	TESTDIR . '/deploy/t__data__f3.txt' => 't/data/f3.txt',
	TESTDIR . '/restore/t__data__d1__d11/f1.txt' => 't/data/d1/d11/f1.txt',
	TESTDIR . '/deploy/t__data__d1__d11/f1.txt' => 't/data/d1/d11/f1.txt',
	TESTDIR . '/restore/t__data__d2__d21/f2.txt' => 't/data/d2/d21/f2.txt',
	TESTDIR . '/deploy/t__data__d2__d21/f2.txt' => 't/data/d2/d21/f2.txt',
);

for my $key (keys %compare) {
	my $value = $compare{$key};

	files_content_same($key, $value);
}

files_content_same(TESTDIR . '/deploy.sh', \<<SHELL);
cp "deploy/t__data__f3.txt" "t/data/f3.txt"
chmod 0644 "t/data/f3.txt"
chown 1001 "t/data/f3.txt"
chgrp 1001 "t/data/f3.txt"

cp "deploy/t__data__d1__d11/f1.txt" "t/data/d1/d11/f1.txt"
chmod 0644 "t/data/d1/d11/f1.txt"
chown 1001 "t/data/d1/d11/f1.txt"
chgrp 1001 "t/data/d1/d11/f1.txt"

cp "deploy/t__data__d2__d21/f2.txt" "t/data/d2/d21/f2.txt"
chmod 0644 "t/data/d2/d21/f2.txt"
chown 1001 "t/data/d2/d21/f2.txt"
chgrp 1001 "t/data/d2/d21/f2.txt"

SHELL

files_content_same(TESTDIR . '/restore.sh', \<<SHELL);
cp "restore/t__data__f3.txt" "t/data/f3.txt"
chmod 0644 "t/data/f3.txt"
chown 1001 "t/data/f3.txt"
chgrp 1001 "t/data/f3.txt"

cp "restore/t__data__d1__d11/f1.txt" "t/data/d1/d11/f1.txt"
chmod 0644 "t/data/d1/d11/f1.txt"
chown 1001 "t/data/d1/d11/f1.txt"
chgrp 1001 "t/data/d1/d11/f1.txt"

cp "restore/t__data__d2__d21/f2.txt" "t/data/d2/d21/f2.txt"
chmod 0644 "t/data/d2/d21/f2.txt"
chown 1001 "t/data/d2/d21/f2.txt"
chgrp 1001 "t/data/d2/d21/f2.txt"

SHELL

files_content_same(TESTDIR . '/diff.sh', \<<SHELL);
echo "t/data/f3.txt"
diff "restore/t__data__f3.txt" "t/data/f3.txt"

echo "t/data/d1/d11/f1.txt"
diff "restore/t__data__d1__d11/f1.txt" "t/data/d1/d11/f1.txt"

echo "t/data/d2/d21/f2.txt"
diff "restore/t__data__d2__d21/f2.txt" "t/data/d2/d21/f2.txt"

SHELL

rmtree TESTDIR;

done_testing;

