# Copyright (c) 2000-2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
# 
# Initial Contributors:
# Nokia Corporation - initial contribution.
# 
# Contributors:
# 
# Description:
# 
#

package Symbian::CBR::Component::Manifest;
use base qw(Exporter);
use EnvDb;
use strict;
use IniData;
use MrpData;
use XML::Simple;
use POSIX qw(strftime);
use Utils;
use Carp;
use File::Spec;
use File::Basename;
use CatData;
use IniData;

eval { push @INC, Utils::PrependEpocRoot('\epoc32\tools') };

#
#Constants
#

use constant CONTENTTYPE_SOURCE => 'source';
use constant CONTENTTYPE_BINARY => 'binary';
use constant CONTENTTYPE_EXPORT => 'export';
use constant CONTENT_TYPE       => 'content-type';
use constant IPR_CATEGORY       => 'ipr-category';
use constant BINARY_PLATFORM    => 'platform';
use constant EVALID_MD5         => 'evalid-checksum';
use constant MODIFIED_TIME      => 'modified-timestamp';
use constant MANIFEST_FILE      => 'manifest.xml';
use constant STATUS_CLEAN       => 0;
use constant STATUS_DIRTY       => 1;
use constant STATUS_DIRTY_SOURCE=> 4;
our @EXPORT = qw(MANIFEST_FILE CONTENT_TYPE IPR_CATEGORY);

#
#Public Interfaces
#

sub new {
    my $class = shift;
    my $file  = shift;
    my $verbose = shift;

    croak "Error: $file does not exist\n" if !-e $file;

    my $self = bless {}, $class;
    $self->{verbose} = $verbose;
    if ( $file =~ /.mrp$/i ) { #check if file is a mrp file
        $self->PopulateDataFromMRP($file);
    }
    elsif ( basename($file) =~ /.xml$/i ) { #check if file is a manifest file
        $self->LoadManifestFile($file);
    }
    else { #cannot proceed if file is neither MRP nor manifest file
        croak "Error: File is neither an MRP file nor a manifest file.\n";
    }
    return $self;
}

sub Save {
    my $self             = shift;
    my $manifestLocation = shift;
    my $myManifestFileBasename = shift;
    my $manifestFile = undef;
    
    if (defined $myManifestFileBasename) {
        print "-----> Use user defined manifest file basename: $myManifestFileBasename \n";
        $manifestFile = File::Spec->catfile( $manifestLocation, $myManifestFileBasename);
    }
    else {
        print "---- > Use default manifest file basename\n";
        $manifestFile = File::Spec->catfile($manifestLocation, MANIFEST_FILE);
    }

    #Die, if the directory path doesn't exist
    croak "Error: Directory path does not exist : $manifestLocation\n" if !-d $manifestLocation;

    #Create an EnvDb object to retrieve component versions
    my $iniData = IniData->New();
    my $envDb = EnvDb->Open($iniData, 0);

    #Hash structure to be provided as input for XML::Simple->XMLout()
    my $component = {
        name       => $self->{componentName},
        meta    => {
            'cbr-version'    => { 'content' => $self->{cbrVersion} },
            'created-time'   => { 'content' => strftime( '%Y-%m-%dT%H:%M:%S', localtime()) },
            'mrp-path'       => { 'content' => $self->{mrpFilePath} },
        },
        manifest => { files => [] }
    };

    if (defined $envDb->Version($self->{componentName})) {
        $component->{version} = $envDb->Version($self->{componentName});
    }
    
    if (defined $envDb->InternalVersion($self->{componentName})) {
        $component->{'internal-version'} = $envDb->InternalVersion($self->{componentName});
    }

    if (defined $self->{evalidVersion}) {
        $component->{meta}{'evalid-version'}{content} = $self->{evalidVersion};
    }

    #Construct the file group structure hierarchy
    my $groups = {};

    foreach my $path (keys %{$self->{files}}) {
        # make file representation
        my $file = { path => $path };
    
        for $_ (qw(evalid-checksum modified-timestamp)) {
            next if !defined $self->{files}{$path}{$_}; # skip undef
            $file->{$_} = $self->{files}{$path}{$_};
        }
    
        # pick file group
    
        my $groupid = join(',', grep defined, (
            $self->{files}{$path}{'content-type'},
            $self->{files}{$path}{'ipr-category'},
            $self->{files}{$path}{'platform'}));
    
        # make new group if it doesn't exist
    
        if (!defined $groups->{$groupid}) {
            $groups->{$groupid} = { file => [] }; # make ref
            for $_ (qw(content-type ipr-category platform)) {
                next if !defined $self->{files}{$path}{$_}; # skip undef
                $groups->{$groupid}{$_} = $self->{files}{$path}{$_};
            }
            push @{$component->{manifest}{files}}, $groups->{$groupid};
        }
    
        # add file to correct group
    
        push @{$groups->{$groupid}{file}}, $file;
    }

    #Use the hash structure for calling the XMLout() to write the manifest file
    eval {XMLout(
        $component,
        xmldecl     => '<?xml version="1.0" encoding="ISO-8859-1"?>',
        rootname    => 'component',
        outputfile  => $manifestFile )};

    croak "Error: Can't write manifest file: $@\n" if $@;

    return $manifestFile;
}

