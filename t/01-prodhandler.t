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
		if (ref $filename) {

			# handle later
			push @contents, $filename;
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

	if (uc ref $contents[1] eq 'REGEXP') {
		like $contents[0], $contents[1], "file $files[0] matches";
	}
	else {
		is $contents[0], $contents[1], "files seem to have the same content: @files";
	}
}

my $output;

rmtree TESTDIR;
mkdir TESTDIR;
copy('t/prodhandler.conf', TESTDIR . '/prodhandler.conf');

script_runs(
	[SCRIPT_PATH, TESTDIR], {
		stdout => \$output,
	},
	'script runs ok'
);

# no output in normal generation
is $output, '', 'output ok';

my %compare = (
	TESTDIR . '/restore/UP__data__f3.txt' => 't/data/f3.txt',
	TESTDIR . '/deploy/UP__data__f3.txt' => 't/data/f3.txt',
	TESTDIR . '/restore/UP__data__d1__d11/f1.txt' => 't/data/d1/d11/f1.txt',
	TESTDIR . '/deploy/UP__data__d1__d11/f1.txt' => 't/data/d1/d11/f1.txt',
	TESTDIR . '/restore/UP__data__d2__d21/f2.txt' => 't/data/d2/d21/f2.txt',
	TESTDIR . '/deploy/UP__data__d2__d21/f2.txt' => 't/data/d2/d21/f2.txt',
);

for my $key (keys %compare) {
	my $value = $compare{$key};

	files_content_same($key, $value);
}

files_content_same(
	TESTDIR . '/deploy.sh',
	qr{cp "deploy/UP__data__f3\.txt" "\.\./data/f3\.txt"
chmod 0\d{3} "\.\./data/f3\.txt"
chown \d+ "\.\./data/f3\.txt"
chgrp \d+ "\.\./data/f3\.txt"

cp "deploy/UP__data__d1__d11/f1\.txt" "\.\./data/d1/d11/f1\.txt"
chmod 0\d{3} "\.\./data/d1/d11/f1\.txt"
chown \d+ "\.\./data/d1/d11/f1\.txt"
chgrp \d+ "\.\./data/d1/d11/f1\.txt"

cp "deploy/UP__data__d2__d21/f2\.txt" "\.\./data/d2/d21/f2\.txt"
chmod 0\d{3} "\.\./data/d2/d21/f2\.txt"
chown \d+ "\.\./data/d2/d21/f2\.txt"
chgrp \d+ "\.\./data/d2/d21/f2\.txt"}
);

files_content_same(
	TESTDIR . '/restore.sh',
	qr{cp "restore/UP__data__f3\.txt" "\.\./data/f3\.txt"
chmod 0\d{3} "\.\./data/f3\.txt"
chown \d+ "\.\./data/f3\.txt"
chgrp \d+ "\.\./data/f3\.txt"

cp "restore/UP__data__d1__d11/f1\.txt" "\.\./data/d1/d11/f1\.txt"
chmod 0\d{3} "\.\./data/d1/d11/f1\.txt"
chown \d+ "\.\./data/d1/d11/f1\.txt"
chgrp \d+ "\.\./data/d1/d11/f1\.txt"

cp "restore/UP__data__d2__d21/f2\.txt" "\.\./data/d2/d21/f2\.txt"
chmod 0\d{3} "\.\./data/d2/d21/f2\.txt"
chown \d+ "\.\./data/d2/d21/f2\.txt"
chgrp \d+ "\.\./data/d2/d21/f2\.txt"}
);

files_content_same(
	TESTDIR . '/diff.sh',
	qr{echo "\.\./data/f3\.txt"
diff "restore/UP__data__f3\.txt" "\.\./data/f3\.txt"

echo "\.\./data/d1/d11/f1\.txt"
diff "restore/UP__data__d1__d11/f1\.txt" "\.\./data/d1/d11/f1\.txt"

echo "\.\./data/d2/d21/f2\.txt"
diff "restore/UP__data__d2__d21/f2\.txt" "\.\./data/d2/d21/f2\.txt"}
);

rmtree TESTDIR;

done_testing;

