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
# Symbian::CBR::IPR::MRP
#

package Symbian::CBR::IPR::MRP;

use strict;
use Carp;
use File::Spec;
use File::Basename;
use Cwd;
use Symbian::CBR::MRP::Reader;

use base qw(Class::Singleton);

use constant SRCROOT => ($ENV{SRCROOT} || '\\');

BEGIN {
    # The location of the CBR Tools may not be known to Perl, so we do a seach 
    # to see if they are available...
    if (!eval {require IniData}) {
        if (-e File::Spec->catdir(File::Basename::dirname("$0"), 'IniData.pm')) {
            push @INC, File::Spec->catdir(File::Basename::dirname("$0"));
        } 
        else {
            for my $path (split(/;/,$ENV{PATH})) {
                if (-e $path."\\IniData\.pm") {
                    push @INC, $path;
                    last;
                }
            }
        }
    } 
}


sub _new_instance {
    my $pkg = shift;
    my $typeOfMrp = shift;
    my $verbose = shift;

    if (!$typeOfMrp || shift) {
        # caller(0))[3] gives the package and the method called, e.g. Symbian::CBR::IPR::MRP::_new_instance
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }
    
    my $self = {};
    bless $self, $pkg;
       
    $self->{typeOfMrp} = $typeOfMrp;
    $self->{verbose} = $verbose;
    
    return $self;
}

sub PrepareInformationForComponent {
    my $self = shift;
    my $component = shift;
    
    my @mrpLocation;
    
    #if it's a comp name then look it up/read it 
    if (@mrpLocation = $self->GetMRPLocations($component)) {
        $self->ReadMRPFiles(\@mrpLocation);
    }
    else {
        # If we can't get any MRP locations then we can't use MRP files for IPR information
        return undef;
    }
}

sub PrepareInformationForMrpFile {
    my $self = shift;
    my @mrps = shift;
    
    #can take a single or a list
    
    $self->ReadMRPFiles(\@mrps);
}

sub Populate {
    my $self = shift;

    croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n" if (shift);
    
    if (exists $self->{populated}) {
        # We only need to populate the tree once
        return 1;
    }
    else {
        # Set a flag and continue
        $self->{populated} = 1;
    }
    
    my @mrpFiles;
    
    if (@mrpFiles = $self->GetMRPLocations()) {
        $self->ReadMRPFiles(\@mrpFiles);
        
        if (!(keys %{$self->{iprTree}})) {
            # If we can't get any IPR information from MRP files then we can't use MPR files for IPR information
            return undef;
        }        
    }
    else {
        # If we can't get any MRP locations then we can't use MRP files for IPR information
        return undef;   
    }
}


sub GetMRPLocations {
    my $self = shift;
    my $component = shift;

    croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n" if (shift);

    my @mrpFiles; 
   
    # Try to get MRP locations from environment database.
    if ($self->InvokeCBRTools()) {      
        @mrpFiles = $self->{envDB}->GetMRPLocations($component);
        
        if (scalar @mrpFiles) {
            # envDb may return \
            @mrpFiles = grep /\.mrp$/, @mrpFiles;
        }

        if (!scalar @mrpFiles) {
            return ();
        }
    
        return (@mrpFiles);
    }
    else {
        return ();
    }
}


sub InvokeCBRTools {
    my $self = shift;
    
    # If we have already tried to use the CBR Tools but have been unable to then return undef
    if ($self->{noCbrTools}) {
        return undef;
    }
    
    # If we have successfully created a CBR Tools EnvDB object then return true
    if (exists $self->{envDB}) {
        return 1;
    }
    
    # Otherwise we try to create a CBR Tools EnvDB object...
    my $iniData;
    my @errors;
    
    if (eval {require IniData} && eval {require EnvDb}) {
        eval {$iniData = IniData->New()};
 
         push @errors, $@ if ($@);

        if ($iniData) {
            eval {$self->{envDB} = EnvDb->Open($iniData)};

            push @errors, $@ if ($@);
        } 
    }
    
    if ($iniData && $self->{envDB} && !scalar(@errors)) {
        return 1;        
    }
    else {
        # If not successful then we produce a warning and return undef
        carp "Warning: Unable to use the CBR Tools for obtaining MRP locations\n";
        carp "The following errors were returned: @errors\n" if (scalar(@errors) > 0);

        $self->{noCbrTools} = 1;
        return undef;   
    }
}


sub ReadMRPFiles {
    my $self = shift;
    my $mrpFiles = shift;

    croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n" if (shift);
        
    # Construct a reader object, specifying the type of MRP object to populate
    if (!exists $self->{reader}) {
        print "Obtaining IPR information from MRP files...\n" if ($self->{verbose});
        $self->{reader} = Symbian::CBR::MRP::Reader->instance();
        $self->{reader}->SetVerbose() if ($self->{verbose});
    }
    
    my @dependencies;
    
    foreach my $mrpFile (@$mrpFiles) {
        # It is possible that the file doesn't exist, e.g. only binaries may be installed
        next if (!-e $mrpFile);
        
        # Skip this file if it has already been processed
        next if (exists $self->{processedMrpFiles}->{lc($mrpFile)}); 
        
        # Keep a record of the MRP files that we have processed...
        $self->{processedMrpFiles}->{lc($mrpFile)} = 1;
        
        eval {
            # Parse the MRP file.  The reader returns an MRP object
            my $mrpObj = $self->{reader}->ReadFile($mrpFile, $self->{typeOfMrp});
            
            # Get the IPR information from the MRP object
            my $iprInformation = $mrpObj->GetIPRInformation();
            
            # Add it to the IPR lookup tree
            $self->AddToTree($iprInformation);
    
            if (scalar($mrpObj->GetExportComponentDependencies())) {
                @dependencies = $mrpObj->GetExportComponentDependencies();
            }
        };

        if ($@) {
          print $@;
        }
    }
      
    # if any left over then call PrepareInformationForComponent
    foreach my $dependancy (@dependencies) {
        if (my @mrpLocations = $self->GetMRPLocations($dependancy)) {
            $self->ReadMRPFiles(\@mrpLocations);
        }
        else {
            carp "Warning: Unable to locate MRP file for dependant component \"$dependancy\"\n";
        }
    }
}