sub Compare {
    my $self           = shift;
    my $manifestObj    = shift;
    my $validatesource = shift;
    my $keepGoing      = shift;
    my $callback       = shift;
    
    my $status = STATUS_CLEAN;

    #Check for similarity of component names
    croak "Error: Component names does not match between manifest versions\n" if lc($self->{componentName}) ne lc($manifestObj->{componentName});

    #Check for presence of evalid md5 in both versions of the component
    croak "Error: MD5 info incomplete\n" if !defined $self->{evalidVersion} or !defined $manifestObj->{evalidVersion};

    #Check for similarity of evalid versions used in both versions of components
    croak "Error: Incompatible evalid versions\n" if $self->{evalidVersion} ne $manifestObj->{evalidVersion};
   
    #Get list of files in MRP and manifest file
    #do not include source if validate source not specified
    my $filesFromThisComponent   = $self->GetFiles(!$validatesource);
    my $filesFromBaselineComponent = $manifestObj->GetFiles(!$validatesource);
    if ( @$filesFromThisComponent != @$filesFromBaselineComponent ) { #Check if counts of files in both versions are same
        print "File counts differ\n";
        $status = STATUS_DIRTY;
    }
    %{$self->{compareFiles}} = (); # Hash to store all zip files, files for zipfile and their status.
    my @noChecksumFiles;

    foreach my $file ( @{$filesFromThisComponent} ) { #Iterate through each files listed in mrp
        my $zipname = $self->GetZipName($file);
        my $fileContentType = $self->GetFileInfo($file, CONTENT_TYPE);

        next if !$validatesource and $fileContentType eq 'source'; #Skip comparison source files if $validatesource is not set
        if ( !$manifestObj->FileExists($file) ) { #Check if a corresponding entry for the file exist in manifest file
            print "File added in the new environment : $file\n";
            $self->{compareFiles}{$zipname}{files}{$file} = "added";
            if ( $fileContentType eq 'source' && $status != STATUS_DIRTY) {
                $status = STATUS_DIRTY_SOURCE;
            }
            else {
                $status = STATUS_DIRTY;
                return $status unless $keepGoing; #If $keepGoing is set, continue the iteration. Else, stop the comparison and return back to the caller
            }
            next;
        }

        #Check evalid md5 checksums of all files
        if (not defined $manifestObj->GetFileInfo( $file, EVALID_MD5 ) or not defined $self->GetFileInfo($file, EVALID_MD5)) {
            push @noChecksumFiles,$file;
        }
        elsif ( $manifestObj->GetFileInfo( $file, EVALID_MD5 ) ne $self->GetFileInfo($file, EVALID_MD5) ) { #comparison of Evalid checksum of both verisons
            print "The evalid checksum does not match for the file : $file\n";  
            $self->{compareFiles}{$zipname}{files}{$file} = "modified";
            if ( $fileContentType eq 'source' && $status != STATUS_DIRTY) {
                $status = STATUS_DIRTY_SOURCE;
            }
            else {
                $status = STATUS_DIRTY;
                return $status unless $keepGoing; #If $keepGoing is set, continue the iteration. Else, stop the comparison and return back to the caller
            }
        }

        #Check for mismatches in ipr-categories for source and export files
        if ($validatesource && ($fileContentType eq 'source' or $fileContentType eq 'export')) {
            if ($self->GetFileInfo($file, IPR_CATEGORY) ne $manifestObj->GetFileInfo($file, IPR_CATEGORY)) {
                print "Content-type mismatch between version : $file\n";
                
                $self->{compareFiles}{$zipname}{files}{$file} = "added";
                
                my $zipnameOriginal = $manifestObj->GetZipName($file);
                $self->{compareFiles}{$zipnameOriginal}{files}{$file} = "deleted";
                
                if ( $fileContentType eq 'source' && $status != STATUS_DIRTY) {
                    $status = STATUS_DIRTY_SOURCE;
                }
                else {
                    $status = STATUS_DIRTY;
                    return $status unless $keepGoing; #If $keepGoing is set, continue the iteration. Else, stop the comparison and return back to the caller            
                }
            }
        }
        
        #Check for moving some files from one zip file to another
        my $ref_zipname = $manifestObj->GetZipName($file);
        if ($zipname ne $ref_zipname) {
        	   #The file is moved from $ref_zipname to $zipname
            $self->{compareFiles}{$zipname}{files}{$file} = "added";
            if ($manifestObj->FileExists($file))  {
                $self->{compareFiles}{$ref_zipname}{files}{$file} = "deleted";
            }
        }
    }
    
    if (scalar @noChecksumFiles > 0) {
        if (defined $callback) {
            unless (&$callback(\@noChecksumFiles,$self,$keepGoing)) {
                $status = STATUS_DIRTY if ($status  == STATUS_CLEAN);
            }
        }
        
        foreach my $file (@noChecksumFiles) {
            my $zipname = $self->GetZipName($file);
            $self->{compareFiles}{$zipname}{files}{$file} = "modified"; #set to modified as don't have a method to compare no-checksum files
        }
    }
    
    foreach my $file ( @{$filesFromBaselineComponent } ) { 
        my $zipname = $manifestObj->GetZipName($file);
        if ( !$self->FileExists($file) ) {
            $self->{compareFiles}{$zipname}{files}{$file} = "deleted";
        }
        else {
            #Check for moving some files from one zip file to another
            my $ref_zipname = $self->GetZipName($file);
            if ($zipname ne $ref_zipname) {
                #The file is moved from $zipname to $ref_zipname
                $self->{compareFiles}{$zipname}{files}{$file} = "deleted";
                $self->{compareFiles}{$ref_zipname}{files}{$file} = "added";
           }
        }
    }
   
    return $status;
}

