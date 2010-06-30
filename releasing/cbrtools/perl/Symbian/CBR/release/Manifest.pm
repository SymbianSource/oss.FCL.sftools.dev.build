# Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Description:
# Symbian::CBR::Release::Manifest.pm
#

package Symbian::CBR::Release::Manifest;

use File::Basename;
use File::Spec;
use File::Path;
use RelData;
use XML::Simple;
use Carp;
use POSIX qw(strftime);


#
#Constants
#

use constant MD5                => 'md5';
use constant SIZE               => 'size';
use constant MODIFIED_TIME      => 'modified-timestamp';
use constant VERSION            =>   '1.0.0';


#
#Public.
#

sub new {
  my $pkg = shift;
  my $iniData = shift;
  my $verbose = shift;
  my $self;
  $self->{iniData} = $iniData;
  $self->{verbose} = $verbose;
  bless $self, $pkg;
  return $self;
}

sub GenerateManifest {
  my $self = shift;
  my $comp = shift;
  my $version = shift;
  my $archive = shift;

  my $relData;
  if (defined $archive) {
    $relData  = RelData->OpenExternal($archive, $comp, $version);
  }
  else {
    $relData = RelData->Open($self->{iniData}, $comp, $version, $self->{verbose});
  }

  $self->{'baselineName'} = $comp;
  $self->{'baselineVersion'} = $version;

  print "Generating Release manifest file.\n";
  
  #Get envirnoment from baseline's reldata.
  my $environment = $relData->Environment();

  foreach my $thisComp (sort keys %{$environment}){
    #Identify the release directory for all components.
    my $thisVer = $environment->{$thisComp};
    print "Reading $thisComp $thisVer.\n " if($self->{verbose});
    
    my $relDir;
    if (defined $archive) {
      $relDir = File::Spec->catdir($archive, $thisComp, $thisVer);
    }
    else {
      $relDir = $self->{iniData}->PathData->LocalArchivePathForExistingComponent($thisComp, $thisVer);
    }
    croak "$thisComp $thisVer doesn't exist.\n" unless(-e $relDir);
    
    opendir(RELDIR, $relDir) or croak "Error: can't opendir $relDir\n";
    my @allFiles = grep {$_ ne '.' and $_ ne '..'} map {"$relDir\\$_"} readdir(RELDIR);
    close RELDIR;
    $self->{components}{$thisComp}{version} = $thisVer;
    #List all files from component release.
    foreach my $thisFile (@allFiles) {
      my $file = basename($thisFile);
      next if($file eq "." or $file eq "..");

      #Record size, md5 checksum and modified timestamp for all files.
      open(FILEHANDLE,"$thisFile") or croak "Couldn't open file \"$thisFile\".\n";
      $md5 = Digest::MD5->new;
      $md5->addfile(FILEHANDLE);
      close FILEHANDLE;

      my $modifiedTimeStamp = Utils::FileModifiedTime($thisFile);

      $self->{components}{$thisComp}{files}{$file}{+SIZE} = -s $thisFile;
      $self->{components}{$thisComp}{files}{$file}{+MD5} = $md5->hexdigest;
      $self->{components}{$thisComp}{files}{$file}{+MODIFIED_TIME} = $modifiedTimeStamp;
    }
  }

}

