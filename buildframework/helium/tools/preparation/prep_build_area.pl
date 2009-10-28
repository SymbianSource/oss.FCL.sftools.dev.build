#!perl -w

#============================================================================ 
#Name        : prep_build_area.pl 
#Part of     : Helium 

#Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
#All rights reserved.
#This component and the accompanying materials are made available
#under the terms of the License "Eclipse Public License v1.0"
#which accompanies this distribution, and is available
#at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
#Initial Contributors:
#Nokia Corporation - initial contribution.
#
#Contributors:
#
#Description: 
#============================================================================

use strict;
use Getopt::Long;
use File::Path;
use File::Basename;
use File::Spec;
use File::Temp qw(tempfile);
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use FindBin;
use XML::Twig;
use FindBin;
use lib "$FindBin::Bin/../common/packages";
use Utils;


sub process_build_sources;


my $UNZIP = "unzip";


my $destdir = '';
my $zipdir = '';
my $config = '';
my $dryrun = 0;
my $verbose = $ENV{'VERBOSE'};

GetOptions( 'destdir=s'  => \$destdir,
            'zipdir=s'   => \$zipdir,
            'config=s'   => \$config,
            'dry-run|n'  => \$dryrun) or pod2usage( 2 );

my ( $dest_drive, undef, undef ) = File::Spec->splitpath( $destdir );
my $twig = new XML::Twig();
$twig->parsefile( $config );

# Get the 'prepSpec' XML root element
my $root = $twig->root();

# Get the list of generic excluded paths from the XML config file
my @excluded_paths;
my @exclude_elements = $root->get_xpath( "config/exclude" );
for my $exclude_element ( @exclude_elements )
{
    my $exclude_text = $exclude_element->att( 'name' );
    push( @excluded_paths, $exclude_text );
}

my @sources;
@sources = $root->get_xpath( "source" );

# Always run just a check of the inputs
my $validate_failed = 0;
my $validate_only = 1;
process_build_sources( $destdir, $zipdir, \@sources, $validate_only );

# Then run the actual operations if a parameter was not set to do a dry run only
if ( not $validate_failed )
{
    $validate_only = 0;
    
    process_build_sources( $destdir, $zipdir, \@sources, $validate_only );
    # Delete the unzip directory in case one was created
    print "Deleting the temp unzip directory: '$zipdir'\n";
    rmtree( $zipdir, 1 );
}
exit $validate_failed;



sub process_build_sources
{
    my ( $destdir, $zipdir, $sources, $validate_only ) = @_;
    for my $source ( @{$sources} )
    {
        process_source( $destdir, $zipdir, $source, $validate_only );
    }
}



# Process a single source element, which could define either a copy or an unzip
# operation.
sub process_source
{
    my ( $destdir, $zipdir, $source_element, $validate_only ) = @_;

    my $source_label = $source_element->att( 'label' );
    if ( $verbose )
    {
        print "Processing source with label: $source_label\n";
    }

    # Handle each of the copy or unzip operations for this source
    my @operations = $source_element->get_xpath( "copy" );
    my @unzip_operations = $source_element->get_xpath( "unzip" );
    my @unzipicds_operations = $source_element->get_xpath( "unzipicds" );
    my @nested_unzip_operations = $source_element->get_xpath( "nestedunzip" );
    push( @operations, @unzip_operations, @unzipicds_operations, @nested_unzip_operations );
    for my $operation ( @operations )
    {
        if ( is_valid( $operation ) )
        {
            # Construct the path for the zip to extract or the directory to copy
            my $source = undef;
            if ( $operation->gi() =~ /^(unzip|copy|nestedunzip)$/ )
            {
            	$source = File::Spec->canonpath( $source_element->att( 'basedir' ).'/'. $operation->att( 'name' ));
            	$source = replace_env_vars( $source );

            	if ( $verbose )
            	{
            	    print "Processing $source\n";
            	}

            	# Check if the source directory or zip exists, unless it contains globs
            	if ( ( not -e $source ) && ( $source !~ /\*/ ) )
            	{
            	    if ( $source !~ /^$dest_drive/i )
            	    {
            	        print("ERROR: Can't locate input source: \"$source\"\n");
            	        $validate_failed = 1;
            	        next;
            	    }
            	    else
            	    {
            	        if ( $verbose )
            	        {
            	            print( "INFO: Input not ready: \"$source\"\n");
            	        }
            	    }
            	}
		}

            if ( not $validate_only )
            {
                # Construct the destination directory, based on the provided default
                # root destination and any additional subdirectory defined in the operation
                my $dest = $destdir;
                my $dest_sub_dir = $operation->att( 'dest' );
                if ( $dest_sub_dir )
                {
                    $dest_sub_dir = replace_env_vars( $dest_sub_dir );

                    # If the destination is an absolute path, then ignore the
                    # default root destination.
                    if ( $dest_sub_dir =~ /:/ )
                    {
                        $dest = $dest_sub_dir;
                    }
                    # Otherwise just add the subdirectory to root destination
                    else
                    {
                        $dest .= $dest_sub_dir;
                    }
                }
                $dest = replace_env_vars( $dest );

                # See if operation is a copy or an unzip
                my $operation_type = $operation->gi();
                
                unless( -e $dest )
                {
						    	mkpath( [$dest],1,0755 );
						    }
                
                if ( $operation_type eq 'unzip' )
                {                	  
                    extract_source_zip( $source, $dest, $zipdir, $operation );
                }
                elsif ( $operation_type eq 'nestedunzip' )
                {                	                	
                	extract_source_nested( $source, $dest, $zipdir, $operation );
                }
                elsif ( $operation_type eq 'copy' )
                {
                    copy_source_files( $source, $dest, $operation );
                }
                elsif ( $operation_type eq 'unzipicds' )
                {
                	extract_source_icds( $source, $dest, $zipdir, $operation );
                }
            }
        }
    }
}