sub GetDiffZipFiles {
  my $self = shift;
  return $self->{compareFiles};
}

sub GetDiffFilesForZip {
  my $self = shift;
  my $zipfile = shift;
  return $self->{compareFiles}{$zipfile}{files};
}

sub GetFileStatus {
  my $self = shift;
  my $zipfile = shift;
  my $file = shift;
  return $self->{compareFiles}{$zipfile}{files}{$file};
}


#
#Private Methods
#

sub PopulateDataFromMRP {
    my $self    = shift;
    my $mrpFile = shift;

    #Check if EvalidCompare is installed
    if (eval { require EvalidCompare }) {
        $self->{evalidInstalled} = 1;
    } else {
        print "Remark: Evalid is not available ($@)\n";
    }

    #Create a mrpData object to retrieve files list that define the component
    my $iniData = IniData->New();
    
    #need to remove SRCROOT from MRP file
    $mrpFile = Utils::RemoveSourceRoot($mrpFile);
    
    my $mrpData = MrpData->New( $mrpFile, undef, undef, $iniData, 0, 0 );

    #Set the evalid version only if EValidCompare is installed
    if ( $self->{evalidInstalled} ) {
        $self->{evalidVersion}      = $EvalidCompare::VERSION;
    }
    #Set rest of meta data information
    $self->{cbrVersion}         = Utils::ToolsVersion();
    $self->{componentName}      = $mrpData->Component();
    $self->{mrpFilePath}        = $mrpData->MrpName();
    if ( Utils::WithinSourceRoot( $self->{mrpFilePath} ) ) {
        $self->{mrpFilePath} = Utils::RemoveSourceRoot( $self->{mrpFilePath} );
    }

    #Iterate through list of files list returned by mrpData and calculate the manifest informations
    #Make calls to SetFileInfo and save the manifest informations of the file to a common file hash
    foreach my $sourcecategory ( @{ $mrpData->SourceCategories() } ) {
        foreach my $file ( @{ $mrpData->Source( $sourcecategory ) }) {
            my $absFilePath = Utils::RelativeToAbsolutePath( $file, $mrpData->{iniData}, SOURCE_RELATIVE );
            
            # Reverse any source mappings as we don't want them in the manifest...
            $file = $iniData->PerformReverseMapOnFileName($file);
            
            # We also want to remove the SRCROOT from the file name
            if (Utils::WithinSourceRoot($file)){
                $file = Utils::RemoveSourceRoot($file);
            }
            if (-f $absFilePath) {
                $self->SetFileInfo( $file, CONTENT_TYPE, CONTENTTYPE_SOURCE );
                $self->SetFileInfo( $file, IPR_CATEGORY, $sourcecategory );
                $self->SetFileInfo( $file, MODIFIED_TIME, Utils::FileModifiedTime( $absFilePath ) );
                if ($self->{evalidInstalled}) {
                    $self->GenerateEvalidSignature($file, $absFilePath);
                }
            }
        }
    }    

    #List of binary files, their manifest calculations and saving to the file hash
    foreach my $binarycategory ( @{ $mrpData->BinaryCategories() } ) {
        foreach my $file ( @{ $mrpData->Binaries($binarycategory) } ) {
            my $absFilePath = Utils::RelativeToAbsolutePath( $file, $mrpData->{iniData}, EPOC_RELATIVE );
            if (-f $absFilePath) {
                $self->SetFileInfo( $file, CONTENT_TYPE, CONTENTTYPE_BINARY );
                if ( $binarycategory ne 'unclassified') {
                    $self->SetFileInfo( $file, BINARY_PLATFORM, $binarycategory );
                }
                $self->SetFileInfo( $file, MODIFIED_TIME, Utils::FileModifiedTime( $absFilePath ) );
                if ($self->{evalidInstalled}) {
                    $self->GenerateEvalidSignature($file, $absFilePath);
                }
            }
        }
    }

    #List of export files, their manifest calculations and saving to the file hash
    foreach my $exportcategory ( @{ $mrpData->ExportCategories() } ) {
        foreach my $file ( @{ $mrpData->Exports($exportcategory) } ) {
            my $absFilePath = Utils::RelativeToAbsolutePath( $file, $mrpData->{iniData}, EPOC_RELATIVE );
            if (-f $absFilePath) {
                $self->SetFileInfo( $file, CONTENT_TYPE, CONTENTTYPE_EXPORT );
                $self->SetFileInfo( $file, IPR_CATEGORY, $exportcategory );
                $self->SetFileInfo( $file, MODIFIED_TIME, Utils::FileModifiedTime( $absFilePath ) );
                if ($self->{evalidInstalled}) {
                    $self->GenerateEvalidSignature($file, $absFilePath);
                }
            }
        }
    }
}

