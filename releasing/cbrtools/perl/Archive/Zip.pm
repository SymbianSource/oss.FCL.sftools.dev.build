#! perl -w
# $Revision: 1.39 $

# Copyright (c) 2000 Ned Konz. All rights reserved.  This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

=head1 NAME

Archive::Zip - Provide an interface to ZIP archive files.

=head1 SYNOPSIS

 use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

 my $zip = Archive::Zip->new();
 my $member = $zip->addDirectory( 'dirname/' );
 $member = $zip->addString( 'This is a test', 'stringMember.txt' );
 $member->desiredCompressionMethod( COMPRESSION_DEFLATED );
 $member = $zip->addFile( 'xyz.pl', 'AnotherName.pl' );

 die 'write error' if $zip->writeToFileNamed( 'someZip.zip' ) != AZ_OK;

 $zip = Archive::Zip->new();
 die 'read error' if $zip->read( 'someZip.zip' ) != AZ_OK;

 $member = $zip->memberNamed( 'stringMember.txt' );
 $member->desiredCompressionMethod( COMPRESSION_STORED );

 die 'write error' if $zip->writeToFileNamed( 'someOtherZip.zip' ) != AZ_OK;

=head1 DESCRIPTION

The Archive::Zip module allows a Perl program to create,
manipulate, read, and write Zip archive files.

Zip archives can be created, or you can read from existing zip files.
Once created, they can be written to files, streams, or strings.

Members can be added, removed, extracted, replaced, rearranged,
and enumerated.
They can also be renamed or have their dates, comments,
or other attributes queried or modified.
Their data can be compressed or uncompressed as needed.
Members can be created from members in existing Zip files,
or from existing directories, files, or strings.

This module uses the L<Compress::Zlib|Compress::Zlib> library
to read and write the compressed streams inside the files.

=head1 EXPORTS

=over 4

=item :CONSTANTS

Exports the following constants:

FA_MSDOS FA_UNIX GPBF_ENCRYPTED_MASK
GPBF_DEFLATING_COMPRESSION_MASK GPBF_HAS_DATA_DESCRIPTOR_MASK
COMPRESSION_STORED COMPRESSION_DEFLATED
IFA_TEXT_FILE_MASK IFA_TEXT_FILE IFA_BINARY_FILE
COMPRESSION_LEVEL_NONE
COMPRESSION_LEVEL_DEFAULT
COMPRESSION_LEVEL_FASTEST
COMPRESSION_LEVEL_BEST_COMPRESSION

=item :MISC_CONSTANTS

Exports the following constants (only necessary for extending the module):

FA_AMIGA FA_VAX_VMS FA_VM_CMS FA_ATARI_ST
FA_OS2_HPFS FA_MACINTOSH FA_Z_SYSTEM FA_CPM FA_WINDOWS_NTFS
GPBF_IMPLODING_8K_SLIDING_DICTIONARY_MASK
GPBF_IMPLODING_3_SHANNON_FANO_TREES_MASK
GPBF_IS_COMPRESSED_PATCHED_DATA_MASK COMPRESSION_SHRUNK
DEFLATING_COMPRESSION_NORMAL DEFLATING_COMPRESSION_MAXIMUM
DEFLATING_COMPRESSION_FAST DEFLATING_COMPRESSION_SUPER_FAST
COMPRESSION_REDUCED_1 COMPRESSION_REDUCED_2 COMPRESSION_REDUCED_3
COMPRESSION_REDUCED_4 COMPRESSION_IMPLODED COMPRESSION_TOKENIZED
COMPRESSION_DEFLATED_ENHANCED
COMPRESSION_PKWARE_DATA_COMPRESSION_LIBRARY_IMPLODED

=item :ERROR_CODES

Explained below. Returned from most methods.

AZ_OK AZ_STREAM_END AZ_ERROR AZ_FORMAT_ERROR AZ_IO_ERROR

=back

=head1 OBJECT MODEL

=head2 Inheritance

 Exporter
    Archive::Zip                            Common base class, has defs.
        Archive::Zip::Archive               A Zip archive.
        Archive::Zip::Member                Abstract superclass for all members.
            Archive::Zip::StringMember      Member made from a string
            Archive::Zip::FileMember        Member made from an external file
                Archive::Zip::ZipFileMember Member that lives in a zip file
                Archive::Zip::NewFileMember Member whose data is in a file
            Archive::Zip::DirectoryMember   Member that is a directory

=cut

# ----------------------------------------------------------------------
# class Archive::Zip
# Note that the package Archive::Zip exists only for exporting and
# sharing constants. Everything else is in another package
# in this file.
# Creation of a new Archive::Zip object actually creates a new object
# of class Archive::Zip::Archive.
# ----------------------------------------------------------------------

package Archive::Zip;
require 5.003_96;
use strict;

use Carp ();
use IO::File ();
use IO::Seekable ();
use Compress::Zlib ();
use POSIX qw(_exit);

use vars qw( @ISA @EXPORT_OK %EXPORT_TAGS $VERSION $ChunkSize $ErrorHandler );

if ($Compress::Zlib::VERSION < 1.06)
{
    if ($] < 5.006001)
    {
       print STDERR "Your current perl libraries are too old; please upgrade to Perl 5.6.1\n";
    }
    else
    {
       print STDERR "There is a problem with your perl run time environment.\n An old version of Zlib is in use,\n please check your perl installation (5.6.1 or later) and your perl libraries\n"; 
    }
    STDERR->flush;
    POSIX:_exit(1);
}

# This is the size we'll try to read, write, and (de)compress.
# You could set it to something different if you had lots of memory
# and needed more speed.
$ChunkSize = 32768;

$ErrorHandler = \&Carp::carp;

# BEGIN block is necessary here so that other modules can use the constants.
BEGIN
{
	require Exporter;

	$VERSION = "0.11";
	@ISA = qw( Exporter );

	my @ConstantNames = qw( FA_MSDOS FA_UNIX GPBF_ENCRYPTED_MASK
	GPBF_DEFLATING_COMPRESSION_MASK GPBF_HAS_DATA_DESCRIPTOR_MASK
	COMPRESSION_STORED COMPRESSION_DEFLATED COMPRESSION_LEVEL_NONE
	COMPRESSION_LEVEL_DEFAULT COMPRESSION_LEVEL_FASTEST
	COMPRESSION_LEVEL_BEST_COMPRESSION IFA_TEXT_FILE_MASK IFA_TEXT_FILE
	IFA_BINARY_FILE );

	my @MiscConstantNames = qw( FA_AMIGA FA_VAX_VMS FA_VM_CMS FA_ATARI_ST
	FA_OS2_HPFS FA_MACINTOSH FA_Z_SYSTEM FA_CPM FA_WINDOWS_NTFS
	GPBF_IMPLODING_8K_SLIDING_DICTIONARY_MASK
	GPBF_IMPLODING_3_SHANNON_FANO_TREES_MASK
	GPBF_IS_COMPRESSED_PATCHED_DATA_MASK COMPRESSION_SHRUNK
	DEFLATING_COMPRESSION_NORMAL DEFLATING_COMPRESSION_MAXIMUM
	DEFLATING_COMPRESSION_FAST DEFLATING_COMPRESSION_SUPER_FAST
	COMPRESSION_REDUCED_1 COMPRESSION_REDUCED_2 COMPRESSION_REDUCED_3
	COMPRESSION_REDUCED_4 COMPRESSION_IMPLODED COMPRESSION_TOKENIZED
	COMPRESSION_DEFLATED_ENHANCED
	COMPRESSION_PKWARE_DATA_COMPRESSION_LIBRARY_IMPLODED );

	my @ErrorCodeNames = qw( AZ_OK AZ_STREAM_END AZ_ERROR AZ_FORMAT_ERROR
	AZ_IO_ERROR );

	my @PKZipConstantNames = qw( SIGNATURE_FORMAT SIGNATURE_LENGTH
	LOCAL_FILE_HEADER_SIGNATURE LOCAL_FILE_HEADER_FORMAT
	LOCAL_FILE_HEADER_LENGTH DATA_DESCRIPTOR_FORMAT DATA_DESCRIPTOR_LENGTH
	CENTRAL_DIRECTORY_FILE_HEADER_SIGNATURE
	CENTRAL_DIRECTORY_FILE_HEADER_FORMAT CENTRAL_DIRECTORY_FILE_HEADER_LENGTH
	END_OF_CENTRAL_DIRECTORY_SIGNATURE
	END_OF_CENTRAL_DIRECTORY_SIGNATURE_STRING END_OF_CENTRAL_DIRECTORY_FORMAT
	END_OF_CENTRAL_DIRECTORY_LENGTH );

	my @UtilityMethodNames = qw( _error _ioError _formatError
		_subclassResponsibility _binmode _isSeekable _newFileHandle);

	@EXPORT_OK = ( 'computeCRC32' );
	%EXPORT_TAGS = ( 'CONSTANTS' => \@ConstantNames,
			'MISC_CONSTANTS' => \@MiscConstantNames,
			'ERROR_CODES' => \@ErrorCodeNames,
			# The following two sets are for internal use only
			'PKZIP_CONSTANTS' => \@PKZipConstantNames,
			'UTILITY_METHODS' => \@UtilityMethodNames );

	# Add all the constant names and error code names to @EXPORT_OK
	Exporter::export_ok_tags( 'CONSTANTS', 'ERROR_CODES',
		'PKZIP_CONSTANTS', 'UTILITY_METHODS', 'MISC_CONSTANTS' );
}

# ------------------------- begin exportable error codes -------------------

=head1 ERROR CODES

Many of the methods in Archive::Zip return error codes.
These are implemented as inline subroutines, using the C<use constant> pragma.
They can be imported into your namespace using the C<:CONSTANT>
tag:

    use Archive::Zip qw( :CONSTANTS );
    ...
    die "whoops!" if $zip->read( 'myfile.zip' ) != AZ_OK;

=over 4

=item AZ_OK (0)

Everything is fine.

=item AZ_STREAM_END (1)

The read stream (or central directory) ended normally.

=item AZ_ERROR (2)

There was some generic kind of error.

=item AZ_FORMAT_ERROR (3)

There is a format error in a ZIP file being read.

=item AZ_IO_ERROR (4)

There was an IO error.

=back

=cut

use constant AZ_OK			=> 0;
use constant AZ_STREAM_END	=> 1;
use constant AZ_ERROR		=> 2;
use constant AZ_FORMAT_ERROR => 3;
use constant AZ_IO_ERROR	=> 4;

# ------------------------- end exportable error codes ---------------------
# ------------------------- begin exportable constants ---------------------

# File types
# Values of Archive::Zip::Member->fileAttributeFormat()

use constant FA_MSDOS		=> 0;
use constant FA_UNIX		=> 3;

# general-purpose bit flag masks
# Found in Archive::Zip::Member->bitFlag()

use constant GPBF_ENCRYPTED_MASK						=> 1 << 0;
use constant GPBF_DEFLATING_COMPRESSION_MASK			=> 3 << 1;
use constant GPBF_HAS_DATA_DESCRIPTOR_MASK				=> 1 << 3;

# deflating compression types, if compressionMethod == COMPRESSION_DEFLATED
# ( Archive::Zip::Member->bitFlag() & GPBF_DEFLATING_COMPRESSION_MASK )

use constant DEFLATING_COMPRESSION_NORMAL		=> 0 << 1;
use constant DEFLATING_COMPRESSION_MAXIMUM		=> 1 << 1;
use constant DEFLATING_COMPRESSION_FAST			=> 2 << 1;
use constant DEFLATING_COMPRESSION_SUPER_FAST	=> 3 << 1;

# compression method

=head1 COMPRESSION

Archive::Zip allows each member of a ZIP file to be compressed (using
the Deflate algorithm) or uncompressed. Other compression algorithms
that some versions of ZIP have been able to produce are not supported.

Each member has two compression methods: the one it's stored as (this
is always COMPRESSION_STORED for string and external file members),
and the one you desire for the member in the zip file.
These can be different, of course, so you can make a zip member that
is not compressed out of one that is, and vice versa.
You can inquire about the current compression and set
the desired compression method:

    my $member = $zip->memberNamed( 'xyz.txt' );
    $member->compressionMethod();    # return current compression
    # set to read uncompressed
    $member->desiredCompressionMethod( COMPRESSION_STORED );
    # set to read compressed
    $member->desiredCompressionMethod( COMPRESSION_DEFLATED );

There are two different compression methods:

=over 4

=item COMPRESSION_STORED

file is stored (no compression)

=item COMPRESSION_DEFLATED

file is Deflated

=back

=head2 Compression Levels

