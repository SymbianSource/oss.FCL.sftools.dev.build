# Copyright (c) 2000 Ned Konz. All rights reserved.  This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

# $Revision: 1.5 $
package Archive::Zip::Archive;
use File::Find ();
use Archive::Zip qw(:ERROR_CODES :UTILITY_METHODS);

=head1 NAME

Archive::Zip::Tree -- methods for adding/extracting trees using Archive::Zip

=head1 SYNOPSIS

  use Archive::Zip;
  use Archive::Zip::Tree;
  my $zip = Archive::Zip->new();
  # add all readable files and directories below . as xyz/*
  $zip->addTree( '.', 'xyz' );	
  # add all readable plain files below /abc as /def/*
  $zip->addTree( '/abc', '/def', sub { -f && -r } );	
  # add all .c files below /tmp as stuff/*
  $zip->addTreeMatching( '/tmp', 'stuff', '\.c$' );
  # add all .o files below /tmp as stuff/* if they aren't writable
  $zip->addTreeMatching( '/tmp', 'stuff', '\.o$', sub { ! -w } );
  # and write them into a file
  $zip->writeToFile('xxx.zip');

  # now extract the same files into /tmpx
  $zip->extractTree( 'stuff', '/tmpx' );

=head1 METHODS

=over 4

=item $zip->addTree( $root, $dest [,$pred] )

$root is the root of the tree of files and directories to be added

$dest is the name for the root in the zip file (undef or blank means to use
relative pathnames)

C<$pred> is an optional subroutine reference to select files: it is passed the
name of the prospective file or directory using C<$_>,
and if it returns true, the file or
directory will be included.  The default is to add all readable files and
directories.

For instance, using

  my $pred = sub { /\.txt/ };
  $zip->addTree( '.', '.', $pred );

will add all the .txt files in and below the current directory,
using relative names, and making the names identical in the zipfile:

  original name           zip member name
  ./xyz                   xyz
  ./a/                    a/
  ./a/b                   a/b

To use absolute pathnames, just pass them in:

$zip->addTree( '/a/b', '/a/b' );

  original name           zip member name
  /a/                     /a/
  /a/b                    /a/b

To translate relative to absolute pathnames, just pass them in:

$zip->addTree( '.', '/c/d' );

  original name           zip member name
  ./xyz                   /c/d/xyz
  ./a/                    /c/d/a/
  ./a/b                   /c/d/a/b

To translate absolute to relative pathnames, just pass them in:

$zip->addTree( '/c/d', 'a' );

  original name           zip member name
  /c/d/xyz                a/xyz
  /c/d/a/                 a/a/
  /c/d/a/b                a/a/b

Returns AZ_OK on success.

Note that this will not follow symbolic links to directories.

Note also that this does not check for the validity of filenames.

=back

=cut

sub addTree
{
	my $self = shift;
	my $root = shift or return _error("root arg missing in call to addTree()");
	my $dest = shift || '';
	my $pred = shift || sub { -r };
	$root =~ s{\\}{/}g;	# normalize backslashes in case user is misguided
	$root =~ s{([^/])$}{$1/};	# append slash if necessary
	$dest =~ s{([^/])$}{$1/} if $dest;	# append slash if necessary
	my @files;
	File::Find::find( sub { push( @files, $File::Find::name ) }, $root );
	@files = grep { &$pred } @files;	# pass arg via local $_
	foreach my $fileName ( @files )
	{
		( my $archiveName = $fileName ) =~ s{^\Q$root}{$dest};
		$archiveName =~ s{^\./}{};
		next if $archiveName =~ m{^\.?/?$};	# skip current dir
		my $member = ( -d $fileName )
			? $self->addDirectory( $fileName, $archiveName )
			: $self->addFile( $fileName, $archiveName );
		return _error( "add $fileName failed in addTree()" ) if !$member;
	}
	return AZ_OK;
}

=over 4

=item $zip->addTreeMatching( $root, $dest, $pattern [,$pred] )

$root is the root of the tree of files and directories to be added

$dest is the name for the root in the zip file (undef means to use relative
pathnames)

$pattern is a (non-anchored) regular expression for filenames to match

$pred is an optional subroutine reference to select files: it is passed the
name of the prospective file or directory in C<$_>,
and if it returns true, the file or
directory will be included.  The default is to add all readable files and
directories.

To add all files in and below the current dirctory
whose names end in C<.pl>, and make them extract into a subdirectory
named C<xyz>, do this:

  $zip->addTreeMatching( '.', 'xyz', '\.pl$' )

To add all I<writable> files in and below the dirctory named C</abc>
whose names end in C<.pl>, and make them extract into a subdirectory
named C<xyz>, do this:

  $zip->addTreeMatching( '/abc', 'xyz', '\.pl$', sub { -w } )

Returns AZ_OK on success.

Note that this will not follow symbolic links to directories.

=back

=cut

sub addTreeMatching
{
	my $self = shift;
	my $root = shift
		or return _error("root arg missing in call to addTreeMatching()");
	my $dest = shift || '';
	my $pattern = shift
		or return _error("pattern missing in call to addTreeMatching()");
	my $pred = shift || sub { -r };
	my $matcher = sub { m{$pattern} && &$pred };
	return $self->addTree( $root, $dest, $matcher );
}

=over 4

=item $zip->extractTree( $root, $dest )

Extracts all the members below a given root. Will
translate that root to a given dest pathname.

For instance,

   $zip->extractTree( '/a/', 'd/e/' );

when applied to a zip containing the files:
 /a/x /a/b/c /d/e

will extract:
 /a/x to d/e/x
 /a/b/c to d/e/b/c

and ignore /d/e

=back 

=cut

sub extractTree
{
	my $self = shift();
	my $root = shift();
	return _error("root arg missing in call to extractTree()")
		unless defined($root);
	my $dest = shift || '.';
	$root =~ s{\\}{/}g;	# normalize backslashes in case user is misguided
	$root =~ s{([^/])$}{$1/};	# append slash if necessary
	my @members = $self->membersMatching( "^$root" );
	foreach my $member ( @members )
	{
		my $fileName = $member->fileName(); 
		$fileName =~ s{$root}{$dest};
		my $status = $member->extractToFileNamed( $fileName );
		return $status if $status != AZ_OK;
	}
	return AZ_OK;
}

1;
__END__

=head1 AUTHOR

Ned Konz, perl@bike-nomad.com

=head1 COPYRIGHT

Copyright (c) 2000 Ned Konz. All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

L<Compress::Zlib>
L<Archive::Zip>

=cut

# vim: ts=4 sw=4 columns=80