sub LoadManifestFile {
    my $self         = shift;
    my $manifestFile = shift;

    my $iniData = IniData->New();

    #Generate the hash structure from manifest file
    my $component   = eval{XMLin(
                    $manifestFile,
                    forcearray => [ qw(files file) ])};

    croak "Error: Can't read manifest file '$manifestFile': $@\n" if $@;

    #Extract meta data informations from the generated structure
    $self->{componentName}      = $component->{name};
    $self->{evalidVersion}      = $component->{meta}{'evalid-version'}{content};
    $self->{cbrVersion}         = $component->{meta}{'cbr-version'}{content};
    $self->{mrpFilePath}        = $component->{meta}{'mrp-path'}{content};
    $self->{createdTimeString}  = $component->{meta}{'created-time'}{content};

    #Extract the manifest information of files from the generated structure
    foreach my $category ( @{ $component->{manifest}{files} } ) {
        foreach my $file ( @{ $category->{file} } ) {
            
            # DEF107988	Source mapping breaks manifest
            # Manifest files created with CBR Tools < 2.82.1003 may contain source
            # mapping information, which needs to be removed if present
            my $fileName = $iniData->PerformReverseMapOnFileName($file->{path});
            
            # We also want to remove the SRCROOT from the file name
            if (Utils::WithinSourceRoot($fileName)){
                $fileName = Utils::RemoveSourceRoot($fileName);
            }elsif (Utils::SourceRoot() ne "\\"){
                $fileName =~ s!^[\\\/]!!;
            }
            
            $self->{files}{$fileName}{'content-type'} = $category->{'content-type'};
            $self->{files}{$fileName}{'modified-timestamp'} = $file->{'modified-timestamp'};
            $self->{files}{$fileName}{'ipr-category'} = $category->{'ipr-category'};
            $self->{files}{$fileName}{'platform'} = $category->{'platform'};
            $self->{files}{$fileName}{'evalid-checksum'} = $file->{'evalid-checksum'};
        }
    }
}