sub AddToTree {
    my $self = shift;
    my $iprInformation = shift;

    if (!$iprInformation || shift) {
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }

    foreach my $path (keys %{$iprInformation}) {
        my $lcPath = lc($path);
    
        # each folder is a branch on the tree
        $lcPath =~ s/^[\\\/]//;
        my @folders = split /[\\\/]/, $lcPath;
    
        # used to track position in tree
        my $branch = \%{$self->{iprTree}};
    
        foreach my $folder (@folders) {
            if (!exists $branch->{$folder}) {
                $branch->{$folder} = {};
            }
	    
            # ignore the special folder '.'
            unless ($folder eq '.') {
                $branch = $branch->{$folder};
            }
        }
	
        if (exists $branch->{'_category'}) {
            if ($branch->{'_category'} ne $iprInformation->{$path}->{'category'} || $branch->{'_exportRestricted'} ne $iprInformation->{$path}->{'exportRestricted'}) {
                # If IPR information has already been set and differs then we should set the data as null
                # so that distribution policy files will be used instead.
                $branch->{'_category'} = '';
                $branch->{'_exportRestricted'} = '';
                carp "Warning: IPR information for \"$path\" defined more than once in MRP files and differs and so will be ignored\n";
            }
        }
        else {
            $branch->{'_category'} = $iprInformation->{$path}->{'category'};
            $branch->{'_exportRestricted'} = $iprInformation->{$path}->{'exportRestricted'};
        }
    }
}


sub Category {
    my $self = shift;
    my $path = shift;

    if (!$path || shift) {
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }

    return $self->GetIPRinfo($path)->{'category'};
}


sub ExportRestricted {
    my $self = shift;
    my $path = shift;
    
    if (!$path || shift) {
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }
    
    return $self->GetIPRinfo($path)->{'exportRestricted'};
}


sub GetIPRinfo {
    my $self = shift;
    my $path = lc(shift); # We need to lowercase the path

    if (!$path || shift) { 
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }
    
    if (!exists $self->{iprTree}) {
        # If no information exists in the tree then try to populate all the information from the EnvDB database
        $self->Populate();
    }
    
    # Turn paths into abs from rel, some tools may pass relative paths (e.g. ExportIPR.pl)
    $path = File::Spec->rel2abs($path);

    # We need to remove drive letters
    $path =~ s/^[a-z]://i;

    my $results = {
                'category' => undef, # As the distribution policy modules return X if no category is found
                'exportRestricted' => undef};

    $path =~ s/^[\\\/]//; # Remove the first slash otherwise splitting the path on slashes will create an empty array entry
    my @folders = split /[\\\/]/, $path;

    my $branch = $self->{iprTree};

    # find the path in the tree
    foreach my $folder (@folders) {
        if (exists $branch->{$folder}) {
            $branch = $branch->{$folder};
            
            if (exists $branch->{'_category'}) {
                $results = {
                    'category' => $branch->{'_category'},
                    'exportRestricted' => $branch->{'_exportRestricted'}};
            }
        }
        else {
            last;
        }
    }

    return $results;
}

1;


__END__

=pod

=head1 NAME

Symbian::CBR::IPR::MRP - An interface to IPR information contained within MRP files

=head1 SYNOPSIS

 use Symbian::CBR::IPR::MRP;

 # Instantiate a Symbian::CBR::IPR::MRP object
 my $iprMrp = Symbian::CBR::IPR::MRP->instance();

 # Get the IPR category for a path
 my $category = $iprMrp->Category('\aPath\somewhere');

 # Get the export restricted flag for a path
 my $exportRestricted = $iprMrp->ExportRestricted('\aPath\somewhere');

=head1 DESCRIPTION

This package collates IPR information for either an entire environment, or for a
component, and provides methods to access IPR information for a given path.

=head1 METHODS

=head2 instance(component, typeOfMrp, verbose)

Instantiates a Symbian::CBR::IPR::MRP object.

The typeOfMrp argument is non-optional.  Valid types are MRP and MRPDATA.  See the
documentation for Symbian::CBR::MRP::Reader for more information.

If a component had been specified then the MRP file for the component will be processed
and the IPR information obtained.  Any MRP files for dependant components will be located
and processed too.  If no component name has been specified all MRP files in the environment
will be processed.

=head2 Category(path)

Returns the IPR category of the path.  If no IPR information exists for the
specified path then undef will be returned.

=head2 ExportRestricted(path)

Returns true if the specified path is export restricted, and false if it is not.
If no IPR information exists for the specified path then false will be returned.

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