If a member's desiredCompressionMethod is COMPRESSION_DEFLATED,
you can choose different compression levels. This choice may
affect the speed of compression and decompression, as well as
the size of the compressed member data.

    $member->desiredCompressionLevel( 9 );

The levels given can be:

=over 4

=item 0 or COMPRESSION_LEVEL_NONE

This is the same as saying

    $member->desiredCompressionMethod( COMPRESSION_STORED );

=item 1 .. 9

1 gives the best speed and worst compression, and 9 gives the best
compression and worst speed.

=item COMPRESSION_LEVEL_FASTEST

This is a synonym for level 1.

=item COMPRESSION_LEVEL_BEST_COMPRESSION

This is a synonym for level 9.

=item COMPRESSION_LEVEL_DEFAULT

This gives a good compromise between speed and compression, and is
currently equivalent to 6 (this is in the zlib code).

This is the level that will be used if not specified.

=back

=cut

# these two are the only ones supported in this module
use constant COMPRESSION_STORED => 0;	# file is stored (no compression)
use constant COMPRESSION_DEFLATED => 8;	# file is Deflated

use constant COMPRESSION_LEVEL_NONE => 0;
use constant COMPRESSION_LEVEL_DEFAULT => -1;
use constant COMPRESSION_LEVEL_FASTEST => 1;
use constant COMPRESSION_LEVEL_BEST_COMPRESSION => 9;

# internal file attribute bits
# Found in Archive::Zip::Member::internalFileAttributes()

use constant IFA_TEXT_FILE_MASK	=> 1;
use constant IFA_TEXT_FILE		=> 1;	# file is apparently text
use constant IFA_BINARY_FILE	=> 0;

# PKZIP file format miscellaneous constants (for internal use only)
use constant SIGNATURE_FORMAT => "V";
use constant SIGNATURE_LENGTH => 4;

use constant LOCAL_FILE_HEADER_SIGNATURE	=> 0x04034b50;
use constant LOCAL_FILE_HEADER_FORMAT		=> "v3 V4 v2";
use constant LOCAL_FILE_HEADER_LENGTH		=> 26;

use constant DATA_DESCRIPTOR_FORMAT	=> "V3";
use constant DATA_DESCRIPTOR_LENGTH	=> 12;

use constant CENTRAL_DIRECTORY_FILE_HEADER_SIGNATURE => 0x02014b50;
use constant CENTRAL_DIRECTORY_FILE_HEADER_FORMAT => "C2 v3 V4 v5 V2";
use constant CENTRAL_DIRECTORY_FILE_HEADER_LENGTH => 42;

use constant END_OF_CENTRAL_DIRECTORY_SIGNATURE => 0x06054b50;
use constant END_OF_CENTRAL_DIRECTORY_SIGNATURE_STRING => pack( "V",
	END_OF_CENTRAL_DIRECTORY_SIGNATURE );
use constant END_OF_CENTRAL_DIRECTORY_FORMAT => "v4 V2 v";
use constant END_OF_CENTRAL_DIRECTORY_LENGTH => 18;

use constant FA_AMIGA		=> 1;
use constant FA_VAX_VMS		=> 2;
use constant FA_VM_CMS		=> 4;
use constant FA_ATARI_ST	=> 5;
use constant FA_OS2_HPFS	=> 6;
use constant FA_MACINTOSH	=> 7;
use constant FA_Z_SYSTEM	=> 8;
use constant FA_CPM			=> 9;
use constant FA_WINDOWS_NTFS => 10;

use constant GPBF_IMPLODING_8K_SLIDING_DICTIONARY_MASK	=> 1 << 1;
use constant GPBF_IMPLODING_3_SHANNON_FANO_TREES_MASK	=> 1 << 2;
use constant GPBF_IS_COMPRESSED_PATCHED_DATA_MASK		=> 1 << 5;

# the rest of these are not supported in this module
use constant COMPRESSION_SHRUNK => 1;	# file is Shrunk
use constant COMPRESSION_REDUCED_1 => 2;# file is Reduced CF=1
use constant COMPRESSION_REDUCED_2 => 3;# file is Reduced CF=2
use constant COMPRESSION_REDUCED_3 => 4;# file is Reduced CF=3
use constant COMPRESSION_REDUCED_4 => 5;# file is Reduced CF=4
use constant COMPRESSION_IMPLODED => 6;	# file is Imploded
use constant COMPRESSION_TOKENIZED => 7;# reserved for Tokenizing compr.
use constant COMPRESSION_DEFLATED_ENHANCED => 9; # reserved for enh. Deflating
use constant COMPRESSION_PKWARE_DATA_COMPRESSION_LIBRARY_IMPLODED => 10;

# ------------------------- end of exportable constants ---------------------

=head1  Archive::Zip methods

The Archive::Zip class (and its invisible subclass Archive::Zip::Archive)
implement generic zip file functionality.

Creating a new Archive::Zip object actually makes an Archive::Zip::Archive
object, but you don't have to worry about this unless you're subclassing.

=cut

=head2 Constructor

=over 4

=cut

use constant ZIPARCHIVECLASS 	=> 'Archive::Zip::Archive';
use constant ZIPMEMBERCLASS		=> 'Archive::Zip::Member';

#--------------------------------

=item new( [$fileName] )

Make a new, empty zip archive.

    my $zip = Archive::Zip->new();

If an additional argument is passed, new() will call read() to read the
contents of an archive:

    my $zip = Archive::Zip->new( 'xyz.zip' );

If a filename argument is passed and the read fails for any reason, new
will return undef. For this reason, it may be better to call read
separately.

=cut

sub new	# Archive::Zip
{
	my $class = shift;
	return $class->ZIPARCHIVECLASS->new( @_ );
}

=back

=head2  Utility Methods

These Archive::Zip methods may be called as functions or as object
methods. Do not call them as class methods:

    $zip = Archive::Zip->new();
    $crc = Archive::Zip::computeCRC32( 'ghijkl' );    # OK
    $crc = $zip->computeCRC32( 'ghijkl' );            # also OK

    $crc = Archive::Zip->computeCRC32( 'ghijkl' );    # NOT OK

=over 4

=cut

#--------------------------------

=item Archive::Zip::computeCRC32( $string [, $crc] )

This is a utility function that uses the Compress::Zlib CRC
routine to compute a CRC-32.

You can get the CRC of a string:

    $crc = Archive::Zip::computeCRC32( $string );

Or you can compute the running CRC:

    $crc = 0;
    $crc = Archive::Zip::computeCRC32( 'abcdef', $crc );
    $crc = Archive::Zip::computeCRC32( 'ghijkl', $crc );

=cut

sub computeCRC32	# Archive::Zip
{
	my $data = shift;
	$data = shift if ref( $data );	# allow calling as an obj method
	my $crc = shift;
	return Compress::Zlib::crc32( $data, $crc );
}

#--------------------------------

=item Archive::Zip::setChunkSize( $number )

Change chunk size used for reading and writing.
Currently, this defaults to 32K.
This is not exportable, so you must call it like:

    Archive::Zip::setChunkSize( 4096 );

or as a method on a zip (though this is a global setting).
Returns old chunk size.

=cut

sub setChunkSize	# Archive::Zip
{
	my $chunkSize = shift;
	$chunkSize = shift if ref( $chunkSize );	# object method on zip?
	my $oldChunkSize = $Archive::Zip::ChunkSize;
	$Archive::Zip::ChunkSize = $chunkSize;
	return $oldChunkSize;
}

#--------------------------------

=item Archive::Zip::setErrorHandler( \&subroutine )

Change the subroutine called with error strings.
This defaults to \&Carp::carp, but you may want to change
it to get the error strings.

This is not exportable, so you must call it like:

    Archive::Zip::setErrorHandler( \&myErrorHandler );

If no error handler is passed, resets handler to default.

Returns old error handler.

Note that if you call Carp::carp or a similar routine
or if you're chaining to the default error handler
from your error handler, you may want to increment the number
of caller levels that are skipped (do not just set it to a number):

    $Carp::CarpLevel++;

=cut

sub setErrorHandler (&)	# Archive::Zip
{
	my $errorHandler = shift;
	$errorHandler = \&Carp::carp if ! defined( $errorHandler );
	my $oldErrorHandler = $Archive::Zip::ErrorHandler;
	$Archive::Zip::ErrorHandler = $errorHandler;
	return $oldErrorHandler;
}

sub _printError	# Archive::Zip
{
	my $string = join( ' ', @_, "\n" );
	my $oldCarpLevel = $Carp::CarpLevel;
	$Carp::CarpLevel += 2;
	&{ $ErrorHandler }( $string );
	$Carp::CarpLevel = $oldCarpLevel;
}

# This is called on format errors.
sub _formatError	# Archive::Zip
{
	shift if ref( $_[0] );
	_printError( 'format error:', @_ );
	return AZ_FORMAT_ERROR;
}

# This is called on IO errors.
sub _ioError	# Archive::Zip
{
	shift if ref( $_[0] );
	_printError( 'IO error:', @_, ':', $! );
	return AZ_IO_ERROR;
}

# This is called on generic errors.
sub _error	# Archive::Zip
{
	shift if ref( $_[0] );
	_printError( 'error:', @_ );
	return AZ_ERROR;
}

# Called when a subclass should have implemented
# something but didn't
sub _subclassResponsibility 	# Archive::Zip
{
	Carp::croak( "subclass Responsibility\n" );
}

# Try to set the given file handle or object into binary mode.
sub _binmode	# Archive::Zip
{
	my $fh = shift;
	return $fh->can( 'binmode' )
		?	$fh->binmode()
		:	binmode( $fh );
}

# Attempt to guess whether file handle is seekable.
sub _isSeekable	# Archive::Zip
{
	my $fh = shift;
	my ($p0, $p1);
	my $seekable = 
		( $p0 = $fh->tell() ) >= 0
		&& $fh->seek( 1, IO::Seekable::SEEK_CUR )
		&& ( $p1 = $fh->tell() ) >= 0
		&& $p1 == $p0 + 1
		&& $fh->seek( -1, IO::Seekable::SEEK_CUR )
		&& $fh->tell() == $p0;
	return $seekable;
}

# Return an opened IO::Handle
# my ( $status, fh ) = _newFileHandle( 'fileName', 'w' );
# Can take a filename, file handle, or ref to GLOB
# Or, if given something that is a ref but not an IO::Handle,
# passes back the same thing.
sub _newFileHandle	# Archive::Zip
{
	my $fd = shift;
	my $status = 1;
	my $handle = IO::File->new();

	if ( ref( $fd ) )
	{
		if ( $fd->isa( 'IO::Handle' ) or $fd->isa( 'GLOB' ) )
		{
			$status = $handle->fdopen( $fd, @_ );
		}
		else
		{
			$handle = $fd;
		}
	}
	else
	{
		$status = $handle->open( $fd, @_ );
	}

	return ( $status, $handle );
}

=back

=cut

# ----------------------------------------------------------------------
# class Archive::Zip::Archive (concrete)
# Generic ZIP archive.
# ----------------------------------------------------------------------
package Archive::Zip::Archive;
use File::Path;
use File::Basename;

use vars qw( @ISA );
@ISA = qw( Archive::Zip );

BEGIN { use Archive::Zip qw( :CONSTANTS :ERROR_CODES :PKZIP_CONSTANTS
	:UTILITY_METHODS ) }

#--------------------------------
# Note that this returns undef on read errors, else new zip object.

sub new	# Archive::Zip::Archive
{
	my $class = shift;
	my $self = bless( {
		'diskNumber' => 0,
		'diskNumberWithStartOfCentralDirectory' => 0,
		'numberOfCentralDirectoriesOnThisDisk' => 0, # shld be # of members
		'numberOfCentralDirectories' => 0,	# shld be # of members
		'centralDirectorySize' => 0,	# must re-compute on write
		'centralDirectoryOffsetWRTStartingDiskNumber' => 0,	# must re-compute
		'zipfileComment' => ''
		}, $class );
	$self->{'members'} = [];
	if ( @_ )
	{
		my $status = $self->read( @_ );
		return $status == AZ_OK ? $self : undef;
	}
	return $self;
}

=head2 Accessors

=over 4

=cut

#--------------------------------

=item members()

Return a copy of my members array

    my @members = $zip->members();

=cut

sub members	# Archive::Zip::Archive
{ @{ shift->{'members'} } }

#--------------------------------

=item numberOfMembers()

Return the number of members I have

=cut

sub numberOfMembers	# Archive::Zip::Archive
{ scalar( shift->members() ) }

#--------------------------------

=item memberNames()

Return a list of the (internal) file names of my members

=cut

sub memberNames	# Archive::Zip::Archive
{
	my $self = shift;
	return map { $_->fileName() } $self->members();
}

