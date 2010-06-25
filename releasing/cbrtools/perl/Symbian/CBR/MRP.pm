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
# Symbian::CBR::MRP
#

package Symbian::CBR::MRP;

use strict;
use Carp;
use File::Spec;
use base qw(Symbian::CBR::MRPInterface);


sub new {
    my $pkg = shift;
    my $mrpName = shift;
    my $verbose = shift;

    if (!$mrpName || shift) {
        # caller(0))[3] gives the package and the method called, e.g. Symbian::CBR::MRP::new
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }
    
    my $self = {
            'mrpName' => $mrpName,
            'verbose' => $verbose};

    bless $self, $pkg;

    return $self;
}

sub SetIPR {
    my $self = shift;
    my $category = shift;
    my $path = lc(shift) || 'default';
    my $exportRestricted = (shift) ? 1 : 0;
    
    if (!$category || shift) {
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";        
    }
    
    if ($category !~ /^[a-z]$/i) {
        #Check that the IPR category specified is indeed a valid category
        croak "Error: IPR category $category is invalid\n";
    }

    $path = File::Spec->canonpath($path); # Normalise the path
    
    # remove trailing slashes
    $path =~ s/[\\\/]$//;
    
    if (exists $self->{unresolvedIPR}->{$path}) {
        return 0;
    }
    
    $self->{unresolvedIPR}->{$path} = {
                    category => uc($category),
                    exportRestricted => $exportRestricted};
    
    return 1;
}

sub SetComponent {
    my $self = shift;
    my $operand = shift;

    if (!$operand || shift) {
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }

    if (exists $self->{componentName}) {
        return 0;
    }
    
    $self->{componentName} = $operand;
    
    return 1;
}

sub SetNotesSource {
    my $self = shift;
    my $operand = shift;

    if (!$operand || shift) {
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }
    
    if (exists $self->{notesSource}) {
        return 0;
    }

    $operand = File::Spec->canonpath($operand); # Normalise the path
    
    if (!-f $operand) {
       croak "Error: Notes source \"$operand\" does not exist\n";
    }

    $self->{notesSource} = $operand;
    
    return 1;
}

sub SetSource {
    my $self = shift;
    my $operand = shift;

    if (!$operand || shift) {
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }

    $operand = File::Spec->canonpath($operand); # Normalise the path
    
    #remove trailing slashes
    $operand =~ s/[\\\/]$//;
    
    if (!-e $operand) {
       croak "Error: Source \"$operand\" does not exist\n";
    }
    
    if (exists $self->{sourceItems}->{$operand}) {
        return 0;
    }
    
    $self->{sourceItems}->{$operand} = 1;
    
    return 1;
}

sub SetBinary {
    my $self = shift;
    my @operand = @{shift()} if (ref $_[0] eq 'ARRAY');
    my $test = (shift) ? 1 : 0;
    my $remove = (shift) ? 1 : 0;

    if (!scalar(@operand) || shift) {
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }

    my $path = shift @operand;

    $path = File::Spec->canonpath($path); # Normalise the path

    push @{$self->{binary}}, {
                        path    => $path,
                        test    => $test,
                        remove  => $remove,
                        words   => [@operand]};
}

sub SetExports {
    my $self = shift;
    my $operand = shift;
    my $test = (shift) ? 1 : 0;
    my $dependantComponent = shift;

    if (!$operand || shift) {
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }

    if (exists $self->{exports}->{$operand}) {
        croak "Error: 'exports' entry for \"$operand\" defined more than once in $self->{mrpName}\n";
    }

    $operand = File::Spec->canonpath($operand); # Normalise the path

    if (!-e $operand) {
        croak "Error: Exports path \"$operand\" does not exist\n";
    }

    $self->{exports}->{$operand} = $test;
    
    if ($dependantComponent) {
        push (@{$self->{exports}->{_dependantComponent}}, $dependantComponent);
    }
}

