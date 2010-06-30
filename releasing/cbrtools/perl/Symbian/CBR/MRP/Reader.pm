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
# Symbian::CBR::MRP::Reader
#

package Symbian::CBR::MRP::Reader;

use strict;
use Carp;
use Symbian::CBR::MRP;

use base qw(Class::Singleton);

sub _new_instance {
    my $pkg = shift;
    my $self = {};
    
    # caller(0))[3] gives the package and the method called, e.g. Symbian::CBR::MRP::Reader::_new_instance
    croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n" if (scalar(@_));
    
    bless $self, $pkg;
}

sub ReadFile {
    my $self = shift;    
    my $file = shift;
    my $type = shift;
    
    if (!$file || !$type || shift) {
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }    
    
    my $mrpObject;
    
    # First we create the type of object required...
    if ($type eq 'MRP') {
        $mrpObject = Symbian::CBR::MRP->new($file);
    }
    elsif ($type eq 'MRPDATA') {
        if (!eval "require MrpData") {
            croak "Error: MrpData module is not available\n";
        }
        
        # PDDEF128617 fix
        # The envDb uses the path to the mrp file as a key with SRCROOT removed
        # An earlier MrpData->New was provided data from the envDb to create an MrpData Object
        # (so the key was mrp location with SRCROOT removed)
        # The below MrpData->New is given the full filename (because this function has to read the file)
        # This is wrong, the key for MrpData->New is not the full path
        # So the below line removes the SRCROOT from the key before providing it to MrpData->New
        my $localMrpName = $file;
        if (Utils::WithinSourceRoot($localMrpName)){
            $localMrpName = Utils::RemoveSourceRoot($localMrpName);        
        }
        #The 1 is to tell MrpData not to read the file
        $mrpObject = MrpData->New($localMrpName, undef, undef, undef, undef, undef ,1);
    }
    else {
        croak "Error: Invalid MRP object type $type\n";
    }

    if ($mrpObject->Populated()) {
        # MrpData is a multiton, it's possible a populated object has been returned
        return $mrpObject;
    }
    
    if (!$mrpObject) {
        croak "Unable to create an $type object for '$file'\n";   
    }
    
    if (!-f $file) {
        croak "Error: \"$file\" does not exist\n";
    }

    if ($self->{verbose}) {
        print "Reading $file...\n";
    }

    # Then parse the file and populate the object
    open MRP, $file or die "Unable to open \"$file\" for reading: $!\n";
    
    while (my $line = <MRP>) {
        chomp $line;
        
        $line =~ s/(?<!\\)#.*$//;  # remove comments
        $line =~ s/^\s+//;
        next if (!$line); # blank lines

        my @parts;
        
        my $string = $line;
        while ($string) {
            if ($string =~ s/^\"(.*?)\"//    # Match and remove next quoted string
            or $string =~ s/^(.*?)\s+//  # or, match and remove next (but not last) unquoted string
            or $string =~ s/^(.*)\s*$//) {  # or, match and remove last unquoted string.
                push (@parts, $1);
                $string =~ s/^\s+//; # Remove delimiter if present.
            }
        }
        
        my $keyword = shift @parts;

        my $remove = ($keyword =~ s/^-//);
        
        if (!scalar(@parts) or ($remove && $keyword !~ /binary|testbinary|export_file/)) {
            croak "Error: Invalid line in \"$file\" \(Line $.\): \"$line\"\n";
        }

        if ($keyword eq 'component') {
            if (scalar @parts > 1) {
                croak "Error: Invalid number of arguments to $keyword keyword in \"$file\"\n";   
            }
            if (!$mrpObject->SetComponent($parts[0])) {
                croak "Error: 'component' keyword used more than once in \"$file\"\n";
            }
        }
        elsif ($keyword eq 'notes_source') {
            if (scalar @parts > 1) {
                croak "Error: Invalid number of arguments to $keyword keyword in \"$file\"\n";   
            }
            if (!$mrpObject->SetNotesSource($parts[0])) {
                croak "Error: 'notes_source' keyword used more than once in \"$file\"\n";
            }
        }       
        elsif ($keyword eq 'source') {
            my $source = join ' ', @parts;
            if (!$mrpObject->SetSource($source)) { # some source statements contain spaces in the name
                croak "Error: 'source' entry for \"$source\" defined more than once in \"$file\"\n";
            }
        }
        elsif ($keyword =~ /^(test)?binary$/) {
            if (scalar @parts > 4) {
                croak "Error: Invalid number of arguments to $keyword keyword in \"$file\"\n";
            }
            
            # SetBinary (operand, test, remove)
            $mrpObject->SetBinary(\@parts, $1, $remove);
        }
        elsif ($keyword =~ /^(test)?exports$/) {
            if (scalar @parts > 2) {
                croak "Error: Invalid number of arguments to $keyword keyword in \"$file\"\n";
            }

            # SetExports (operand, test, dependantComponet)
            $mrpObject->SetExports($parts[0], $1, $parts[1]);
        }
        elsif ($keyword eq 'export_file') {
            if (scalar @parts > 3) {
                croak "Error: Invalid number of arguments to $keyword keyword in \"$file\"\n";
            }

            # SetExportFile (source, destination, remove, dependantComponet)
            $mrpObject->SetExportFile($parts[0], $parts[1], $remove, $parts[2]);
        }
        elsif ($keyword eq 'ipr') {
            if (scalar @parts > 3) {
                croak "Error: Invalid number of arguments to $keyword keyword in \"$file\"\n";
            }

            # SetIPR (category, path, exportRestricted)
            if ($parts[0] eq 'export-restricted') {
                if (!$mrpObject->SetIPR($parts[1], $parts[2], 1)) {
                   croak "Error: IPR information for \"$parts[2]\" specified more than once in \"$file\"\n";
                }
            }
            else {
                if (!$mrpObject->SetIPR($parts[0], $parts[1], 0)) {
                   croak "Error: IPR information for \"$parts[1]\" specified more than once in \"$file\"\n";
                }
            }
        }
        else {
            croak "Error: Invalid line in \"$file\" \(Line $.\): \"$line\"\n";
        }
    }
    close MRP;
    
    $mrpObject->ValidateParsing();

    return $mrpObject;
}

sub SetVerbose {
    my $self = shift;
    
    $self->{verbose} = 1;
}

1;

__END__

=pod

=head1 NAME

Symbian::CBR::MRP::Reader - Parses MRP files and returns a populated MRP object

=head1 SYNOPSIS

 use Symbian::CBR::MRP::Reader;

 # Instantiate an instance of the Symbian::CBR::MRP::Reader object
 my $mrpReader = Symbian::CBR::MRP::Reader->instance();

 my $mrpFile = '\someFolder\anMrpFile.mrp';

 # Enable verbose output
 $mrpReader->SetVerbose();

 # Call ReadFile on the mrp reader, specifying the MRP file to parse and the type
 # of MRP object you want to be populated and returned
 my $mrpObject = $mrpReader->ReadFile($mrpFile, 'MRP');

 ...

 # Call methods on the returned MRP object
 $mrpObject->GetIPRInformation();

=head1 DESCRIPTION

This module is used to parse MRP files and populate MRP objects.  The user can
specify the type of MRP object to be populated and returned.  This module includes
basic MRP syntax checking but stronger syntax checking should be implemented
in the MRP object to be populated.

=head1 METHODS

=head2 instance()

Instantiates and returns Symbian::CBR::MRP::Reader object.  This object is a
singleton.

=head2 ReadFile (mrpfile, type)

Reads the specified MRP file, instantiates and populates an MRP object of the
type specified and then returns the populated MRP object to the caller.

Valid MRP types are MRP and MRPDATA.

MRP: This is a Symbian::CBR::MRP object.  It is a lightweight MRP object and
contains only basic MRP functionality.  This option should be used when MRP
objects are required for tools which are not part of the CBR Tools.  See the
Symbian::CBR::MRP documentation for more details.

MRPDATA:  This is an MrpData object, as used by the CBR Tools.  This option
should only be used for the CBR Tools. See the MrpData documentation
for more details.

=head2 SetVerbose ()

Used to set enable verbose output.  Once set it is not possible to unset the
verbose output.  This is because this package is a singleton, and disabling the
verbose output could disrupt other code using this same instance.  This means
that it is not possible to disable the verbosity once it has been enabled.

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
