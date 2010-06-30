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
# Symbian::IPR
#

package Symbian::IPR;

use strict;
use Carp;
use Symbian::CBR::IPR::MRP;
use Symbian::DistributionPolicy::Reader;

use base qw(Class::Singleton);


sub _new_instance {
    my $pkg = shift;
    my $useDistPolFirst = shift;
    my $disallowUnclassifiedSource = shift;
    my $typeOfMrp = shift;
    my $verbose = shift;
    my $captureDistributionPolicyOutput = shift;
    
    if (!$typeOfMrp || shift) {
        # caller(0))[3] gives the package and the method called, e.g. Symbian::IPR::_new_instance
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }

    my $self = {
            'useDistPolFirst' => $useDistPolFirst,
            'disallowUnclassifiedSource' => $disallowUnclassifiedSource,
            'verbose' => $verbose,
            'typeOfMrp' => $typeOfMrp,
            'captureDistributionPolicyOutput' => $captureDistributionPolicyOutput};

    bless $self, $pkg;

    if (!$useDistPolFirst) {
        # If we are not using distribution policy files as default then create a Symbian::CBR::IPR::MRP object... 
        $self->CreateMrpObject();
    }
    
    return $self;
}

sub CreateMrpObject {
    my $self = shift;
    
    if (!exists $self->{'mrpObject'}) {
        $self->{'mrpObject'} = Symbian::CBR::IPR::MRP->instance($self->{typeOfMrp}, $self->{verbose});
    }
    
    # We may have cached calls to PrepareInformationForComponent...
    if (defined $self->{prepareInformationForComponentCache}) {
        foreach my $component (@{$self->{prepareInformationForComponentCache}}) {
            $self->PrepareInformationForComponent($component);
        }
        delete $self->{prepareInformationForComponentCache};
    }
    
    # and also to PrepareInformationForMrpFile...
    if (defined $self->{prepareInformationForMrpFileCache}) {
        $self->PrepareInformationForMrpFile->(@{$self->{prepareInformationForMrpFileCache}});
        delete $self->{prepareInformationForMrpFileCache};
    }
}

sub PrepareInformationForComponent {
    my $self = shift;
    my $component = shift;
    
    # An MRP object may not have been created, for example if using distribution policy files first.
    # In that case we cache the calls to PrepareInformationForComponent, and will pass them onto the
    # MRP object if it is ever created.
    if (defined $self->{'mrpObject'}) {
        $self->{'mrpObject'}->PrepareInformationForComponent($component);
    }
    else {
        push @{$self->{prepareInformationForComponentCache}}, $component;
    }
}

sub PrepareInformationForMrpFile {
    my $self = shift;
    my @mrps = shift;   

    # An MRP object may not have been created, for example if using distribution policy files first.
    # In that case we cache the calls to PrepareInformationForMrpFile, and will pass them onto the
    # MRP object if it is ever created.
    if (defined $self->{'mrpObject'}) {
        $self->{'mrpObject'}->PrepareInformationForMrpFile(@mrps);
    }
    else {
        push @{$self->{prepareInformationForMrpFileCache}}, @mrps;
    }
}


sub Category {
    my $self = shift;
    my $path = shift;

    if (!$path || shift) {
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }
    
    my ($category, $errors) = $self->GetRequestedInformation($path, 'Category');

    if (!$category) {
        $category = 'X';
    }

    return ($category, $errors);
}

sub ExportRestricted {
    my $self = shift;
    my $path = shift;

    if (!$path || shift) {
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }

    my ($exportRestricted, $errors) = $self->GetRequestedInformation($path, 'ExportRestricted');

    return ($exportRestricted, $errors);
}