sub SetExportFile {
    my $self = shift;
    my $source = shift;
    my $destination = shift;
    my $remove = (shift) ? 1 : 0;
    my $dependantComponent = shift;

    if (!$source || shift) {
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }
    
    unless ($source and $destination) {
        croak "Error: Incorrect syntax to 'export_file' keyword in \"$self->{mrpName}\"\n";
    }

    $source = File::Spec->canonpath($source); # Normalise the path
    $destination = File::Spec->canonpath($destination);
    
    if (!$remove) {
        if (!-e $source) {
            croak "Error: Export file \"$source\" does not exist\n";
        }
    }

    push @{$self->{exportFiles}}, {
                    source      => $source,                  
                    destination => $destination,
                    remove      => $remove};

    if ($dependantComponent) {
        push (@{$self->{exports}->{_dependantComponent}}, $dependantComponent);
    }
}

sub GetIPRInformation {
    my $self = shift;
    
    if (exists $self->{IPR}) {
        return $self->{IPR};
    }
    else {
        return {};
    }
}

sub Component {
    my $self = shift;
    
    if ($self->{componentName}) {
        return $self->{componentName};
    }
    
    return undef;
}

sub GetExportComponentDependencies {
    my $self = shift;

    if (exists $self->{exports}->{_dependantComponent}) {
        return @{$self->{exports}->{_dependantComponent}}
    }

    return undef;
}

sub GetSource {
    my $self = shift;
    
    if (exists $self->{sourceItems}) {
        return [keys %{$self->{sourceItems}}];
    }
    
    return [];
}

sub ValidateParsing {
    my $self = shift;

    # This flag stops the reader from trying to populate the object more than once
    $self->{populated} = 1;

    if (exists $self->{sourceItems} && !exists $self->{unresolvedIPR}) {
        # If no IPR information exists in the MRP file then we set the IPR category
        # for each source item to undef.  This is so that incorrect IPR information is
        # not returned.
        
        foreach my $sourceItem (keys %{$self->{sourceItems}}) {
            $self->{IPR}->{$sourceItem} = {
                                           category => undef,
                                           exportRestricted => undef,
                                           };
        }
    }
    else {
        # Reconcile the IPR information here so that any warnings are produced sooner...
        # IPR information can only be included if it matches a source line in the MRP file
        # All other IPR lines will be ignored.  The reconciliation is done here as IPR
        # lines may appear before source lines in the MRP file.

        if (!defined $self->{sourceItems} && exists $self->{unresolvedIPR}->{default}) {
            carp "Warning: The default IPR entry does not apply to any source statements in \"$self->{mrpName}\"\n";
        }

        # Match IPR against source statement by using the length...
        foreach my $sourceItem (keys %{$self->{sourceItems}}) {    
            # The sort below sorts by longest line first, not shortest line first. Note $b <=> $a, not $a <=> $b...
            # This allows us to match the most relevant line first, based on longest length/best match 
            foreach my $iprItem (sort {length($b) <=> length($a)} keys %{$self->{unresolvedIPR}}) {
                next if ($iprItem eq 'default');
                # If the source item contains the IPR path then it is a match 
                if ($sourceItem =~ m/^\Q$iprItem\E([\\\/]|$)/i) {
                    $self->{IPR}->{$sourceItem} = $self->{unresolvedIPR}->{$iprItem};
                    
                    last;   
                }
            }
                 
            # If it didn't match an IPR then we assign the default
            if (!exists $self->{IPR}->{$sourceItem}) {
                $self->{IPR}->{$sourceItem} = $self->{unresolvedIPR}->{default};
            }
        }
    
        delete $self->{unresolvedIPR}->{default};
    
        # Find IPR entries which do live under a source folder...
        foreach my $iprItem (keys %{$self->{unresolvedIPR}}) {
            next if (exists $self->{IPR}->{$iprItem});
            
            foreach my $sourceItem (keys %{$self->{sourceItems}}) {
                if ($iprItem =~ /^\Q$sourceItem\E/i) {
                    $self->{IPR}->{$iprItem} = $self->{unresolvedIPR}->{$iprItem};
                    last;
                }
            }
         
            if (!grep /\Q$iprItem\E/i, (keys %{$self->{IPR}})) {
                # Otherwise this IPR statement does not apply to this MRP file...
                carp "Warning: The IPR entry for \"$iprItem\" does not apply to any source statements in \"$self->{mrpName}\"\n";
            }     
        }
        
        delete $self->{unresolvedIPR};
    }
}