#--------------------------------

=item memberNamed( $string )

Return ref to member whose filename equals given filename or undef

=cut

sub memberNamed	# Archive::Zip::Archive
{
	my ( $self, $fileName ) = @_;
	my ( $retval ) = grep { $_->fileName() eq $fileName } $self->members();
	return $retval;
}

#--------------------------------

=item membersMatching( $regex )

Return array of members whose filenames match given regular
expression in list context.
Returns number of matching members in scalar context.

    my @textFileMembers = $zip->membersMatching( '.*\.txt' );
    # or
    my $numberOfTextFiles = $zip->membersMatching( '.*\.txt' );

=cut

sub membersMatching	# Archive::Zip::Archive
{
	my ( $self, $pattern ) = @_;
	return grep { $_->fileName() =~ /$pattern/ } $self->members();
}

#--------------------------------

=item diskNumber()

Return the disk that I start on.
Not used for writing zips, but might be interesting if you read a zip in.
This had better be 0, as Archive::Zip does not handle multi-volume archives.

=cut

sub diskNumber	# Archive::Zip::Archive
{ shift->{'diskNumber'} }

#--------------------------------

=item diskNumberWithStartOfCentralDirectory()

Return the disk number that holds the beginning of the central directory.
Not used for writing zips, but might be interesting if you read a zip in.
This had better be 0, as Archive::Zip does not handle multi-volume archives.

=cut

sub diskNumberWithStartOfCentralDirectory	# Archive::Zip::Archive
{ shift->{'diskNumberWithStartOfCentralDirectory'} }

#--------------------------------

=item numberOfCentralDirectoriesOnThisDisk()

Return the number of CD structures on this disk.
Not used for writing zips, but might be interesting if you read a zip in.

=cut

sub numberOfCentralDirectoriesOnThisDisk	# Archive::Zip::Archive
{ shift->{'numberOfCentralDirectoriesOnThisDisk'} }

#--------------------------------

=item numberOfCentralDirectories()

Return the number of CD structures in the whole zip.
Not used for writing zips, but might be interesting if you read a zip in.

=cut

sub numberOfCentralDirectories	# Archive::Zip::Archive
{ shift->{'numberOfCentralDirectories'} }

#--------------------------------

=item centralDirectorySize()

Returns central directory size, as read from an external zip file.
Not used for writing zips, but might be interesting if you read a zip in.

=cut

sub centralDirectorySize	# Archive::Zip::Archive
{ shift->{'centralDirectorySize'} }

#--------------------------------

=item centralDirectoryOffsetWRTStartingDiskNumber()

Returns the offset into the zip file where the CD begins.
Not used for writing zips, but might be interesting if you read a zip in.

=cut

sub centralDirectoryOffsetWRTStartingDiskNumber	# Archive::Zip::Archive
{ shift->{'centralDirectoryOffsetWRTStartingDiskNumber'} }

#--------------------------------

=item zipfileComment( [$string] )

Get or set the zipfile comment.
Returns the old comment.

    print $zip->zipfileComment();
    $zip->zipfileComment( 'New Comment' );

=cut

sub zipfileComment	# Archive::Zip::Archive
{
	my $self = shift;
	my $comment = $self->{'zipfileComment'};
	if ( @_ )
	{
		$self->{'zipfileComment'} = shift;
	}
	return $comment;
}

=back

=head2 Member Operations

Various operations on a zip file modify members.
When a member is passed as an argument, you can either use a reference
to the member itself, or the name of a member. Of course, using the
name requires that names be unique within a zip (this is not enforced).

=over 4

=cut

#--------------------------------

=item removeMember( $memberOrName )

Remove and return the given member, or match its name and remove it.
Returns undef if member name doesn't exist in this Zip.
No-op if member does not belong to this zip.

=cut

sub removeMember	# Archive::Zip::Archive
{
	my ( $self, $member ) = @_;
	$member = $self->memberNamed( $member ) if ! ref( $member );
	return undef if ! $member;
	my @newMembers = grep { $_ != $member } $self->members();
	$self->{'members'} = \@newMembers;
	return $member;
}

#--------------------------------

=item replaceMember( $memberOrName, $newMember )

Remove and return the given member, or match its name and remove it.
Replace with new member.
Returns undef if member name doesn't exist in this Zip.

    my $member1 = $zip->removeMember( 'xyz' );
    my $member2 = $zip->replaceMember( 'abc', $member1 );
    # now, $member2 (named 'abc') is not in $zip,
    # and $member1 (named 'xyz') is, having taken $member2's place.

=cut

sub replaceMember	# Archive::Zip::Archive
{
	my ( $self, $oldMember, $newMember ) = @_;
	$oldMember = $self->memberNamed( $oldMember ) if ! ref( $oldMember );
	return undef if ! $oldMember;
	my @newMembers
		= map { ( $_ == $oldMember ) ? $newMember : $_ } $self->members();
	$self->{'members'} = \@newMembers;
	return $oldMember;
}

#--------------------------------

=item extractMember( $memberOrName [, $extractedName ] )

Extract the given member, or match its name and extract it.
Returns undef if member doesn't exist in this Zip.
If optional second arg is given, use it as the name of the
extracted member. Otherwise, the internal filename of the member is used
as the name of the extracted file or directory.

All necessary directories will be created.

Returns C<AZ_OK> on success.

=cut

sub extractMember	# Archive::Zip::Archive
{
	my $self = shift;
	my $member = shift;
	$member = $self->memberNamed( $member ) if ! ref( $member );
	return _error( 'member not found' ) if !$member;
	my $name = shift;
	$name = $member->fileName() if not $name;
	my $dirName = dirname( $name );
	mkpath( $dirName ) if ( ! -d $dirName );
	return _ioError( "can't create dir $dirName" ) if ( ! -d $dirName );
	return $member->extractToFileNamed( $name, @_ );
}

#--------------------------------

=item extractMemberWithoutPaths( $memberOrName [, $extractedName ] )

Extract the given member, or match its name and extract it.
Does not use path information (extracts into the current directory).
Returns undef if member doesn't exist in this Zip.
If optional second arg is given, use it as the name of the
extracted member (its paths will be deleted too).
Otherwise, the internal filename of the member (minus paths) is used
as the name of the extracted file or directory.

Returns C<AZ_OK> on success.

=cut

sub extractMemberWithoutPaths	# Archive::Zip::Archive
{
	my $self = shift;
	my $member = shift;
	$member = $self->memberNamed( $member ) if ! ref( $member );
	return _error( 'member not found' ) if !$member;
	my $name = shift;
	$name = $member->fileName() if not $name;
	$name = basename( $name );
	return $member->extractToFileNamed( $name, @_ );
}

#--------------------------------

=item addMember( $member )

Append a member (possibly from another zip file) to the zip file.
Returns the new member.
Generally, you will use addFile(), addDirectory(), addString(), or read()
to add members.

    # Move member named 'abc' to end of zip:
    my $member = $zip->removeMember( 'abc' );
    $zip->addMember( $member );

=cut

sub addMember	# Archive::Zip::Archive
{
	my ( $self, $newMember ) = @_;
	push( @{ $self->{'members'} }, $newMember ) if $newMember;
	return $newMember;
}

#--------------------------------

=item addFile( $fileName [, $newName ] )

Append a member whose data comes from an external file,
returning the member or undef.
The member will have its file name set to the name of the external
file, and its desiredCompressionMethod set to COMPRESSION_DEFLATED.
The file attributes and last modification time will be set from the file.

If the name given does not represent a readable plain file or symbolic link,
undef will be returned.

The text mode bit will be set if the contents appears to be text (as returned
by the C<-T> perl operator).

The optional second argument sets the internal file name to
something different than the given $fileName.

=cut

sub addFile	# Archive::Zip::Archive
{
	my $self = shift;
	my $fileName = shift;
	my $newName = shift;
	my $newMember = $self->ZIPMEMBERCLASS->newFromFile( $fileName );
	if (defined($newMember))
	{
		$self->addMember( $newMember );
		$newMember->fileName( $newName ) if defined( $newName );
	}
	return $newMember;
}

#--------------------------------

=item addString( $stringOrStringRef [, $name] )

Append a member created from the given string or string reference.
The name is given by the optional second argument.
Returns the new member.

The last modification time will be set to now,
and the file attributes will be set to permissive defaults.

    my $member = $zip->addString( 'This is a test', 'test.txt' );

=cut

sub addString	# Archive::Zip::Archive
{
	my $self = shift;
	my $newMember = $self->ZIPMEMBERCLASS->newFromString( @_ );
	return $self->addMember( $newMember );
}

#--------------------------------

=item addDirectory( $directoryName [, $fileName ] )

Append a member created from the given directory name.
The directory name does not have to name an existing directory.
If the named directory exists, the file modification time and permissions
are set from the existing directory, otherwise they are set to now and
permissive default permissions.
The optional second argument sets the name of the archive member
(which defaults to $directoryName)

Returns the new member.

=cut

sub addDirectory	# Archive::Zip::Archive
{
	my ( $self, $name, $newName ) = @_;
	my $newMember = $self->ZIPMEMBERCLASS->newDirectoryNamed( $name );
	$self->addMember( $newMember );
	$newMember->fileName( $newName ) if defined( $newName );
	return $newMember;
}

#--------------------------------

=item contents( $memberOrMemberName [, $newContents ] )

Returns the uncompressed data for a particular member, or undef.

    print "xyz.txt contains " . $zip->contents( 'xyz.txt' );

Also can change the contents of a member:

    $zip->contents( 'xyz.txt', 'This is the new contents' );

=cut

sub contents	# Archive::Zip::Archive
{
	my ( $self, $member, $newContents ) = @_;
	$member = $self->memberNamed( $member ) if ! ref( $member );
	return undef if ! $member;
	return $member->contents( $newContents );
}

#--------------------------------

=item writeToFileNamed( $fileName )

Write a zip archive to named file.
Returns C<AZ_OK> on success.

Note that if you use the same name as an existing
zip file that you read in, you will clobber ZipFileMembers.
So instead, write to a different file name, then delete
the original.

    my $status = $zip->writeToFileNamed( 'xx.zip' );
    die "error somewhere" if $status != AZ_OK;

=cut

sub writeToFileNamed	# Archive::Zip::Archive
{
	my $self = shift;
	my $fileName = shift;
	foreach my $member ( $self->members() )
	{
		if ( $member->_usesFileNamed( $fileName ) )
		{
			return _error("$fileName is needed by member " 
					. $member->fileName() 
					. "; try renaming output file");
		}
	}
	my ( $status, $fh ) = _newFileHandle( $fileName, 'w' );
	return _ioError( "Can't open $fileName for write" ) if !$status;
	my $retval = $self->writeToFileHandle( $fh, 1 );
	$fh->close();
	return $retval;
}

#--------------------------------

=item writeToFileHandle( $fileHandle [, $seekable] )

Write a zip archive to a file handle.
Return AZ_OK on success.

The optional second arg tells whether or not to try to seek backwards
to re-write headers.
If not provided, it is set by testing seekability. This could fail
on some operating systems, though.

    my $fh = IO::File->new( 'someFile.zip', 'w' );
    $zip->writeToFileHandle( $fh );

If you pass a file handle that is not seekable (like if you're writing
to a pipe or a socket), pass a false as the second argument:

    my $fh = IO::File->new( '| cat > somefile.zip', 'w' );
    $zip->writeToFileHandle( $fh, 0 );   # fh is not seekable

=cut

sub writeToFileHandle	# Archive::Zip::Archive
{
	my $self = shift;
	my $fh = shift;
	my $fhIsSeekable = @_ ? shift : _isSeekable( $fh );
	_binmode( $fh );

	my $offset = 0;
	foreach my $member ( $self->members() )
	{
		$member->{'writeLocalHeaderRelativeOffset'} = $offset;
		my $retval = $member->_writeToFileHandle( $fh, $fhIsSeekable );
		$member->endRead();
		return $retval if $retval != AZ_OK;
		$offset += $member->_localHeaderSize() + $member->_writeOffset();
		$offset += $member->hasDataDescriptor() ? DATA_DESCRIPTOR_LENGTH : 0;
	}
	$self->{'writeCentralDirectoryOffset'} = $offset;
	return $self->_writeCentralDirectory( $fh );
}

# Returns next signature from given file handle, leaves
# file handle positioned afterwards.
# In list context, returns ($status, $signature)