sub GetRequestedInformation {
    my $self = shift;
    my $path = shift;
    my $what = shift;

    my @errors; # This collects the errors produced from the distribution policy modules.
                # The CBR Tools handle these errors in a different way.

    if (!$path || !$what || shift) {
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }
    
    my $result = undef;
    my $informationFrom = undef;
    
    if (!$self->{useDistPolFirst} && $self->{mrpObject}) {
        # If to use MRP files first and an Mrp object exists...
        $result = $self->{mrpObject}->$what($path);

        $informationFrom = 'M' if (defined $result);
    }
    
    if (! defined $result) {
        # If  distribution policies are to be used first or could not obtain information
        # from MRP object then use distribution policies

        # Create a distribution policy reader if one does not already exist...
        if (!$self->{distPolReader}) {
            # Create a distribution policy reader if one does not already exist...
            $self->{distPolReader} = Symbian::DistributionPolicy::Reader->new();
        }
        
        if ($self->{distPolReader}->isa("Symbian::DistributionPolicy::Reader")) {
            my $warner;
            
            # We may need to capture the output of the distribution policy modules
            if ($self->{'captureDistributionPolicyOutput'}) {
                $warner = sub { push @errors, shift; };
            }
            local $SIG{__WARN__} = $warner if ($warner);

            # We want to make sure that we do have a reader before trying to read a file
            eval {  my $distPolObj = $self->{distPolReader}->ReadPolicyFile($path);
                    $result = $distPolObj->$what()};

            $informationFrom = 'D' if (defined $result);
        }
    }

    if ((!defined $result) && $self->{useDistPolFirst}) {
        # If distribution policies have been used first and failed then try getting the information from MRP files...
        
        # The Symbian::CBR::IPR::MRP might not yet have been created
        if (!exists $self->{mrpObject}) {
            $self->CreateMrpObject();
        }
        
        $result = $self->{mrpObject}->$what($path);

        $informationFrom = 'M' if (defined $result);
    }
   
    if (!defined $informationFrom && $self->{disallowUnclassifiedSource}) {
        carp "Warning: IPR information for '$path' could not be obtained from either MRP files or distribution policy files\n";
    }
        
    if ($self->{verbose} > 1) {
        # If verbose then we print information saying where the IPR information was obtained from
        if ($informationFrom eq 'M') {
            print "Info: IPR information for '$path' was obtained using MRP files\n";
        }
        elsif ($informationFrom eq 'D') {
            print "Info: IPR information for '$path' was obtained using Distribution Policy files\n";
        }        
    }

    return ($result, \@errors);
}

1;

__END__

=pod

=head1 NAME

Symbian::IPR - An interface to IPR information within MRP files and Distribution
Policy files.

=head1 SYNOPSIS

use Symbian::IPR;

 # Instantiate a Symbian::IPR object
 my $iprObject = Symbian::IPR->instance(0, 0, 'MRP', undef, 1);

 # Get the IPR category for a path
 my $category = $iprObject->Category('\aPath\somewhere');

 # Get the export restricted flag for a path
 my $exportRestricted = $iprObject->ExportRestricted('\aPath\somewhere');

=head1 DESCRIPTION

This package provides an interface to obtaining IPR information from MRP files
and Distribution Policy files.  The user can specify the order of preference
between MRP and distribution policies.  If the requested information can not be
obtained from the preferred choice then the package will fall back to using the
other option.

=head1 METHODS

=head2 new(useDistPolFirst, disallowUnclassifiedSource, typeOfMrp, component, verbose)

Instantiates a Symbian::IPR object.

The default order is for IPR information to be obtained from MRP files first, and
if unsuccessful then to obtain the IPR information from distribution policy files.
If the boolean value useDistPolFirst is specified then IPR information will be
obtained from distribution policy files by default, and if not successful then
MRP files will be used.

If the disallowUnclassifiedSource flag is specified then warnings will be produced
if IPR information can not be obtained both MRP files and distribution.policy files.

The typeOfMrp argument is non-optional.  Valid types are MRP and MRPDATA.  See the
documentation for Symbian::CBR::MRP::Reader for more information.

If a component had been specified then the MRP file for the component will be processed
and the IPR information obtained.  Any MRP files for dependant components will be
located and processed too.  If no component name has been specified all MRP files
in the environment will be processed.

=head2 Category(path)

Returns the IPR category of the path.  If no IPR information exists for the
specified path then X will be returned.

=head2 ExportRestricted(path)

Returns true if the specified path is export restricted, and false if it is not.
If no IPR information exists for the specified path then undef will be returned.

=head2 PrepareInformationForComponent(component_name)

If using MRP files for IPR information it is possible to specify which components
contain the information required.  This improves performance as only required
MRP files are processed.  The default behaviour is to process all MRP files listed
in the CBR Tools environment database.

If using distribution policy files as default then information passed to this method
will be cached and realised only if it becomes necessary to use MRP files for IPR
information (e.g. distribution policy file does not exist).

=head2 PrepareInformationForMrpFile(list_of_mrp_files)

If using MRP files for IPR information it is possible to specify which MRP files
contain the information required.  This can be used in scenarios where a CBR Tools
environment database does not exist, and so MRP locations are unknown.

If using distribution policy files as default then information passed to this method
will be cached and realised only if it becomes necessary to use MRP files for IPR
information (e.g. distribution policy file does not exist).

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