sub Populated {
  my $self = shift;
  
  return $self->{populated};
}

1;

__END__

=pod

=head1 NAME

Symbian::CBR::MRP - An object representation of an MRP file

=head1 SYNOPSIS

 use Symbian::CBR::MRP;

 # Construct a Symbian::CBR::MRP object 
 my $mrpObject = Symbian::CBR::MRP->new(mrpName);

 # Use the setters to populate the object
 
 $mrpObject->SetComponent('componentName');
 
 $mrpObject->SetSource('\src\aSrcFolder');
 
 $mrpObject->SetNotesSource('\componentDefs\notes.src');
 
 # Validate the parsing\perform any post parsing operations
 $mrpObject->ValidateParsing();
 
 ...
 
 # Getting information from the Symbian::CBR::MRP object
 my $iprInformation = $mrpObject->GetIPRInformation();
 
 # Get the component name
 my $componentName = $mrpObject->GetComponent();

=head1 DESCRIPTION

This object represents an MRP file.  It is intended to be created and populated
by an MRP file parser, for example Symbian::CBR::MRP::Reader.  No parsing
functionality is included with this object.

Once the object has been populated the parser should call the ValidateParsing()
method, which will perform any post-population actions, such as resolving IPR
information etc.

=head1 METHODS

=head2 new(mrpName, verbose)

Instantiates a Symbian::CBR::MRP object.  The mrpName argument is only used for
printing error and warning messages.

=head2 GetIPRInformation()

Returns a hash containing the IPR information for the component.

The format is the returned data is a hash:

    Path = (
                    category = char,
                    exportRestricted = boolean
            )

=head2 SetBinary(@arguments, test, remove)

Sets the binary information.  @arguments is an array containing the arguments
from the MRP line, in the order in which they appeared.  

=head2 SetComponent(componentName)

Sets the name of the component to componentName.

=head2 SetExportFile(source, destination, remove, dependantComponent)

Sets the export file information.  The source and destination arguments are both
required, if they are not specified a fatal error will be produced.  The source
file will also be checked to see if it exists and that it has not already been
specified as an export file.

If the export file is not included as source for the current MRP component then
the dependant component will also need to be specified.

=head2 SetExports(path, test, dependantComponent)

Sets the location of the bld.inf from where the export information can be derived.
The location will be checked to see if it exists and that it has not already been
specified.

If the exports are not included as source for the current MRP component then
the dependant component will also need to be specified.

=head2 SetIPR(category, path, exportRestricted)

Sets the IPR information for the component.  If no path is specified then the
IPR category is set to be the default category for the component.  The
exportRestricted argument is boolean.

If the same path is specified more than once a fatal error will be produced.

=head2 SetNotesSource(noteSourcePath)

Sets the notes source to the notesSourcePath specified.  If the notes source has
already been set, or the path does not exist, a fatal error will be produced.

=head2 SetSource(sourcePath)

Adds the sourcePath to the list of included source entries for the component.
If the source path does not exist or the path has already been added then a
fatal error will be produced.

=head2 ValidateParsing()

This method needs to be called once the parser has finished setting all the
information.  Currently this method reconciles IPR statements against the
components source, and also checks that required dependant components have
been set.

If this method is not run then IPR information will be unavailable.

=head2 GetExportComponentDependencies()

Returns an array containing the any components which the current component has
dependencies on.

=head2 Component()

Returns the component name.

=head2 Populated()

The MRP file is parsed by a reader, which then populates this MRP object.  The
Populated method returns a boolean value indicating if the object has been
populated.

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