sub RefreshMetaData {
    my $self = shift;
    my $comp = shift;
    my $ver  = shift;

    if (eval { require EvalidCompare }) {
        $self->{evalidInstalled} = 1;
    } else {
        print "Remark: Evalid is not available ($@)\n";
    }

    my $iniData = IniData->New();
    my %catdata;
    my %categories;
    
    foreach my $file (keys %{$self->{files}}) {
        if ($self->{files}->{$file}->{'content-type'} =~ m/export/i && !$categories{$self->{files}->{$file}->{'ipr-category'}}) {        
        my $tempcatdata = CatData->Open($iniData, $comp, $ver, $self->{files}->{$file}->{'ipr-category'});        
        %catdata = (%catdata, %{$tempcatdata->{data}->{exportinfo}});        
        $categories{$self->{files}->{$file}->{'ipr-category'}} = 1;
        }
    }

    $self->{createdTimeString} = strftime( '%Y-%m-%dT%H:%M:%S', localtime());
    $self->{cbrVersion} = Utils::ToolsVersion();

    foreach my $file (keys  %{$self->{files}}) {
        my $type = $self->{files}->{$file}->{'content-type'};
        my $absFilePath;

        if ($type eq CONTENTTYPE_EXPORT or $type eq CONTENTTYPE_BINARY) {
            $absFilePath = Utils::RelativeToAbsolutePath($file, $iniData, EPOC_RELATIVE);
        } else {
            $absFilePath = Utils::RelativeToAbsolutePath($file, $iniData, SOURCE_RELATIVE);
        }
        
        if (!-e $absFilePath) {
            delete $self->{files}->{$file};
            next;
        }
        
        $self->SetFileInfo($file, MODIFIED_TIME, Utils::FileModifiedTime($absFilePath));
        $self->GenerateEvalidSignature($file, $absFilePath) if ($self->{evalidInstalled});
        
        my $policy;
        
        if ($self->{files}->{$file}->{'content-type'} =~ /source/i) {
            my ($category) = Utils::ClassifyPath($iniData, $absFilePath, 0, 0, $comp);        
            $self->SetFileInfo($file, IPR_CATEGORY, $category);
        } elsif ($self->{files}->{$file}->{'content-type'} =~ /export/i) {
            my $sourcefile = Utils::RelativeToAbsolutePath($catdata{$file}, $iniData, SOURCE_RELATIVE);
            my ($category) = Utils::ClassifyPath($iniData, $sourcefile, 0, 0, $comp);     
            $self->SetFileInfo($file, IPR_CATEGORY, $category);
        }
    }
}

sub SetFileInfo {
    my $self       = shift;
    my $file       = shift;
    my $infoType   = shift;
    my $valueToSet = shift;
    $self->{files}{$file}{$infoType} = $valueToSet;
}

sub UnsetFileInfo {
    my $self       = shift;
    my $file       = shift;
    my $infoType   = shift;
    delete $self->{files}{$file}{$infoType} if exists $self->{files}{$file}{$infoType};
}

sub GetFiles {
    my $self = shift;
    my $excludesource = shift;
    
    if (!$excludesource) {
        my @fileList = keys %{$self->{files}};
        return \@fileList;
    }
    
    my @fileList = grep (($self->GetFileInfo($_, CONTENT_TYPE) ne 'source'), keys %{$self->{files}});
    return \@fileList;
}

sub GetFileInfo {
    my $self     = shift;
    my $file     = shift;
    my $infoType = shift;
    my $fileInfo = $self->{files}{$file}{$infoType};
    unless (defined $fileInfo) {
    	  $file = lc $file;
    	  $fileInfo = $self->{files}{$file}{$infoType};
    }
    return $fileInfo;
}

sub FileExists {
  my $self = shift;
  my $file = shift;
  my $isExists = exists $self->{files}{$file};
  if (!$isExists) {
    foreach my $ff (keys %{$self->{files}}) {
      return 1 if(lc($ff) eq lc($file));
    }
  }
  return $isExists;
}