# Unzip icds
sub CompareICDs
{
	my $aid = 0;
	my $bid = 0;
	$aid = $1 if ($a =~ /ic([d|f]\d+.*)\.zip$/i);
	$bid = $1 if ($b =~ /ic([d|f]\d+.*)\.zip$/i);
	return lc($aid) cmp lc($bid);
}

#
# Syntax:
#
# + source
#   + unzipicds
#      location+
#      include*
#
sub extract_source_icds
{
    my ( $sourcezip, $dest, $zipdir, $zip_element ) = @_;
    my @location_elements = $zip_element->get_xpath( 'location' );

    my @listoffiles;
    foreach my $location_element ( @location_elements )
		{
		    my $dir = File::Spec->canonpath( $location_element->att('name') );
			print "Scanning $dir\n";
			unless ( -d "$dir" )
			{
				print ("WARNING: $dir doesn't not exits. Skipping\n");
				next;
			}

			opendir DIR, $dir;
			my @l = grep( { # Check the file ends in .zip
			                /\.zip$/ &&
			                # Check file is a plain file (not a directory)
			                -f "$dir/$_" &&
			                # Modify the file path to the full canonical one
			                ($_=File::Spec->canonpath("$dir/$_")) } readdir(DIR) );

            # See if any of the files are in the list of excluded files
            my @exclude_elements = $location_element->get_xpath( 'exclude' );
            if ( scalar( @exclude_elements ) > 0 )
            {
                my @excluded_files = map( $_->att('name'), @exclude_elements );
                my $files_total = scalar( @l );
                my $i = 0;
                while( $i < $files_total )
                {
                    my $file = $l[$i];
                    foreach my $excluded_file ( @excluded_files )
                    {
                        if ( $file =~ /$excluded_file/ )
                        {
                            print( "Removing excluded file '$file' from ICD/ICF list\n" );
                            splice( @l, $i, 1 );
                            $files_total--;
                        }
                    }
                    $i++;
                }
            }
			@listoffiles = (@listoffiles, @l);

			closedir DIR;
		}

    my @include_elements = $zip_element->get_xpath( 'include' );
    my $includes = '';
		for my $include_element ( @include_elements )
		{
			if ( is_valid( $include_element ) )
			{
				my $include_text = $include_element->att( 'name' );
				$includes .= "$include_text ";
			}
		}

	foreach my $icd (sort CompareICDs @listoffiles)
	{
		if ( -e "$icd" )
		{
			print "Unzipping $icd\n";
	    log_exec(  "$UNZIP -o -C $icd"
           . " $includes"
           . " -x " . join(" ", map({"*/" . $_} @excluded_paths ))
           . " -d $dest");
		}
	}
}