sub Save {
  my $self = shift;
  my $manifestFilePath = shift;

  unless (-d $manifestFilePath) {
    eval {mkpath($manifestFilePath)};
    if ($@) {
      my $error = $@;
      $error =~ s/ at .*?(?i:manifest\.pm) line \d+$//;
      die "Error: Unable to create path $manifestFilePath: $error\n";
    }
  }
  print "Writing release manifest to $manifestFilePath path.\n ";
  my $release = {
        version =>   VERSION,
        meta => { 'baseline-name' => { 'value' => $self->{'baselineName'} },
                  'baseline-version' => { 'value' => $self->{'baselineVersion'} },
                  'created-time' => { 'value' => strftime( '%Y-%m-%dT%H:%M:%S', localtime() ) } },
        manifest => { component => [] }
  };
  my $manifest = $self->{'baselineName'} ."_".$self->{'baselineVersion'}."_manifest.xml";
  my $manifestFile = File::Spec->catfile( $manifestFilePath, $manifest );
  my $components = {};
  foreach  my $thisComp(sort keys %{$self->{components}}) {
    $thisVer = $self->{components}{$thisComp}{version};
    my $index = "$thisComp,$thisVer";
    foreach  my  $thisFile (sort keys %{$self->{components}{$thisComp}{files}}) {
      my $file = { 
           'name' => $thisFile,
           'size' => $self->{components}{$thisComp}{files}{$thisFile}{+SIZE},
           'md5'  => $self->{components}{$thisComp}{files}{$thisFile}{+MD5},
           'modified-timestamp' => $self->{components}{$thisComp}{files}{$thisFile}{+MODIFIED_TIME}
	  };
      if (!defined $components->{$index}) {
        $components->{$index} = { file => [], name => $thisComp, version => $thisVer }; # make ref
        push @{$release->{manifest}{component}}, $components->{$index};
      }
      push @{$components->{$index}{file}}, $file;
    }
  }

  eval {XMLout(
        $release,
        xmldecl     => '<?xml version="1.0" ?>',
        rootname    => 'release',
        outputfile  => $manifestFile )};

  croak "Error: Can't write manifest file: $@\n" if $@;
}

sub Load {
  my $self = shift;
  my $manifestFile = shift;
  
  if (!-e $manifestFile) {
    die "Error: Can't read manifest file '$manifestFile': File does not exist\n";
  }
  
  my %metaFieldMap = qw(baseline-name baselineName baseline-version baselineVersion created-time createdTime);
  my $release   = eval{XMLin(
                    $manifestFile,
                    forcearray => [ qw(component file) ],
                    keyattr => [])};


  die "Error: Can't read manifest file '$manifestFile': $@\n" if $@;
  print "Reading $manifestFile file.\n " if($self->{verbose});

  for my $meta (@{$release->{meta}}) {
    $self->{$metaFieldMap{$meta->{name}}} = $meta->{value};
  }
  foreach my $component ( @{ $release->{manifest}{component} } ) {
    my $comp = $component->{'name'};
    my $version = $component->{version};
    $self->{components}{$comp}{version} = $version;
    foreach my $file ( @{ $component->{file} } ) {
      my $fileName = $file->{'name'};
      $self->{components}{$comp}{files}{$fileName}{+SIZE} = $file->{+SIZE};
      $self->{components}{$comp}{files}{$fileName}{+MD5} = $file->{+MD5};
      $self->{components}{$comp}{files}{$fileName}{+MODIFIED_TIME} = $file->{+MODIFIED_TIME};
    }
  }
}

sub FileExists {
  my $self = shift;
  my $comp = shift;
  my $file = shift;
  croak "Error: Component and file name must be specified.\n" unless(defined $comp and defined $file);
  return exists $self->{components}{$comp}{files}{$file};
}

1;

__END__

=head1 NAME

Symbian::CBR::Release::Manifest.pm - Provides an interface to data associated with a particular release.

=head2 new

Creates a new Symbian::CBR::Release::Manifest object. Expects to be passed a reference to an iniData object and verbose level.

=head2 GenerateManifest

Expects to be passed a component, version and optionally archive path. Generates a release manifest hash using component version and archive if provided. Otherwise uses archive specified in reltools.ini.

=head2 Save

Expects to be passed a destination path. Create destination path if destination path is not existing, and save the hash structure to manifest.xml file.

=head2 Load

Expects to be passed a manifest file path. Reads manifest file and converts into a hash structure.

=head2 FileExists

Expects to be passed a component name and file name. If file is present in the component returns 1, otherwise 0.

=head1 KNOWN BUGS

None.

=head1 COPYRIGHT

 Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
 All rights reserved.
 This component and the accompanying materials are made available
 under the terms of the License "Eclipse Public License v1.0"
 which accompanies this distribution, and is available
 at the URL "http://www.eclipse.org/legal/epl-v10.html".
 
 Initial Contributors:
 Nokia Corporation - initial contribution.
 
 Contributors:
 
 Description:
 

=cut