sub _readSignature	# Archive::Zip::Archive
{
	my $self = shift;
	my $fh = shift;
	my $fileName = shift;
	my $signatureData;
	$fh->read( $signatureData, SIGNATURE_LENGTH )
		or return _ioError( "reading header signature" );
	my $signature = unpack( SIGNATURE_FORMAT, $signatureData );
	my $status = AZ_OK;
	if ( $signature != CENTRAL_DIRECTORY_FILE_HEADER_SIGNATURE
			and $signature != LOCAL_FILE_HEADER_SIGNATURE
			and $signature != END_OF_CENTRAL_DIRECTORY_SIGNATURE )
	{
		$status = _formatError(
			sprintf( "bad signature: 0x%08x at offset %d in file \"%s\"",
				$signature, $fh->tell() - SIGNATURE_LENGTH, $fileName ) );
	}

	return ( $status, $signature );
}

# Used only during writing
sub _writeCentralDirectoryOffset	# Archive::Zip::Archive
{ shift->{'writeCentralDirectoryOffset'} }

sub _writeEOCDOffset	# Archive::Zip::Archive
{ shift->{'writeEOCDOffset'} }

# Expects to have _writeEOCDOffset() set
sub _writeEndOfCentralDirectory	# Archive::Zip::Archive
{
	my ( $self, $fh ) = @_;

	$fh->write( END_OF_CENTRAL_DIRECTORY_SIGNATURE_STRING, SIGNATURE_LENGTH )
		or return _ioError( 'writing EOCD Signature' );

	my $header = pack( END_OF_CENTRAL_DIRECTORY_FORMAT,
		0,	# {'diskNumber'},
		0,	# {'diskNumberWithStartOfCentralDirectory'},
		$self->numberOfMembers(),	# {'numberOfCentralDirectoriesOnThisDisk'},
		$self->numberOfMembers(),	# {'numberOfCentralDirectories'},
		$self->_writeEOCDOffset() - $self->_writeCentralDirectoryOffset(),
		$self->_writeCentralDirectoryOffset(),
		length( $self->zipfileComment() )
	 );
	$fh->write( $header, END_OF_CENTRAL_DIRECTORY_LENGTH )
		or return _ioError( 'writing EOCD header' );
	if ( length( $self->zipfileComment() ))
	{
		$fh->write( $self->zipfileComment(), length( $self->zipfileComment() ))
			or return _ioError( 'writing zipfile comment' );
	}
	return AZ_OK;
}

sub _writeCentralDirectory	# Archive::Zip::Archive
{
	my ( $self, $fh ) = @_;

	my $offset = $self->_writeCentralDirectoryOffset();
	foreach my $member ( $self->members() )
	{
		my $status = $member->_writeCentralDirectoryFileHeader( $fh );
		return $status if $status != AZ_OK;
		$offset += $member->_centralDirectoryHeaderSize();
	}
	$self->{'writeEOCDOffset'} = $offset;
	return $self->_writeEndOfCentralDirectory( $fh );
}

#--------------------------------

=item read( $fileName )

Read zipfile headers from a zip file, appending new members.
Returns C<AZ_OK> or error code.

    my $zipFile = Archive::Zip->new();
    my $status = $zipFile->read( '/some/FileName.zip' );

=cut

sub read	# Archive::Zip::Archive
{
	my $self = shift;
	my $fileName = shift;
	return _error( 'No filename given' ) if ! $fileName;
	my ( $status, $fh ) = _newFileHandle( $fileName, 'r' );
	return _ioError( "opening $fileName for read" ) if !$status;
	_binmode( $fh );

	$status = $self->_findEndOfCentralDirectory( $fh );
	return $status if $status != AZ_OK;

	my $eocdPosition = $fh->tell();

	$status = $self->_readEndOfCentralDirectory( $fh );
	return $status if $status != AZ_OK;

	$fh->seek( $eocdPosition - $self->centralDirectorySize(),
		IO::Seekable::SEEK_SET )
			or return _ioError( "Can't seek $fileName" );

	for ( ;; )
	{
		my $newMember = 
			$self->ZIPMEMBERCLASS->_newFromZipFile( $fh, $fileName );
		my $signature;
		( $status, $signature ) = $self->_readSignature( $fh, $fileName );
		return $status if $status != AZ_OK;
		last if $signature == END_OF_CENTRAL_DIRECTORY_SIGNATURE;
		$status = $newMember->_readCentralDirectoryFileHeader();
		return $status if $status != AZ_OK;
		$status = $newMember->endRead();
		return $status if $status != AZ_OK;
		$newMember->_becomeDirectoryIfNecessary();
		push( @{ $self->{'members'} }, $newMember );
	}

	$fh->close();
	return AZ_OK;
}

# Read EOCD, starting from position before signature.
# Return AZ_OK on success.
sub _readEndOfCentralDirectory	# Archive::Zip::Archive
{
	my $self = shift;
	my $fh = shift;

	# Skip past signature
	$fh->seek( SIGNATURE_LENGTH, IO::Seekable::SEEK_CUR )
		or return _ioError( "Can't seek past EOCD signature" );

	my $header = '';
	$fh->read( $header, END_OF_CENTRAL_DIRECTORY_LENGTH )
		or return _ioError( "reading end of central directory" );

	my $zipfileCommentLength;
	(
		$self->{'diskNumber'},
		$self->{'diskNumberWithStartOfCentralDirectory'},
		$self->{'numberOfCentralDirectoriesOnThisDisk'},
		$self->{'numberOfCentralDirectories'},
		$self->{'centralDirectorySize'},
		$self->{'centralDirectoryOffsetWRTStartingDiskNumber'},
		$zipfileCommentLength
	 ) = unpack( END_OF_CENTRAL_DIRECTORY_FORMAT, $header );

	if ( $zipfileCommentLength )
	{
		my $zipfileComment = '';
		$fh->read( $zipfileComment, $zipfileCommentLength )
			or return _ioError( "reading zipfile comment" );
		$self->{'zipfileComment'} = $zipfileComment;
	}

	return AZ_OK;
}

# Seek in my file to the end, then read backwards until we find the
# signature of the central directory record. Leave the file positioned right
# before the signature. Returns AZ_OK if success.
sub _findEndOfCentralDirectory	# Archive::Zip::Archive
{
	my $self = shift;
	my $fh = shift;
	my $data = '';
	$fh->seek( 0, IO::Seekable::SEEK_END )
		or return _ioError( "seeking to end" );

	my $fileLength = $fh->tell();
	if ( $fileLength < END_OF_CENTRAL_DIRECTORY_LENGTH + 4 )
	{
		return _formatError( "file is too short" )
	}

	my $seekOffset = 0;
	my $pos = -1;
	for ( ;; )
	{
		$seekOffset += 512;
		$seekOffset = $fileLength if ( $seekOffset > $fileLength );
		$fh->seek( -$seekOffset, IO::Seekable::SEEK_END )
			or return _ioError( "seek failed" );
		$fh->read( $data, $seekOffset )
			or return _ioError( "read failed" );
		$pos = rindex( $data, END_OF_CENTRAL_DIRECTORY_SIGNATURE_STRING );
		last if ( $pos > 0
			or $seekOffset == $fileLength
			or $seekOffset >= $Archive::Zip::ChunkSize );
	}

	if ( $pos >= 0 )
	{
		$fh->seek( $pos - $seekOffset, IO::Seekable::SEEK_CUR )
			or return _ioError( "seeking to EOCD" );
		return AZ_OK;
	}
	else
	{
		return _formatError( "can't find EOCD signature" );
	}
}

=back

=head1 MEMBER OPERATIONS

=head2 Class Methods

Several constructors allow you to construct members without adding
them to a zip archive.

These work the same as the addFile(), addDirectory(), and addString()
zip instance methods described above, but they don't add the new members
to a zip.

=over 4

=cut

# ----------------------------------------------------------------------
# class Archive::Zip::Member
# A generic member of an archive ( abstract )
# ----------------------------------------------------------------------
package Archive::Zip::Member;
use vars qw( @ISA );
@ISA = qw ( Archive::Zip );

BEGIN { use Archive::Zip qw( :CONSTANTS :ERROR_CODES :PKZIP_CONSTANTS
	:UTILITY_METHODS ) }

use Time::Local ();
use Compress::Zlib qw( Z_OK Z_STREAM_END MAX_WBITS );
use File::Path;
use File::Basename;

use constant ZIPFILEMEMBERCLASS	=> 'Archive::Zip::ZipFileMember';
use constant NEWFILEMEMBERCLASS	=> 'Archive::Zip::NewFileMember';
use constant STRINGMEMBERCLASS	=> 'Archive::Zip::StringMember';
use constant DIRECTORYMEMBERCLASS	=> 'Archive::Zip::DirectoryMember';

# Unix perms for default creation of files/dirs.
use constant DEFAULT_DIRECTORY_PERMISSIONS => 040755;
use constant DEFAULT_FILE_PERMISSIONS => 0100666;
use constant DIRECTORY_ATTRIB => 040000;
use constant FILE_ATTRIB => 0100000;

# Returns self if successful, else undef
# Assumes that fh is positioned at beginning of central directory file header.
# Leaves fh positioned immediately after file header or EOCD signature.
sub _newFromZipFile # Archive::Zip::Member
{
	my $class = shift;
	my $self = $class->ZIPFILEMEMBERCLASS->_newFromZipFile( @_ );
	return $self;
}

#--------------------------------

=item Archive::Zip::Member->newFromString( $stringOrStringRef [, $fileName] )

Construct a new member from the given string. Returns undef on error.

    my $member = Archive::Zip::Member->newFromString( 'This is a test',
                                                     'xyz.txt' );

=cut

sub newFromString	# Archive::Zip::Member
{
	my $class = shift;
	my $self = $class->STRINGMEMBERCLASS->_newFromString( @_ );
	return $self;
}

#--------------------------------

=item newFromFile( $fileName )

Construct a new member from the given file. Returns undef on error.

    my $member = Archive::Zip::Member->newFromFile( 'xyz.txt' );

=cut

sub newFromFile	# Archive::Zip::Member
{
	my $class = shift;
	my $self = $class->NEWFILEMEMBERCLASS->_newFromFileNamed( @_ );
	return $self;
}

#--------------------------------

=item newDirectoryNamed( $directoryName )

Construct a new member from the given directory.
Returns undef on error.

    my $member = Archive::Zip::Member->newDirectoryNamed( 'CVS/' );

=cut

sub newDirectoryNamed # Archive::Zip::Member
{
	my $class = shift;
	my $self = $class->DIRECTORYMEMBERCLASS->_newNamed( @_ );
	return $self;
}

sub new	# Archive::Zip::Member
{
	my $class = shift;
	my $self = {
		'lastModFileDateTime' => 0,
		'fileAttributeFormat' => FA_UNIX,
		'versionMadeBy' => 20,
		'versionNeededToExtract' => 20,
		'bitFlag' => 0,
		'compressionMethod' => COMPRESSION_STORED,
		'desiredCompressionMethod' => COMPRESSION_STORED,
		'desiredCompressionLevel' => COMPRESSION_LEVEL_NONE,
		'internalFileAttributes' => 0,
		'externalFileAttributes' => 0,	# set later
		'fileName' => '',
		'cdExtraField' => '',
		'localExtraField' => '',
		'fileComment' => '',
		'crc32' => 0,
		'compressedSize' => 0,
		'uncompressedSize' => 0,
		@_
	};
	bless( $self, $class );
	$self->unixFileAttributes( $self->DEFAULT_FILE_PERMISSIONS );
	return $self;
}

sub _becomeDirectoryIfNecessary	# Archive::Zip::Member
{
	my $self = shift;
	$self->_become( DIRECTORYMEMBERCLASS )
		if $self->isDirectory();
	return $self;
}

# Morph into given class (do whatever cleanup I need to do)
sub _become	# Archive::Zip::Member
{
	return bless( $_[0], $_[1] );
}

=back

=head2 Simple accessors

These methods get (and/or set) member attribute values.

=over 4

=cut

#--------------------------------

=item versionMadeBy()

Gets the field from my member header.

=cut

sub versionMadeBy	# Archive::Zip::Member
{ shift->{'versionMadeBy'} }

#--------------------------------

=item fileAttributeFormat( [$format] )

Gets or sets the field from the member header.
These are C<FA_*> values.

=cut