# Copy (optionally) zip files and extract them
sub extract_source_zip
{
    my ( $sourcezip, $dest, $zipdir, $zip_element ) = @_;

    if ( $zipdir )
    {
        if ( not -d $zipdir )
        {
            print "Creating dir for caching zip files: $zipdir\n";
            eval { mkpath( $zipdir ) };
            if ( $@ )
            {
                print "Couldn't create $zipdir: $@";
            }
        }

        my $destzip = File::Spec->canonpath($zipdir.'/'.basename( $sourcezip ));

        my ( $lcl_size, $rmt_size ) = ( 0, 0 );
        if ( -f $destzip )
        {
            $lcl_size = -s $destzip;
        }
        if ( -f $sourcezip )
        {
            $rmt_size = -s $sourcezip;
        }
        if ( $rmt_size != $lcl_size )
        {
            my $zipdir_to_copy = $zipdir;
            $zipdir_to_copy =~ s/\//\\/g;
            log_exec( "xcopy $sourcezip $zipdir_to_copy /H /R /Y /Q" );
            die( "xcopy failed with exit code " . ($? >> 8)) if ($? >> 8);
        }

        # Set source zip to the cached copy on the local drive
        $sourcezip = $destzip;
    }

    # See if there are any include patterns
    my $includes = '';
    my @include_elements = $zip_element->get_xpath( 'include' );
    my @source_include_elements = $zip_element->get_xpath( '../include' );
    push( @include_elements, @source_include_elements );
    if ( scalar( @include_elements ) > 0 )
    {
        for my $include_element ( @include_elements )
        {
            if ( is_valid( $include_element ) )
            {
                my $include_text = $include_element->att( 'name' );
                $includes .= "$include_text ";
            }
        }
    }

    log_exec(  "$UNZIP -o -C $sourcezip"
               . " $includes"
               . " -x " . join(" ", map({"*/" . $_} @excluded_paths ))
               . " -d $dest");
    rmtree( $zipdir, 1 );   
}

# Find all zip files and unzip those twice
sub extract_source_nested
{
    my ( $sourcezip, $dest, $zipdir, $zip_element ) = @_;
    my $nestedZipDir = $zipdir . '_nested';
    if ( $nestedZipDir )
    {
        if ( not -d $nestedZipDir )
        {
            print "Creating dir for caching zip files: $nestedZipDir\n";
            eval { mkpath( $nestedZipDir ) };
            if ( $@ )
            {
                print "Couldn't create $nestedZipDir: $@";
            }
        }

        my $destzip = File::Spec->canonpath($nestedZipDir.'/'.basename( $sourcezip ));

        my ( $lcl_size, $rmt_size ) = ( 0, 0 );
        if ( -f $destzip )
        {
            $lcl_size = -s $destzip;
        }
        if ( -f $sourcezip )
        {
            $rmt_size = -s $sourcezip;
        }
        if ( $rmt_size != $lcl_size )
        {
            my $zipdir_to_copy = $nestedZipDir;
            $zipdir_to_copy =~ s/\//\\/g;     
            log_exec(  "$UNZIP -o -C $sourcezip"                              
               . " -d $zipdir_to_copy");            
        }

        # Set source zip to the cached copy on the local drive
        $sourcezip = $nestedZipDir . "/" . "*.zip";
    }   

    log_exec(  "$UNZIP -o -C $sourcezip"
               . " -d $dest");
    rmtree( $nestedZipDir, 1 );    
}