sub GenerateEvalidSignature {
    my $self = shift;
    my $file = shift;
    my $absFilePath = shift;
    
    my $error=0;
    # Reroute STDOUT via our error handler
    tie *STDOUT, 'Symbian::CBR::Component::Manifest::EvalidErrorHandler', \$error;
    my ($md5Checksum, $type) = EvalidCompare::GenerateSignature($absFilePath);
    untie *STDOUT;
    
    if ($error == 0) {
        $self->SetFileInfo($file, EVALID_MD5, $md5Checksum);
        return 1;
    } else {
        print "Warning: Unable to generate checksum for file $file\n" if $error == 2;
        $self->UnsetFileInfo($file, EVALID_MD5);
        return 0;
    }
}
sub GetZipName {
  my $self = shift;
  my $file = shift;
  my $fileContentType = $self->GetFileInfo($file, CONTENT_TYPE);
  my $zipname;
  
  $fileContentType =~ s/export/exports/i;

  if ($fileContentType eq 'binary') {
    my $platform = $self->GetFileInfo($file, 'platform');
    if (defined $platform) {
      $zipname = "binaries_".$platform.".zip";
    }
    else {
      $zipname = "binaries".".zip";
    }
  }
  else {
    my $cat = $self->GetFileInfo($file, 'ipr-category');
    $zipname = $fileContentType.$cat.".zip";
  }
  
  return $zipname;
}

package Symbian::CBR::Component::Manifest::EvalidErrorHandler;

sub TIEHANDLE {
    my $self = {};
    bless $self, shift;
    my $errorflag = shift;
    $self->{errorflag} = $errorflag;
    return $self;
}

sub PRINT {
    my $self = shift;
    my $message = shift;
    my $errorflag = $self->{errorflag};

    # Untie STDOUT
    my $handle = tied *STDOUT;
    untie *STDOUT;

    # Check for evalidcompare dependency failures
    if (
      $message =~ /^Error: (.*) failed \(\d+\) on file .* - not retrying as raw binary/ or
      $message =~ /^Error: (.*) failed again \(\d+\) on .* - reporting failure/
    ) {
        # Failure: checksum will be corrupt

        if ($1 =~ /dumpbin/i) {
            # Suppress known error
            $$errorflag = 1;
        } else {
            $message =~ s/^Error:\s*//;
            print "Warning: Tool dependency 'evalidcompare' failed with message: ".$message;
            $$errorflag = 2;
        }
    } else {
        # Output wasn't an error message
        print $message;
    }

    # Re-tie the handle
    tie *STDOUT, ref($handle), $errorflag;
}

1;

__END__

=head1 NAME

Manifest.pm - A module that helps the construction of manifest objects for inclusion during component release process and for validation of component release

=head1 DESCRIPTION

The module is used for constructing manifest objects for individual components from either a mrp file or a manifest file. The objects obtained from either processes include informations on the environment and the files that define the component.

The file properties include useful informations that can be used for validating components during the release processes like the ipr-category of sources and export files, content-type, platform in which binary files are built, evalid md5 checksum and modified timestamp.

=head1 INTERFACE

=head2 Object Management

=head3 new

Expects a full file path of a mrp file or a manifest file path. A valid manifest xml file should be available in the path. Responsible for constructing the manifest object with a list of files that define the component along with useful manifest informations and metadata information regarding the environment

=head2 Data Management

=head3 Compare

Expects a manifest object reference as parameter. Performs a comparison of the manifest informations available in the two manifest objects returns a status of the comparison.

The comparison is mainly done between the evalid md5 checksums of the both components along with basic environment check on similarity of evalid version being used for generating the checksum on the files.

The comparison results in a status being returned as CLEAN (integer equivalent of 0), if the manifest object informations are the same between versions and returns DIRTY (integer equivalent of 1), if the versions differ.

=head3 Save

Expects a directory path as parameter. The path should be a valid existing directory path and is used by the object to save the manifest informations of the component in the form of a manifest.xml file.

The manifest file will not be saved if the path mentioned for the function does not exist.

The manifest file contains manifest information of all the files that define the component and are segregated based on filegroups. The filegroups are listed based on basic attributes of the files like the ipr-category, content-type and binary-platform.
