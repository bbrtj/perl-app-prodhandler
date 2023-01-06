package App::ProdHandler;

use v5.10;
use strict;
use warnings;

1;

__END__

=head1 NAME

App::ProdHandler - a Perl script which sets up an environment for safer handling of production environments

=head1 SYNOPSIS

	# exports the script into the current directory
	prodhandler --self-export

	# copies the script to the server
	scp prodhandler myuser@remote:~/prodhandler

	# log into the server, create a directory for the current task
	ssh myuser@remote
	mkdir dirty_production_task

	# create prodhandler.conf file, which describes files to be altered
	echo "target /production/directory" >> dirty_production_task/prodhandler.conf
	echo "production/file.ext" >> dirty_production_task/prodhandler.conf

	# see what actions will be taken
	prodhandler --describe dirty_production_task

	# set up the environment for that task
	prodhandler dirty_production_task

	# recommended: verify the contents of .sh files
	cat dirty_production_task/*.sh

	# recommended: set up a git repository (if it is available)
	cd dirty_production_task
	git init
	git add -A
	git commit -m "Initial setup"

=head1 DESCRIPTION

This distribution provides C<prodhandler> script which can be used for per-task management of files which must be backed up before modification.

Suppose you must reproduce a bug that only happens undef a very specific environment. Or you have to quickly hotfix something and full release cycle will not be fast enough. Do you change live files? Or make copies as backups and then do modifications? Are you sure you restored all unwanted changes?

This script will set up a small working environment for you, which consists of:

=over

=item * a C<restore> directory, containing original files

=item * a C<deploy> directory, where you can make your changes

=item * C<restore.sh> script, which will restore original files from C<restore> directory

=item * C<deploy.sh> script, which will copy files to their locations from C<restore> directory

=item * C<diff.sh> script, which will check whether files in C<restore> directory differ from original files

=back

This environment is best made in your home directory, far away from actual production files.

=head2 Configuration

The list of files is set using C<prodhandler.conf> file. Each file is in its own line:

	/prod/lib/System.pm
	/prod/script.pl
	/etc/apache2/sites-available/mysite.conf

During copying the files to C<restore> and C<deploy> their paths are flattened, like so:

	__prod__lib__System.pm
	__prod__script.pl
	__etc__apache2__sites-available__mysite.conf

You can set targets in C<prodhandler.conf>:

	target /prod
		lib/System.pm
		script.pl
	target /etc/apache2
		sites-available/mysite.conf

Which will change the local paths like this:

	__prod/lib__System.pm
	__prod/script.pl
	__etc__apache2/sites-available__mysite.conf

Now two directories will be created: C<__prod> and C<__etc__apache2>. This way the directory structure of working copies can be less chaotic by maintaining context with a single directory for each target.

If files in your C<prodhandler.conf> contain whitespace, you will need to quote using either single or double quotes:

	target "/dir/with space"
		'file with space'

You can use relative paths in the configuration:

	../dir/file1
	target ../dir
		file2

These paths will end up like this:

	UP__dir__file1
	UP__dir/file2

They must be relative to the location of configuration file, not to the location from which you run C<prodhandler>! When in doubt, use absolute paths.

=head2 Scripts

C<prodhandler> script is only used once during initialization. After that, work is performed using generated shell scripts.

This design choice does two things:

=over

=item * lets you verify the contents of the files to see whether they do what is advertised and do not break anything else

=item * makes it trivial to do any modifications to deployment / restoration

=back

Both C<restore.sh> and C<deploy.sh> scripts copy each file back into their original locations from the corresponding directory, then change their mode, uid and gid back to what it was during the initialization. You might B<require root permissions> to run those scripts, depending on files' original locations and permissions.

C<diff.sh> script can be run to make sure file contents in C<restore> directory do not differ from original files. It is recommended to do that before running C<deploy.sh> script. If there are differences, it's possible that original files were updated in the meantime and current working environment needs to be initialized again.

=head2 Taking it with you

App::ProdHandler was written with the ability to take it with you in mind. It is fully compatible with perl 5.10.0, uses no non-core dependencies and is self-contained. You don't have to install the CPAN module on the target server (which is often hard or impossible). You can instead install the module locally, export the script and copy it into target server:

	cpanm App::ProdHandler
	prodhandler --self-export
	scp prodhandler myuser@remote:~/prodhandler

=head2 App::ProdHandler and git

If the server on which you want to use the application has git, it is highly recommended to initialize the repository and make a commit after initializing the working environment. This lets you:

=over

=item * double-check what changes were made before running C<deploy.sh>, by running C<git diff>

=item * export the changes, for example to also apply them to the application main repository, by running C<< git diff > changes.diff >>

=item * apply diffs from outside using C<git apply changes.diff>

=item * provide more content on when was this worked on

=item * many more...

=back

=head2 Portability

This module is meant to be used on Unix (Linux, BSD) servers. No effort was made to make it useful in other environments, mainly because the author only knows how to administer Unix servers.

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Bartosz Jarzyna

FreeBSD 2-clause license - see LICENSE