# Copy the release files to a local directory
sub copy_source_files
{
    my ( $source, $dest, $copy_element ) = @_;

    # strip trailing slash - xcopy doesn't like it on source directories
    $source =~ s/[\\\/]$//;

    # See if the source input is a single file
    if ( -f $source )
    {
        # See if the file should be excluded
        if ( is_excluded( $source ) )
        {
            print("Rule \"$source\" => \"$dest\" excluded");
            return;
        }

        # See if a tofile attribute is defined to specify a destination file.
        # Here the $dest parameter is assumed to be just the base directory, as
        # an operation should not have both dest and tofile attributes.
        my $tofile = $copy_element->att( 'tofile' );
        $tofile = replace_env_vars( $tofile );
        if ( $tofile )
        {
            # If the destination is an absolute path, then ignore the
            # default root destination.
            if ( $tofile =~ /:/ )
            {
                $dest = $tofile;
            }
            # Otherwise just add the subdirectory to root destination
            else
            {
                $dest .= $tofile;
            }
        }
        else
        {
            # Create the destination file name, based on path and source filename
            my ( $vol, $path, $file ) = File::Spec->splitpath( $source );
            $dest = File::Spec->catpath( '', $dest, $file );
        }

        # See if the directory path needs to be created
        my ( $vol, $path, undef ) = File::Spec->splitpath( $dest );
        my $destpath = File::Spec->catpath( $vol, $path, '' );
        # Remove any trailing slashes
        $destpath =~ s/[\\\/]$//;
        if ( not ( -e $destpath ) )
        {
            print "Creating dir for copying source files: $destpath\n";
            eval { mkpath( $destpath ) };
            if ( $@ )
            {
                print "Couldn't create $destpath: $@";
            }
        }

        # Execute the copy
        # Convert forward to backslashes
        $dest =~ s/\//\\/g;
        log_exec("copy $source $dest /Y");
    }
    # See if the input is a directory
    elsif ( -d $source )
    {
        $dest =~ s/\//\\/g;
        my $tempfile = write_exclude_file( $copy_element );
        log_exec(
                 "xcopy $source $dest /S /E /I /H /R /Y /F /EXCLUDE:$tempfile");
        log_warn("xcopy did not find any files to copy") if ($? >> 8) == 1;
        log_die("xcopy failed with exit code " . ($? >> 8)) if ($? >> 8) > 1;
        unlink( $tempfile );
    }
}



sub is_valid
{
    my ( $element ) = @_;
    my $valid = 1;

    # See if operation is conditional on a property
    my $if_conditional = $element->att( 'if' );
    my $unless_conditional = $element->att( 'unless' );
    if ( $if_conditional )
    {    	
        # The operation is not processed if a conditional is present but
        # it is not true.
        if ( $if_conditional !~ /^true|yes|1$/i )
        {
            $valid = 0;
        }
    }
    elsif ( $unless_conditional )
    {
        # The operation is not processed if a conditional is present but
        # it is considered true.
    	if ( $unless_conditional =~ /^true|yes|1$/i )
        {
            $valid = 0;
        }
    }
    return $valid;
}



# Return true if the given file is excluded
sub is_excluded
{
    my ( $file ) = @_;
    my $exclude = 0;
    $file =~ s/\\/\//g;
    for my $exclude_file ( @excluded_paths )
    {
        if ( $file =~ /$exclude_file/ )
        {
            $exclude = 1;
            last;
        }
    }
    return $exclude;
}



# write an xcopy exclude file with excluded source paths
sub write_exclude_file
{
    my ( $copy_element ) = @_;

    # Create a tempfile containing files that are ignored
    my ( $handle, $tempfile ) = tempfile();

    my @exclude_elements = $copy_element->get_xpath( 'exclude' );
    for my $exclude ( @exclude_elements )
    {
        if ( is_valid( $exclude ) )
        {
            my $exclude_path = $exclude->att( 'name' );
            # Convert forward slashes to backward slashes for xcopy
            $exclude_path =~ s/\//\\/g;
            print( $handle "$exclude_path\n" );
        }
    }

    print( $handle join( "\n", @excluded_paths ) );
    close( $handle );
    return $tempfile;
}



sub log_exec
{
    my $cmd = shift;
    print "sys: \"$cmd\"\n";
    my @output;
    if ( not $dryrun )
    {
        @output = `$cmd 2>&1`;
    }
    print @output;
    $? = 0;
}



__END__


=head1 NAME

prep_build_area.pl - Populates a build area from input source directories and
zips.

=head1 SYNOPSIS

prep_build_area.pl -config=<XML config file> [-zipdir=\unzip] [-dry-run=<yes|no>]

=head1 OPTIONS

=over 8

=item B<-config>

The path to a XML configuration file that defines the source inputs to
the build.

=item B<-zipdir>

A directory that can be used for copying zips into to cache locally before
unzipping.

=item B<-dry-run>

If defined, this will cause just the inputs to be checked but no copying
or unzipping will take place.

=back

=head1 DESCRIPTION

This script prepares a build drive by copying directories and unzipping files
into the drive, based on an XML configuration file that defines a number
of source inputs. See the XML schema documentation for more details.

=cut