sub fileAttributeFormat	# Archive::Zip::Member
{
	( $#_ > 0 ) ? ( $_[0]->{'fileAttributeFormat'} = $_[1] )
		: $_[0]->{'fileAttributeFormat'}
}

#--------------------------------

=item versionNeededToExtract()

Gets the field from my member header.

=cut

sub versionNeededToExtract	# Archive::Zip::Member
{ shift->{'versionNeededToExtract'} }

#--------------------------------

=item bitFlag()

Gets the general purpose bit field from my member header.
This is where the C<GPBF_*> bits live.

=cut

sub bitFlag	# Archive::Zip::Member
{ shift->{'bitFlag'} }

#--------------------------------

=item compressionMethod()

Returns my compression method. This is the method that is
currently being used to compress my data.

This will be COMPRESSION_STORED for added string or file members,
or any of the C<COMPRESSION_*> values for members from a zip file.
However, this module can only handle members whose data is in
COMPRESSION_STORED or COMPRESSION_DEFLATED format.

=cut

sub compressionMethod	# Archive::Zip::Member
{ shift->{'compressionMethod'} }

#--------------------------------

=item desiredCompressionMethod( [$method] )

Get or set my desiredCompressionMethod
This is the method that will be used to write.
Returns prior desiredCompressionMethod.

Only COMPRESSION_DEFLATED or COMPRESSION_STORED are valid arguments.

Changing to COMPRESSION_STORED will change my desiredCompressionLevel
to 0; changing to COMPRESSION_DEFLATED will change my
desiredCompressionLevel to COMPRESSION_LEVEL_DEFAULT.

=cut

sub desiredCompressionMethod	# Archive::Zip::Member
{
	my $self = shift;
	my $newDesiredCompressionMethod = shift;
	my $oldDesiredCompressionMethod = $self->{'desiredCompressionMethod'};
	if ( defined( $newDesiredCompressionMethod ))
	{
		$self->{'desiredCompressionMethod'} = $newDesiredCompressionMethod;
		if ( $newDesiredCompressionMethod == COMPRESSION_STORED )
		{
			$self->{'desiredCompressionLevel'} = 0;
		}
		elsif ( $oldDesiredCompressionMethod == COMPRESSION_STORED )
		{
			$self->{'desiredCompressionLevel'} = COMPRESSION_LEVEL_DEFAULT;
		}
	}
	return $oldDesiredCompressionMethod;
}

#--------------------------------

=item desiredCompressionLevel( [$method] )

Get or set my desiredCompressionLevel
This is the method that will be used to write.
Returns prior desiredCompressionLevel.

Valid arguments are 0 through 9, COMPRESSION_LEVEL_NONE,
COMPRESSION_LEVEL_DEFAULT, COMPRESSION_LEVEL_BEST_COMPRESSION, and
COMPRESSION_LEVEL_FASTEST.

0 or COMPRESSION_LEVEL_NONE will change the desiredCompressionMethod
to COMPRESSION_STORED. All other arguments will change the
desiredCompressionMethod to COMPRESSION_DEFLATED.

=cut

sub desiredCompressionLevel	# Archive::Zip::Member
{
	my $self = shift;
	my $newDesiredCompressionLevel = shift;
	my $oldDesiredCompressionLevel = $self->{'desiredCompressionLevel'};
	if ( defined( $newDesiredCompressionLevel ))
	{
		$self->{'desiredCompressionLevel'} = $newDesiredCompressionLevel;
		$self->{'desiredCompressionMethod'} = ( $newDesiredCompressionLevel
			? COMPRESSION_DEFLATED
			: COMPRESSION_STORED );
	}
	return $oldDesiredCompressionLevel;
}

#--------------------------------

=item fileName()

Get or set my internal filename.
Returns the (possibly new) filename.

Names will have backslashes converted to forward slashes,
and will have multiple consecutive slashes converted to single ones.

=cut

sub fileName	# Archive::Zip::Member
{
	my $self = shift;
	my $newName = shift;
	if ( $newName )
	{
		$newName =~ s{[\\/]+}{/}g;	# deal with dos/windoze problems
		$self->{'fileName'} = $newName;
	}
	return $self->{'fileName'}
}

#--------------------------------

=item lastModFileDateTime()

Return my last modification date/time stamp in MS-DOS format.

=cut

sub lastModFileDateTime	# Archive::Zip::Member
{ shift->{'lastModFileDateTime'} }

#--------------------------------

=item lastModTime()

Return my last modification date/time stamp,
converted to unix localtime format.

    print "Mod Time: " . scalar( localtime( $member->lastModTime() ) );

=cut

sub lastModTime	# Archive::Zip::Member
{
	my $self = shift;
	return _dosToUnixTime( $self->lastModFileDateTime() );
}

#--------------------------------

=item setLastModFileDateTimeFromUnix()

Set my lastModFileDateTime from the given unix time.

    $member->setLastModFileDateTimeFromUnix( time() );

=cut

sub setLastModFileDateTimeFromUnix	# Archive::Zip::Member
{
	my $self = shift;
	my $time_t = shift;
	$self->{'lastModFileDateTime'} = _unixToDosTime( $time_t );
}

# Convert DOS date/time format to unix time_t format
# NOT AN OBJECT METHOD!
sub _dosToUnixTime	# Archive::Zip::Member
{
	my $dt = shift;

	my $year = ( ( $dt >> 25 ) & 0x7f ) + 80;
	my $mon  = ( ( $dt >> 21 ) & 0x0f ) - 1;
	my $mday = ( ( $dt >> 16 ) & 0x1f );

	my $hour = ( ( $dt >> 11 ) & 0x1f );
	my $min  = ( ( $dt >> 5 ) & 0x3f );
	my $sec  = ( ( $dt << 1 ) & 0x3e );

	my $time_t = Time::Local::timelocal( $sec, $min, $hour, $mday, $mon, $year );
	return $time_t;
}

#--------------------------------

=item internalFileAttributes()

Return the internal file attributes field from the zip header.
This is only set for members read from a zip file.

=cut

sub internalFileAttributes	# Archive::Zip::Member
{ shift->{'internalFileAttributes'} }

#--------------------------------

=item externalFileAttributes()

Return member attributes as read from the ZIP file.
Note that these are NOT UNIX!

=cut

sub externalFileAttributes	# Archive::Zip::Member
{ shift->{'externalFileAttributes'} }

# Convert UNIX permissions into proper value for zip file
# NOT A METHOD!
sub _mapPermissionsFromUnix	# Archive::Zip::Member
{
	my $perms = shift;
	return $perms << 16;
}

# Convert ZIP permissions into Unix ones
# NOT A METHOD!
sub _mapPermissionsToUnix	# Archive::Zip::Member
{
	my $perms = shift;
	return $perms >> 16;
}

#--------------------------------

=item unixFileAttributes( [$newAttributes] )

Get or set the member's file attributes using UNIX file attributes.
Returns old attributes.

    my $oldAttribs = $member->unixFileAttributes( 0666 );

Note that the return value has more than just the file permissions,
so you will have to mask off the lowest bits for comparisions.

=cut

sub unixFileAttributes	# Archive::Zip::Member
{
	my $self = shift;
	my $oldPerms = _mapPermissionsToUnix( $self->{'externalFileAttributes'} );
	if ( @_ )
	{
		my $perms = shift;
		if ( $self->isDirectory() )
		{
			$perms &= ~FILE_ATTRIB;
			$perms |= DIRECTORY_ATTRIB;
		}
		else
		{
			$perms &= ~DIRECTORY_ATTRIB;
			$perms |= FILE_ATTRIB;
		}
		$self->{'externalFileAttributes'} = _mapPermissionsFromUnix( $perms);
	}
	return $oldPerms;
}

#--------------------------------

=item localExtraField( [$newField] )

Gets or sets the extra field that was read from the local header.
This is not set for a member from a zip file until after the
member has been written out.

The extra field must be in the proper format.

=cut

sub localExtraField	# Archive::Zip::Member
{
	( $#_ > 0 ) ? ( $_[0]->{'localExtraField'} = $_[1] )
		: $_[0]->{'localExtraField'}
}

#--------------------------------

=item cdExtraField( [$newField] )

Gets or sets the extra field that was read from the central directory header.

The extra field must be in the proper format.

=cut

sub cdExtraField	# Archive::Zip::Member
{
	( $#_ > 0 ) ? ( $_[0]->{'cdExtraField'} = $_[1] )
		: $_[0]->{'cdExtraField'}
}

#--------------------------------

=item extraFields()

Return both local and CD extra fields, concatenated.

=cut

sub extraFields	# Archive::Zip::Member
{
	my $self = shift;
	return $self->localExtraField() . $self->cdExtraField();
}

#--------------------------------

=item fileComment( [$newComment] )

Get or set the member's file comment.

=cut

sub fileComment	# Archive::Zip::Member
{
	( $#_ > 0 ) ? ( $_[0]->{'fileComment'} = $_[1] )
		: $_[0]->{'fileComment'}
}

#--------------------------------

=item hasDataDescriptor()

Get or set the data descriptor flag.
If this is set, the local header will not necessarily
have the correct data sizes. Instead, a small structure
will be stored at the end of the member data with these
values.

This should be transparent in normal operation.

=cut

sub hasDataDescriptor	# Archive::Zip::Member
{
	my $self = shift;
	if ( @_ )
	{
		my $shouldHave = shift;
		if ( $shouldHave )
		{
			$self->{'bitFlag'} |= GPBF_HAS_DATA_DESCRIPTOR_MASK
		}
		else
		{
			$self->{'bitFlag'} &= ~GPBF_HAS_DATA_DESCRIPTOR_MASK
		}
	}
	return $self->{'bitFlag'} & GPBF_HAS_DATA_DESCRIPTOR_MASK;
}

#--------------------------------

=item crc32()

Return the CRC-32 value for this member.
This will not be set for members that were constructed from strings
or external files until after the member has been written.

=cut

sub crc32	# Archive::Zip::Member
{ shift->{'crc32'} }

#--------------------------------

=item crc32String()

Return the CRC-32 value for this member as an 8 character printable
hex string.  This will not be set for members that were constructed
from strings or external files until after the member has been written.

=cut

sub crc32String	# Archive::Zip::Member
{ sprintf( "%08x", shift->{'crc32'} ); }

#--------------------------------

=item compressedSize()

Return the compressed size for this member.
This will not be set for members that were constructed from strings
or external files until after the member has been written.

=cut

sub compressedSize	# Archive::Zip::Member
{ shift->{'compressedSize'} }

#--------------------------------

=item uncompressedSize()

Return the uncompressed size for this member.

=cut

sub uncompressedSize	# Archive::Zip::Member
{ shift->{'uncompressedSize'} }

#--------------------------------

=item isEncrypted()

Return true if this member is encrypted.
The Archive::Zip module does not currently create or extract
encrypted members.

=cut

sub isEncrypted	# Archive::Zip::Member
{ shift->bitFlag() & GPBF_ENCRYPTED_MASK }


#--------------------------------

=item isTextFile( [$flag] )

Returns true if I am a text file.
Also can set the status if given an argument (then returns old state).
Note that this module does not currently do anything with this flag
upon extraction or storage.
That is, bytes are stored in native format whether or not they came
from a text file.

=cut

sub isTextFile	# Archive::Zip::Member
{
	my $self = shift;
	my $bit = $self->internalFileAttributes() & IFA_TEXT_FILE_MASK;
	if ( @_ )
	{
		my $flag = shift;
		$self->{'internalFileAttributes'} &= ~IFA_TEXT_FILE_MASK;
		$self->{'internalFileAttributes'} |=
			( $flag ? IFA_TEXT_FILE : IFA_BINARY_FILE );
	}
	return $bit == IFA_TEXT_FILE;
}

#--------------------------------

=item isBinaryFile()

Returns true if I am a binary file.
Also can set the status if given an argument (then returns old state).
Note that this module does not currently do anything with this flag
upon extraction or storage.
That is, bytes are stored in native format whether or not they came
from a text file.

=cut

sub isBinaryFile	# Archive::Zip::Member
{
	my $self = shift;
	my $bit = $self->internalFileAttributes() & IFA_TEXT_FILE_MASK;
	if ( @_ )
	{
		my $flag = shift;
		$self->{'internalFileAttributes'} &= ~IFA_TEXT_FILE_MASK;
		$self->{'internalFileAttributes'} |=
			( $flag ? IFA_BINARY_FILE : IFA_TEXT_FILE );
	}
	return $bit == IFA_BINARY_FILE;
}

#--------------------------------

=item extractToFileNamed( $fileName )

Extract me to a file with the given name.
The file will be created with default modes.
Directories will be created as needed.

Returns AZ_OK on success.

=cut

sub extractToFileNamed	# Archive::Zip::Member
{
	my $self = shift;
	my $name = shift;
	return _error( "encryption unsupported" ) if $self->isEncrypted();
	mkpath( dirname( $name ) );	# croaks on error
	my ( $status, $fh ) = _newFileHandle( $name, 'w' );
	return _ioError( "Can't open file $name for write" ) if !$status;
	my $retval = $self->extractToFileHandle( $fh );
	$fh->close();
	return $retval;
}

#--------------------------------

=item isDirectory()

Returns true if I am a directory.

=cut

sub isDirectory	# Archive::Zip::Member
{ return 0 }

# The following are used when copying data
sub _writeOffset	# Archive::Zip::Member
{ shift->{'writeOffset'} }

sub _readOffset	# Archive::Zip::Member
{ shift->{'readOffset'} }

sub _writeLocalHeaderRelativeOffset	# Archive::Zip::Member
{ shift->{'writeLocalHeaderRelativeOffset'} }

sub _dataEnded	# Archive::Zip::Member
{ shift->{'dataEnded'} }

sub _readDataRemaining	# Archive::Zip::Member
{ shift->{'readDataRemaining'} }

sub _inflater	# Archive::Zip::Member
{ shift->{'inflater'} }

sub _deflater	# Archive::Zip::Member
{ shift->{'deflater'} }

# Return the total size of my local header
sub _localHeaderSize	# Archive::Zip::Member
{
	my $self = shift;
	return SIGNATURE_LENGTH
		+ LOCAL_FILE_HEADER_LENGTH
		+ length( $self->fileName() )
		+ length( $self->localExtraField() )
}

# Return the total size of my CD header
sub _centralDirectoryHeaderSize	# Archive::Zip::Member
{
	my $self = shift;
	return SIGNATURE_LENGTH
		+ CENTRAL_DIRECTORY_FILE_HEADER_LENGTH
		+ length( $self->fileName() )
		+ length( $self->cdExtraField() )
		+ length( $self->fileComment() )
}

# convert a unix time to DOS date/time
# NOT AN OBJECT METHOD!
sub _unixToDosTime	# Archive::Zip::Member
{
	my $time_t = shift;
	my ( $sec,$min,$hour,$mday,$mon,$year ) = localtime( $time_t );
	my $dt = 0;
	$dt += ( $sec >> 1 );
	$dt += ( $min << 5 );
	$dt += ( $hour << 11 );
	$dt += ( $mday << 16 );
	$dt += ( ( $mon + 1 ) << 21 );
	$dt += ( ( $year - 80 ) << 25 );
	return $dt;
}

# Write my local header to a file handle.
# Stores the offset to the start of the header in my
# writeLocalHeaderRelativeOffset member.
# Returns AZ_OK on success.
sub _writeLocalFileHeader	# Archive::Zip::Member
{
	my $self = shift;
	my $fh = shift;

	my $signatureData = pack( SIGNATURE_FORMAT, LOCAL_FILE_HEADER_SIGNATURE );
	$fh->write( $signatureData, SIGNATURE_LENGTH )
		or return _ioError( "writing local header signature" );

	my $header = pack( LOCAL_FILE_HEADER_FORMAT,
		$self->versionNeededToExtract(),
		$self->bitFlag(),
		$self->desiredCompressionMethod(),
		$self->lastModFileDateTime(),
		$self->crc32(),
		$self->compressedSize(),		# may need to be re-written later
		$self->uncompressedSize(),
		length( $self->fileName() ),
		length( $self->localExtraField() )
		 );

	$fh->write( $header, LOCAL_FILE_HEADER_LENGTH )
		or return _ioError( "writing local header" );
	if ( length( $self->fileName() ))
	{
		$fh->write( $self->fileName(), length( $self->fileName() ))
			or return _ioError( "writing local header filename" );
	}
	if ( length( $self->localExtraField() ))
	{
		$fh->write( $self->localExtraField(), length( $self->localExtraField() ))
			or return _ioError( "writing local header signature" );
	}

	return AZ_OK;
}

sub _writeCentralDirectoryFileHeader	# Archive::Zip::Member
{
	my $self = shift;
	my $fh = shift;

	my $sigData = pack( SIGNATURE_FORMAT,
		CENTRAL_DIRECTORY_FILE_HEADER_SIGNATURE );
	$fh->write( $sigData, SIGNATURE_LENGTH )
		or return _ioError( "writing central directory header signature" );

	my $fileNameLength = length( $self->fileName() );
	my $extraFieldLength = length( $self->cdExtraField() );
	my $fileCommentLength = length( $self->fileComment() );

	my $header = pack( CENTRAL_DIRECTORY_FILE_HEADER_FORMAT,
		$self->versionMadeBy(),
		$self->fileAttributeFormat(),
		$self->versionNeededToExtract(),
		$self->bitFlag(),
		$self->desiredCompressionMethod(),
		$self->lastModFileDateTime(),
		$self->crc32(),			# these three fields should have been updated
		$self->_writeOffset(),	# by writing the data stream out
		$self->uncompressedSize(),	#
		$fileNameLength,
		$extraFieldLength,
		$fileCommentLength,
		0,						# {'diskNumberStart'},
		$self->internalFileAttributes(),
		$self->externalFileAttributes(),
		$self->_writeLocalHeaderRelativeOffset()
	 );

	$fh->write( $header, CENTRAL_DIRECTORY_FILE_HEADER_LENGTH )
		or return _ioError( "writing central directory header" );
	if ( $fileNameLength )
	{
		$fh->write( $self->fileName(), $fileNameLength )
			or return _ioError( "writing central directory header signature" );
	}
	if ( $extraFieldLength )
	{
		$fh->write( $self->cdExtraField(), $extraFieldLength )
			or return _ioError( "writing central directory extra field" );
	}
	if ( $fileCommentLength )
	{
		$fh->write( $self->fileComment(), $fileCommentLength )
			or return _ioError( "writing central directory file comment" );
	}

	return AZ_OK;
}

# This writes a data descriptor to the given file handle.
# Assumes that crc32, writeOffset, and uncompressedSize are
# set correctly (they should be after a write).
# Further, the local file header should have the
# GPBF_HAS_DATA_DESCRIPTOR_MASK bit set.
sub _writeDataDescriptor	# Archive::Zip::Member
{
	my $self = shift;
	my $fh = shift;
	my $header = pack( DATA_DESCRIPTOR_FORMAT,
		$self->crc32(),
		$self->_writeOffset(),
		$self->uncompressedSize()
	 );

	$fh->write( $header, DATA_DESCRIPTOR_LENGTH )
		or return _ioError( "writing data descriptor" );
	return AZ_OK;
}

# Re-writes the local file header with new crc32 and compressedSize fields.
# To be called after writing the data stream.
# Assumes that filename and extraField sizes didn't change since last written.
sub _refreshLocalFileHeader	# Archive::Zip::Member
{
	my $self = shift;
	my $fh = shift;

	my $here = $fh->tell();
	$fh->seek( $self->_writeLocalHeaderRelativeOffset() + SIGNATURE_LENGTH,
		IO::Seekable::SEEK_SET )
			or return _ioError( "seeking to rewrite local header" );

	my $header = pack( LOCAL_FILE_HEADER_FORMAT,
		$self->versionNeededToExtract(),
		$self->bitFlag(),
		$self->desiredCompressionMethod(),
		$self->lastModFileDateTime(),
		$self->crc32(),
		$self->_writeOffset(),
		$self->uncompressedSize(),
		length( $self->fileName() ),
		length( $self->localExtraField() )
		 );

	$fh->write( $header, LOCAL_FILE_HEADER_LENGTH )
		or return _ioError( "re-writing local header" );
	$fh->seek( $here, IO::Seekable::SEEK_SET )
			or return _ioError( "seeking after rewrite of local header" );

	return AZ_OK;
}

=back

=head2 Low-level member data reading

It is possible to use lower-level routines to access member
data streams, rather than the extract* methods and contents().

For instance, here is how to print the uncompressed contents
of a member in chunks using these methods:

    my ( $member, $status, $bufferRef );
    $member = $zip->memberNamed( 'xyz.txt' );
    $member->desiredCompressionMethod( COMPRESSION_STORED );
    $status = $member->rewindData();
    die "error $status" if $status != AZ_OK;
    while ( ! $member->readIsDone() )
    {
        ( $bufferRef, $status ) = $member->readChunk();
        die "error $status" if $status != AZ_OK;
        # do something with $bufferRef:
        print $$bufferRef;
    }
    $member->endRead();

=over 4

=cut

#--------------------------------

=item readChunk( [$chunkSize] )

This reads the next chunk of given size from the member's data stream and
compresses or uncompresses it as necessary, returning a reference to the bytes
read and a status.
If size argument is not given, defaults to global set by
Archive::Zip::setChunkSize.
Status is AZ_OK on success. Returns C<( \$bytes, $status)>.

    my ( $outRef, $status ) = $self->readChunk();
    print $$outRef if $status != AZ_OK;

=cut

sub readChunk	# Archive::Zip::Member
{
	my ( $self, $chunkSize ) = @_;

	if ( $self->readIsDone() )
	{
		$self->endRead();
		my $dummy = '';
		return ( \$dummy, AZ_STREAM_END );
	}

	$chunkSize = $Archive::Zip::ChunkSize if not defined( $chunkSize );
	$chunkSize = $self->_readDataRemaining()
		if $chunkSize > $self->_readDataRemaining();

	my $buffer = '';
	my $outputRef;
	my ( $bytesRead, $status) = $self->_readRawChunk( \$buffer, $chunkSize );
	return ( \$buffer, $status) if $status != AZ_OK;

	$self->{'readDataRemaining'} -= $bytesRead;
	$self->{'readOffset'} += $bytesRead;

	if ( $self->compressionMethod() == COMPRESSION_STORED )
	{
		$self->{'crc32'} = $self->computeCRC32( $buffer, $self->{'crc32'} );
	}

	( $outputRef, $status) = &{$self->{'chunkHandler'}}( $self, \$buffer );
	$self->{'writeOffset'} += length( $$outputRef );

	$self->endRead()
		if $self->readIsDone();

	return ( $outputRef, $status);
}

# Read the next raw chunk of my data. Subclasses MUST implement.
#	my ( $bytesRead, $status) = $self->_readRawChunk( \$buffer, $chunkSize );
sub _readRawChunk	# Archive::Zip::Member
{
	my $self = shift;
	return $self->_subclassResponsibility();
}

# A place holder to catch rewindData errors if someone ignores
# the error code.
sub _noChunk	# Archive::Zip::Member
{
	my $self = shift;
	return ( \undef, _error( "trying to copy chunk when init failed" ));
}

# Basically a no-op so that I can have a consistent interface.
# ( $outputRef, $status) = $self->_copyChunk( \$buffer );
sub _copyChunk	# Archive::Zip::Member
{
	my ( $self, $dataRef ) = @_;
	return ( $dataRef, AZ_OK );
}


# ( $outputRef, $status) = $self->_deflateChunk( \$buffer );
sub _deflateChunk	# Archive::Zip::Member
{
	my ( $self, $buffer ) = @_;
	my ( $out, $status ) = $self->_deflater()->deflate( $buffer );

	if ( $self->_readDataRemaining() == 0 )
	{
		my $extraOutput;
		( $extraOutput, $status ) = $self->_deflater()->flush();
		$out .= $extraOutput;
		$self->endRead();
		return ( \$out, AZ_STREAM_END );
	}
	elsif ( $status == Z_OK )
	{
		return ( \$out, AZ_OK );
	}
	else
	{
		$self->endRead();
		my $retval = _error( 'deflate error', $status);
		my $dummy = '';
		return ( \$dummy, $retval );
	}
}

# ( $outputRef, $status) = $self->_inflateChunk( \$buffer );
sub _inflateChunk	# Archive::Zip::Member
{
	my ( $self, $buffer ) = @_;
	my ( $out, $status ) = $self->_inflater()->inflate( $buffer );
	my $retval;
	$self->endRead() if ( $status != Z_OK );
	if ( $status == Z_OK || $status == Z_STREAM_END )
	{
		$retval = ( $status == Z_STREAM_END )
			? AZ_STREAM_END : AZ_OK;
		return ( \$out, $retval );
	}
	else
	{
		$retval = _error( 'inflate error', $status);
		my $dummy = '';
		return ( \$dummy, $retval );
	}
}

#--------------------------------

=item rewindData()

Rewind data and set up for reading data streams or writing zip files.
Can take options for C<inflateInit()> or C<deflateInit()>,
but this isn't likely to be necessary.
Subclass overrides should call this method.
Returns C<AZ_OK> on success.

=cut

sub rewindData	# Archive::Zip::Member
{
	my $self = shift;
	my $status;

	# set to trap init errors
	$self->{'chunkHandler'} = $self->can( '_noChunk' );

	# Work around WinZip defect with 0-length DEFLATED files
	$self->desiredCompressionMethod( COMPRESSION_STORED )
		if $self->uncompressedSize() == 0;

	# assume that we're going to read the whole file, and compute the CRC anew.
	$self->{'crc32'} = 0 if ( $self->compressionMethod() == COMPRESSION_STORED );

	# These are the only combinations of methods we deal with right now.
	if ( $self->compressionMethod() == COMPRESSION_STORED
			and $self->desiredCompressionMethod() == COMPRESSION_DEFLATED )
	{
		( $self->{'deflater'}, $status ) = Compress::Zlib::deflateInit(
			'-Level' => $self->desiredCompressionLevel(),
			'-WindowBits' => - MAX_WBITS(), # necessary magic
			@_ );	# pass additional options
		return _error( 'deflateInit error:', $status ) if $status != Z_OK;
		$self->{'chunkHandler'} = $self->can( '_deflateChunk' );
	}
	elsif ( $self->compressionMethod() == COMPRESSION_DEFLATED
			and $self->desiredCompressionMethod() == COMPRESSION_STORED )
	{
		( $self->{'inflater'}, $status ) = Compress::Zlib::inflateInit(
			'-WindowBits' => - MAX_WBITS(), # necessary magic
			@_ );	# pass additional options
		return _error( 'inflateInit error:', $status ) if $status != Z_OK;
		$self->{'chunkHandler'} = $self->can( '_inflateChunk' );
	}
	elsif ( $self->compressionMethod() == $self->desiredCompressionMethod() )
	{
		$self->{'chunkHandler'} = $self->can( '_copyChunk' );
	}
	else
	{
		return _error(
			sprintf( "Unsupported compression combination: read %d, write %d",
				$self->compressionMethod(),
				$self->desiredCompressionMethod() )
		 );
	}

	$self->{'dataEnded'} = 0;
	$self->{'readDataRemaining'} = $self->compressedSize();
	$self->{'readOffset'} = 0;

	return AZ_OK;
}

#--------------------------------

=item endRead()

Reset the read variables and free the inflater or deflater.
Must be called to close files, etc.

Returns AZ_OK on success.

=cut

sub endRead	# Archive::Zip::Member
{
	my $self = shift;
	delete $self->{'inflater'};
	delete $self->{'deflater'};
	$self->{'dataEnded'} = 1;
	$self->{'readDataRemaining'} = 0;
	return AZ_OK;
}

#--------------------------------

=item readIsDone()

Return true if the read has run out of data or errored out.

=cut

sub readIsDone	# Archive::Zip::Member
{
	my $self = shift;
	return ( $self->_dataEnded() or ! $self->_readDataRemaining() );
}

#--------------------------------

=item contents()

Return the entire uncompressed member data or undef in scalar context.
When called in array context, returns C<( $string, $status )>; status
will be AZ_OK on success:

    my $string = $member->contents();
    # or
    my ( $string, $status ) = $member->contents();
    die "error $status" if $status != AZ_OK;

Can also be used to set the contents of a member (this may change
the class of the member):

    $member->contents( "this is my new contents" );

=cut

sub contents	# Archive::Zip::Member
{
	my $self = shift;
	my $newContents = shift;
	if ( defined( $newContents ) )
	{
		$self->_become( STRINGMEMBERCLASS );
		return $self->contents( $newContents );
	}
	else
	{
		my $oldCompression = 
			$self->desiredCompressionMethod( COMPRESSION_STORED );
		my $status = $self->rewindData( @_ );
		if ( $status != AZ_OK )
		{
			$self->endRead();
			return $status;
		}
		my $retval = '';
		while ( $status == AZ_OK )
		{
			my $ref;
			( $ref, $status ) = $self->readChunk( $self->_readDataRemaining() );
			# did we get it in one chunk?
			if ( length( $$ref ) == $self->uncompressedSize() )
			{ $retval = $$ref }
			else
			{ $retval .= $$ref }
		}
		$self->desiredCompressionMethod( $oldCompression );
		$self->endRead();
		$status = AZ_OK if $status == AZ_STREAM_END;
		$retval = undef if $status != AZ_OK;
		return wantarray ? ( $retval, $status ) : $retval;
	}
}

#--------------------------------

=item extractToFileHandle( $fh )

Extract (and uncompress, if necessary) my contents to the given file handle.
Return AZ_OK on success.

=cut

sub extractToFileHandle	# Archive::Zip::Member
{
	my $self = shift;
	return _error( "encryption unsupported" ) if $self->isEncrypted();
	my $fh = shift;
	_binmode( $fh );
	my $oldCompression = $self->desiredCompressionMethod( COMPRESSION_STORED );
	my $status = $self->rewindData( @_ );
	$status = $self->_writeData( $fh ) if $status == AZ_OK;
	$self->desiredCompressionMethod( $oldCompression );
	$self->endRead();
	return $status;
}

# write local header and data stream to file handle
sub _writeToFileHandle	# Archive::Zip::Member
{
	my $self = shift;
	my $fh = shift;
	my $fhIsSeekable = shift;

	# Determine if I need to write a data descriptor
	# I need to do this if I can't refresh the header
	# and I don't know compressed size or crc32 fields.
	my $headerFieldsUnknown = ( ( $self->uncompressedSize() > 0 )
		and ( $self->compressionMethod() == COMPRESSION_STORED
			or $self->desiredCompressionMethod() == COMPRESSION_DEFLATED ) );

	my $shouldWriteDataDescriptor =
		( $headerFieldsUnknown and not $fhIsSeekable );

	$self->hasDataDescriptor( 1 )
		if ( $shouldWriteDataDescriptor );

	$self->{'writeOffset'} = 0;

	my $status = $self->rewindData();
	( $status = $self->_writeLocalFileHeader( $fh ) )
		if $status == AZ_OK;
	( $status = $self->_writeData( $fh ) )
		if $status == AZ_OK;
	if ( $status == AZ_OK )
	{
		if ( $self->hasDataDescriptor() )
		{
			$status = $self->_writeDataDescriptor( $fh );
		}
		elsif ( $headerFieldsUnknown )
		{
			$status = $self->_refreshLocalFileHeader( $fh );
		}
	}

	return $status;
}

# Copy my (possibly compressed) data to given file handle.
# Returns C<AZ_OK> on success
sub _writeData	# Archive::Zip::Member
{
	my $self = shift;
	my $writeFh = shift;

	return AZ_OK if ( $self->uncompressedSize() == 0 );
	my $status;
	my $chunkSize = $Archive::Zip::ChunkSize;
	while ( $self->_readDataRemaining() > 0 )
	{
		my $outRef;
		( $outRef, $status ) = $self->readChunk( $chunkSize );
		return $status if ( $status != AZ_OK and $status != AZ_STREAM_END );

		$writeFh->write( $$outRef, length( $$outRef ) )
			or return _ioError( "write error during copy" );

		last if $status == AZ_STREAM_END;
	}
	return AZ_OK;
}


# Return true if I depend on the named file
sub _usesFileNamed
{
	return 0;
}

# ----------------------------------------------------------------------
# class Archive::Zip::DirectoryMember
# ----------------------------------------------------------------------

package Archive::Zip::DirectoryMember;
use File::Path;

use vars qw( @ISA );
@ISA = qw ( Archive::Zip::Member );
BEGIN { use Archive::Zip qw( :ERROR_CODES :UTILITY_METHODS ) }

sub _newNamed	# Archive::Zip::DirectoryMember
{
	my $class = shift;
	my $name = shift;
	my $self = $class->new( @_ );
	$self->fileName( $name );
	if ( -d $name )
	{
		my @stat = stat( _ );
		$self->unixFileAttributes( $stat[2] );
		$self->setLastModFileDateTimeFromUnix( $stat[9] );
	}
	else
	{
		$self->unixFileAttributes( $self->DEFAULT_DIRECTORY_PERMISSIONS );
		$self->setLastModFileDateTimeFromUnix( time() );
	}
	return $self;
}

sub isDirectory	# Archive::Zip::DirectoryMember
{ return 1; }

sub extractToFileNamed	# Archive::Zip::DirectoryMember
{
	my $self = shift;
	my $name = shift;
	my $attribs = $self->unixFileAttributes() & 07777;
	mkpath( $name, 0, $attribs );	# croaks on error
	return AZ_OK;
}

sub fileName	# Archive::Zip::DirectoryMember
{
	my $self = shift;
	my $newName = shift;
	$newName =~ s{/?$}{/} if defined( $newName );
	return $self->SUPER::fileName( $newName );
}

=back

=head1 Archive::Zip::FileMember methods

The Archive::Zip::FileMember class extends Archive::Zip::Member.
It is the base class for both ZipFileMember and NewFileMember classes.
This class adds an C<externalFileName> and an C<fh> member to keep
track of the external file.

=over 4

=cut

# ----------------------------------------------------------------------
# class Archive::Zip::FileMember
# Base class for classes that have file handles
# to external files
# ----------------------------------------------------------------------

package Archive::Zip::FileMember;
use vars qw( @ISA );
@ISA = qw ( Archive::Zip::Member );
BEGIN { use Archive::Zip qw( :UTILITY_METHODS ) }

#--------------------------------

=item externalFileName()

Return my external filename.

=cut

sub externalFileName	# Archive::Zip::FileMember
{ shift->{'externalFileName'} }

#--------------------------------

# Return true if I depend on the named file
sub _usesFileNamed
{
	my $self = shift;
	my $fileName = shift;
	return $self->externalFileName eq $fileName;
}

=item fh()

Return my read file handle.
Automatically opens file if necessary.

=cut

sub fh	# Archive::Zip::FileMember
{
	my $self = shift;
	$self->_openFile() if ! $self->{'fh'};
	return $self->{'fh'};
}

# opens my file handle from my file name
sub _openFile	# Archive::Zip::FileMember
{
	my $self = shift;
	my ( $status, $fh ) = _newFileHandle( $self->externalFileName(), 'r' );
	if ( !$status )
	{
		_ioError( "Can't open", $self->externalFileName() );
		return undef;
	}
	$self->{'fh'} = $fh;
	_binmode( $fh );
	return $fh;
}

# Closes my file handle
sub _closeFile	# Archive::Zip::FileMember
{
	my $self = shift;
	$self->{'fh'} = undef;
}

# Make sure I close my file handle
sub endRead	# Archive::Zip::FileMember
{
	my $self = shift;
	$self->_closeFile();
	return $self->SUPER::endRead( @_ );
}

sub _become	# Archive::Zip::FileMember
{
	my $self = shift;
	my $newClass = shift;
	return $self if ref( $self ) eq $newClass;
	delete( $self->{'externalFileName'} );
	delete( $self->{'fh'} );
	return $self->SUPER::_become( $newClass );
}

# ----------------------------------------------------------------------
# class Archive::Zip::NewFileMember
# Used when adding a pre-existing file to an archive
# ----------------------------------------------------------------------

package Archive::Zip::NewFileMember;
use vars qw( @ISA );
@ISA = qw ( Archive::Zip::FileMember );

BEGIN { use Archive::Zip qw( :CONSTANTS :ERROR_CODES :UTILITY_METHODS ) }

# Given a file name, set up for eventual writing.
sub _newFromFileNamed	# Archive::Zip::NewFileMember
{
	my $class = shift;
	my $fileName = shift;
	return undef if ! ( -r $fileName && ( -f _ || -l _ ) );
	my $self = $class->new( @_ );
	$self->fileName( $fileName );
	$self->{'externalFileName'} = $fileName;
	$self->{'compressionMethod'} = COMPRESSION_STORED;
	my @stat = stat( _ );
	$self->{'compressedSize'} = $self->{'uncompressedSize'} = $stat[7];
	$self->desiredCompressionMethod( ( $self->compressedSize() > 0 )
		? COMPRESSION_DEFLATED
		: COMPRESSION_STORED );
	$self->unixFileAttributes( $stat[2] );
	$self->setLastModFileDateTimeFromUnix( $stat[9] );
	$self->isTextFile( -T _ );
	return $self;
}

sub rewindData	# Archive::Zip::NewFileMember
{
	my $self = shift;

	my $status = $self->SUPER::rewindData( @_ );
	return $status if $status != AZ_OK;

	return AZ_IO_ERROR if ! $self->fh();
	$self->fh()->clearerr();
	$self->fh()->seek( 0, IO::Seekable::SEEK_SET )
		or return _ioError( "rewinding", $self->externalFileName() );
	return AZ_OK;
}

# Return bytes read. Note that first parameter is a ref to a buffer.
# my $data;
# my ( $bytesRead, $status) = $self->readRawChunk( \$data, $chunkSize );
sub _readRawChunk	# Archive::Zip::NewFileMember
{
	my ( $self, $dataRef, $chunkSize ) = @_;
	return ( 0, AZ_OK ) if ( ! $chunkSize );
	my $bytesRead = $self->fh()->read( $$dataRef, $chunkSize )
		or return ( 0, _ioError( "reading data" ) );
	return ( $bytesRead, AZ_OK );
}

# If I already exist, extraction is a no-op.
sub extractToFileNamed	# Archive::Zip::NewFileMember
{
	my $self = shift;
	my $name = shift;
	if ( $name eq $self->fileName() and -r $name )
	{
		return AZ_OK;
	}
	else
	{
		return $self->SUPER::extractToFileNamed( $name, @_ );
	}
}

=back

=head1 Archive::Zip::ZipFileMember methods

The Archive::Zip::ZipFileMember class represents members that have
been read from external zip files.

=over 4

=cut

# ----------------------------------------------------------------------
# class Archive::Zip::ZipFileMember
# This represents a member in an existing zip file on disk.
# ----------------------------------------------------------------------

package Archive::Zip::ZipFileMember;
use vars qw( @ISA );
@ISA = qw ( Archive::Zip::FileMember );

BEGIN { use Archive::Zip qw( :CONSTANTS :ERROR_CODES :PKZIP_CONSTANTS
	:UTILITY_METHODS ) }

# Create a new Archive::Zip::ZipFileMember
# given a filename and optional open file handle
sub _newFromZipFile	# Archive::Zip::ZipFileMember
{
	my $class = shift;
	my $fh = shift;
	my $externalFileName = shift;
	my $self = $class->new(
		'crc32' => 0,
		'diskNumberStart' => 0,
		'localHeaderRelativeOffset' => 0,
		'dataOffset' =>  0,	# localHeaderRelativeOffset + header length
		@_
	 );
	$self->{'externalFileName'} = $externalFileName;
	$self->{'fh'} = $fh;
	return $self;
}

sub isDirectory	# Archive::Zip::FileMember
{
	my $self = shift;
	return ( substr( $self->fileName(), -1, 1 ) eq '/'
		and $self->uncompressedSize() == 0 );
}

# Because I'm going to delete the file handle, read the local file
# header if the file handle is seekable. If it isn't, I assume that
# I've already read the local header.
# Return ( $status, $self )

sub _become	# Archive::Zip::ZipFileMember
{
	my $self = shift;
	my $newClass = shift;
	return $self if ref( $self ) eq $newClass;

	my $status = AZ_OK;

	if ( _isSeekable( $self->fh() ) )
	{
		my $here = $self->fh()->tell();
		$status = $self->fh()->seek(
			$self->localHeaderRelativeOffset() + SIGNATURE_LENGTH,
			IO::Seekable::SEEK_SET );
		if ( ! $status )
		{
			$self->fh()->seek( $here );
			_ioError( "seeking to local header" );
			return $self;
		}
		$self->_readLocalFileHeader();
		$self->fh()->seek( $here, IO::Seekable::SEEK_SET );
	}

	delete( $self->{'diskNumberStart'} );
	delete( $self->{'localHeaderRelativeOffset'} );
	delete( $self->{'dataOffset'} );

	return $self->SUPER::_become( $newClass );
}

#--------------------------------

=item diskNumberStart()

Returns the disk number that my local header resides
in. Had better be 0.

=cut

sub diskNumberStart	# Archive::Zip::ZipFileMember
{ shift->{'diskNumberStart'} }

#--------------------------------

=item localHeaderRelativeOffset()

Returns the offset into the zip file where my local header is.

=cut

sub localHeaderRelativeOffset	# Archive::Zip::ZipFileMember
{ shift->{'localHeaderRelativeOffset'} }

#--------------------------------

=item dataOffset()

Returns the offset from the beginning of the zip file to
my data.

=cut

sub dataOffset	# Archive::Zip::ZipFileMember
{ shift->{'dataOffset'} }

# Skip local file header, updating only extra field stuff.
# Assumes that fh is positioned before signature.
sub _skipLocalFileHeader	# Archive::Zip::ZipFileMember
{
	my $self = shift;
	my $header;
	$self->fh()->read( $header, LOCAL_FILE_HEADER_LENGTH )
		or return _ioError( "reading local file header" );
	my $fileNameLength;
	my $extraFieldLength;
	(	undef, 	# $self->{'versionNeededToExtract'},
		undef,	# $self->{'bitFlag'},
		undef,	# $self->{'compressionMethod'},
		undef,	# $self->{'lastModFileDateTime'},
		undef,	# $crc32,
		undef,	# $compressedSize,
		undef,	# $uncompressedSize,
		$fileNameLength,
		$extraFieldLength ) = unpack( LOCAL_FILE_HEADER_FORMAT, $header );

	if ( $fileNameLength )
	{
		$self->fh()->seek( $fileNameLength, IO::Seekable::SEEK_CUR )
			or return _ioError( "skipping local file name" );
	}

	if ( $extraFieldLength )
	{
		$self->fh()->read( $self->{'localExtraField'}, $extraFieldLength )
			or return _ioError( "reading local extra field" );
	}

	$self->{'dataOffset'} = $self->fh()->tell();

	return AZ_OK;
}

# Read from a local file header into myself. Returns AZ_OK if successful.
# Assumes that fh is positioned after signature.
# Note that crc32, compressedSize, and uncompressedSize will be 0 if
# GPBF_HAS_DATA_DESCRIPTOR_MASK is set in the bitFlag.

sub _readLocalFileHeader	# Archive::Zip::ZipFileMember
{
	my $self = shift;
	my $header;
	$self->fh()->read( $header, LOCAL_FILE_HEADER_LENGTH )
		or return _ioError( "reading local file header" );
	my $fileNameLength;
	my $crc32;
	my $compressedSize;
	my $uncompressedSize;
	my $extraFieldLength;
	(	$self->{'versionNeededToExtract'},
		$self->{'bitFlag'},
		$self->{'compressionMethod'},
		$self->{'lastModFileDateTime'},
		$crc32,
		$compressedSize,
		$uncompressedSize,
		$fileNameLength,
		$extraFieldLength ) = unpack( LOCAL_FILE_HEADER_FORMAT, $header );

	if ( $fileNameLength )
	{
		my $fileName;
		$self->fh()->read( $fileName, $fileNameLength )
			or return _ioError( "reading local file name" );
		$self->fileName( $fileName );
	}

	if ( $extraFieldLength )
	{
		$self->fh()->read( $self->{'localExtraField'}, $extraFieldLength )
			or return _ioError( "reading local extra field" );
	}

	$self->{'dataOffset'} = $self->fh()->tell();

	# Don't trash these fields from the CD if we already have them.
	if ( not $self->hasDataDescriptor() )
	{
		$self->{'crc32'} = $crc32;
		$self->{'compressedSize'} = $compressedSize;
		$self->{'uncompressedSize'} = $uncompressedSize;
	}

	# We ignore data descriptors (we don't read them,
	# and we compute elsewhere whether we need to write them ).
	# And, we have the necessary data from the CD header.
	# So mark this entry as not having a data descriptor.
	$self->hasDataDescriptor( 0 );

	return AZ_OK;
}


# Read a Central Directory header. Return AZ_OK on success.
# Assumes that fh is positioned right after the signature.

sub _readCentralDirectoryFileHeader	# Archive::Zip::ZipFileMember
{
	my $self = shift;
	my $fh = $self->fh();
	my $header = '';
	$fh->read( $header, CENTRAL_DIRECTORY_FILE_HEADER_LENGTH )
		or return _ioError( "reading central dir header" );
	my ( $fileNameLength, $extraFieldLength, $fileCommentLength );
	(
		$self->{'versionMadeBy'},
		$self->{'fileAttributeFormat'},
		$self->{'versionNeededToExtract'},
		$self->{'bitFlag'},
		$self->{'compressionMethod'},
		$self->{'lastModFileDateTime'},
		$self->{'crc32'},
		$self->{'compressedSize'},
		$self->{'uncompressedSize'},
		$fileNameLength,
		$extraFieldLength,
		$fileCommentLength,
		$self->{'diskNumberStart'},
		$self->{'internalFileAttributes'},
		$self->{'externalFileAttributes'},
		$self->{'localHeaderRelativeOffset'}
	 ) = unpack( CENTRAL_DIRECTORY_FILE_HEADER_FORMAT, $header );

	if ( $fileNameLength )
	{
		$fh->read( $self->{'fileName'}, $fileNameLength )
			or return _ioError( "reading central dir filename" );
	}
	if ( $extraFieldLength )
	{
		$fh->read( $self->{'cdExtraField'}, $extraFieldLength )
			or return _ioError( "reading central dir extra field" );
	}
	if ( $fileCommentLength )
	{
		$fh->read( $self->{'fileComment'}, $fileCommentLength )
			or return _ioError( "reading central dir file comment" );
	}

	$self->desiredCompressionMethod( $self->compressionMethod() );

	return AZ_OK;
}

sub rewindData	# Archive::Zip::ZipFileMember
{
	my $self = shift;

	my $status = $self->SUPER::rewindData( @_ );
	return $status if $status != AZ_OK;

	return AZ_IO_ERROR if ! $self->fh();

	$self->fh()->clearerr();

	# Seek to local file header.
	# The only reason that I'm doing this this way is that the extraField
	# length seems to be different between the CD header and the LF header.
	$self->fh()->seek( $self->localHeaderRelativeOffset() + SIGNATURE_LENGTH,
		IO::Seekable::SEEK_SET )
			or return _ioError( "seeking to local header" );

	# skip local file header
	$status = $self->_skipLocalFileHeader();
	return $status if $status != AZ_OK;

	# Seek to beginning of file data
	$self->fh()->seek( $self->dataOffset(), IO::Seekable::SEEK_SET )
		or return _ioError( "seeking to beginning of file data" );

	return AZ_OK;
}

# Return bytes read. Note that first parameter is a ref to a buffer.
# my $data;
# my ( $bytesRead, $status) = $self->readRawChunk( \$data, $chunkSize );
sub _readRawChunk	# Archive::Zip::ZipFileMember
{
	my ( $self, $dataRef, $chunkSize ) = @_;
	return ( 0, AZ_OK )
		if ( ! $chunkSize );
	my $bytesRead = $self->fh()->read( $$dataRef, $chunkSize )
		or return ( 0, _ioError( "reading data" ) );
	return ( $bytesRead, AZ_OK );
}

# ----------------------------------------------------------------------
# class Archive::Zip::StringMember ( concrete )
# A Zip member whose data lives in a string
# ----------------------------------------------------------------------

package Archive::Zip::StringMember;
use vars qw( @ISA );
@ISA = qw ( Archive::Zip::Member );

BEGIN { use Archive::Zip qw( :CONSTANTS :ERROR_CODES ) }

# Create a new string member. Default is COMPRESSION_STORED.
# Can take a ref to a string as well.
sub _newFromString	# Archive::Zip::StringMember
{
	my $class = shift;
	my $string = shift;
	my $name = shift;
	my $self = $class->new( @_ );
	$self->contents( $string );
	$self->fileName( $name ) if defined( $name );
	# Set the file date to now
	$self->setLastModFileDateTimeFromUnix( time() );
	$self->unixFileAttributes( $self->DEFAULT_FILE_PERMISSIONS );
	return $self;
}

sub _become	# Archive::Zip::StringMember
{
	my $self = shift;
	my $newClass = shift;
	return $self if ref( $self ) eq $newClass;
	delete( $self->{'contents'} );
	return $self->SUPER::_become( $newClass );
}

# Get or set my contents. Note that we do not call the superclass
# version of this, because it calls us.
sub contents    # Archive::Zip::StringMember
{
	my $self = shift;
	my $string = shift;
	if ( defined( $string ) )
	{
		$self->{'contents'} = ( ref( $string ) eq 'SCALAR' )
			? $$string
			: $string;
		$self->{'uncompressedSize'}
			= $self->{'compressedSize'}
			= length( $self->{'contents'} );
		$self->{'compressionMethod'} = COMPRESSION_STORED;
	}
	return $self->{'contents'};
}

# Return bytes read. Note that first parameter is a ref to a buffer.
# my $data;
# my ( $bytesRead, $status) = $self->readRawChunk( \$data, $chunkSize );
sub _readRawChunk	# Archive::Zip::StringMember
{
	my ( $self, $dataRef, $chunkSize ) = @_;
	$$dataRef = substr( $self->contents(), $self->_readOffset(), $chunkSize );
	return ( length( $$dataRef ), AZ_OK );
}

1;
__END__

=back

=head1 AUTHOR

Ned Konz, perl@bike-nomad.com

=head1 COPYRIGHT

Copyright (c) 2000 Ned Konz. All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

L<Compress::Zlib>

=cut

# vim: ts=4 sw=4 columns=80
