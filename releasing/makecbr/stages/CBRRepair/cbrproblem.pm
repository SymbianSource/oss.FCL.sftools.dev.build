#!\bin\perl
# Copyright (c) 2004-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# cbrproblem
# Support for the CBRPatch code, here we record problems within
# damaged CBR environment
# 
#

use strict;
package CBRProblem;

use File::Basename;
use CBRFix;

#
# new
# 
# Create a new CBRProblem object.
#
sub new
    {
    my($arg, $path, $type, $components) = @_;
    my $class = ref($arg) ? ref($arg) : $arg;

    my $self = {};
    bless $self, $class;

    $components = {} if !ref($components);

    $self->Path($path)     if( $path );
    $self->Type($type)     if( $type );
    $self->Components($components) if( $components );

    return $self;
    }

#
# Path
#
# Setter/getter for path member of this CBRProblem object. Path is
# just scalar text. If no path is passed to this, keep the old. In any
# case return the current value of path.
#
sub Path
    {
    my $self = shift;
    return unless( ref($self) );
    my $newpath = shift;
    return $self->{path} unless $newpath;
    $newpath = "\\" . $newpath unless( $newpath =~ m/^\\/ );
    $newpath = lc($newpath);
    $self->{path} = $newpath;
    return $self->{path};
    }
#
# Type  (orphan/multi/absent/dirty)
#
# Setter/getter for type member of this CBRProblem object. Type is
# just scalar text. If no value is passed to this, keep the old. In any
# case return the current value of type.
#
sub Type
    {
    my $self = shift;
    return unless( ref($self) );
    my $newtype = shift;
    return $self->{type} unless $newtype;

    $self->{type} = "orphan"  if( $newtype =~ m/orphan/i );
    $self->{type} = "multi"   if( $newtype =~ m/multi/i );
    $self->{type} = "absent"  if( $newtype =~ m/absent/i );
    $self->{type} = "dirty"   if( $newtype =~ m/dirty/i );

    return $self->{type};
    }
#
# Components
#
# Setter/getter for components member of this CBRProblem object. Owner arg
# is a reference to a hash. If no value is passed to this, keep the old. In
# any case return the current value of components (which is a REFERENCE).
# The hash contains a list of components that this problem affects.
# Naturally the hash should contain one component owner, but we are talking
# about problems here..
#
sub Components  # Takes a reference to a hash if setting..
    {
    my $self = shift;
    return unless( ref($self) );
    my $ownref = shift;

    if( ref($ownref) )  # Reference to a hash, keys of which are components
        {               # claiming to own this file..
        for(keys %$ownref)
            {
            my $component = $_;
            $self->{components}->{$component} = 1;
            }
        }
    return $self->{components};
    }

#
# Return the fix(es) that are required to address this problem.
# We are passed inidata, the envdb, patcharea and 'binbag'
# component name.
#
sub GetFixes
    {
    my $self = shift;
    my($inidata, $envdb, $patcharea, $binbagcomp) = @_;
    return undef unless( ref($self) ); # Must be an object, not a class.

    #
    # First check if we have an easy fix - that is, a component is dirty
    # and therefore must be preprel'd, but nothing else like mrp file editing
    # needs doing.
    #
    if( $self->Type eq "dirty" )
        {
        my $ezfix = CBRFix->new( (keys %{$self->Components})[0], # Component
                                  undef,                # Text for mrp file.
                                  undef,                # Original Mrp file.
                                  undef );              # New mrp file.
        my @fixarray;
        push @fixarray, $ezfix;
        return \@fixarray;
        }

    # Make sure everything we need has been passed across.
    return undef unless( defined($inidata) and defined($envdb) and
                         defined($patcharea) and defined($binbagcomp));

    # Work out the 'binbag' mrpfile name.
    my $binbagmrp = "$patcharea\\$binbagcomp.mrp";

    # The binbag constitutes one CBRFix, we may need other fixes to be
    # done to the existing components.
    my $binbag = CBRFix->new($binbagcomp,  # The component this fix is for.
                             undef,        # The text to add to the mrpfile.
                             $binbagmrp,   # Original Mrp file.
                             $binbagmrp);  # Mrpfile to add the fix to.

    my @fixes; # An array of fixes. We'll return this at the end.

    if(defined($self->Components())) # No components for orphans.
        {
        for my $comp (keys %{$self->Components}) # For each concerned component
            {
            my $mrpfile = $envdb->MrpName($comp);
            unless( $mrpfile =~ m/^\\/ )
            {
                $mrpfile = "\\" . $mrpfile;   # EPOCROOT?
            }
            my $fxmrpdat=undef;
            my $newmrp = "$patcharea\\" . File::Basename::basename($mrpfile);
            my $errormsg = undef;
            unless( defined($fxmrpdat) )
                {
                undef $@;
                eval
                    {
                    $fxmrpdat = $envdb->GetMrpData($comp);
                    };
                $errormsg = $@;
                };

            # The above object creation fails utterly if we have a missing
            # source file. In that case we specify '-source'. Unfortunately
            # this situation also hides other faults with the component,
            # so another iteration might be required to fix everything.
            if( !defined($fxmrpdat) && ($errormsg =~ m/Error: .*?does not exist/) )
                {
                my $fix = CBRFix->new( $comp,            # Component
                                  undef,                 # Text for mrp file.
                                  $mrpfile,              # Original Mrp file.
                                  $newmrp);              # New mrp file.
                # Yes I know '-source' doesn't exist, but it might one
                # day, and for the moment we can intercept this before it
                # actually gets written.
                $fix->MrpFixText("-source " . $self->Path);
                my @fixarray;
                push @fixarray, $fix;
                return \@fixarray;
                }
            # Create the fix for this component.
            my $compfix = CBRFix->new( $comp,     # Component
                                       undef,     # Text to add to mrpfile.
                                       $mrpfile,  # Original mrp file.
                                       $newmrp ); # New mrp file.

            # We now need to determine whether our file that is causing us
            # all of this grief has been exported or is just a binary.
            # This block sets up two variables, 'comp_remove' which
            # is text to be added to the component to exclude the file,
            # and 'binbag_addition' which is text to be added to our
            # 'binbag' component..
            my($comp_remove, $binbag_addition);
            # Trigger ExportCategories, to get the export info cached.
            $fxmrpdat->ExportCategories();

            # The exportinfo structure is new to version 2.76.2 of the release
            # tools, it was introduced to fix DEF047062. It's kind of private
            # but right now this is the only way to associate an exported
            # file with its source.
            for my $class (keys %{$fxmrpdat->{exportinfo}})
                {
                for my $exl (keys %{$fxmrpdat->{exportinfo}->{$class} })
                    {
                    my $exfile = lc($exl);
                    my $srcfile = lc($fxmrpdat->{exportinfo}->{$class}->{$exl});

                    $exfile = "\\" . $exfile unless( $exfile =~ m/^\\/ );
                    $srcfile = "\\" . $srcfile unless( $srcfile =~ m/^\\/ );
                    if( $exfile eq lc($self->Path))
                        {
                        $srcfile = "\"$srcfile\"" if( $srcfile =~ m/\s/ );
                        $exfile = "\"$exfile\"" if( $exfile =~ m/\s/ );
                        $comp_remove = "-export_file    $srcfile $exfile\n";
                        $binbag_addition = "export_file    $srcfile $exfile\n";
                        last;
                        }
                    }
                }
            unless( $comp_remove )  # Not an export? Try binary.
                {
                for my $bil ( @{$fxmrpdat->Binaries()} )
                    {
                    my $bifile = lc($bil);
                    $bifile = "\\" . $bifile unless( $bifile =~ m/^\\/ );
                    if( $bifile eq lc($self->Path) )
                        {
                        my $lpth = lc($bifile);
                        $lpth = "\"$bifile\"" if( $bifile =~ m/\s/ );
                        $comp_remove = "-binary    $lpth\n";
                        $binbag_addition = "binary    $lpth\n";
                        last;
                        }
                    }
                }
            # Remove the file from the component it lives in.
            $compfix->MrpFixText($comp_remove);
            push @fixes, $compfix;

            # Add the file to the binbag, unless its already there and only
            # if we have a multiply owned file. Given where we are in the
            # code it can only be a multi-owned or absent file - and if its
            # absent we don't want to reference it, that was the original
            # problem.
            $binbag->MrpFixText($binbag_addition)
                   if(($self->Type eq "multi") and 
                    not(grep $binbag_addition, @{$binbag->MrpFixText}));
            }
        }
    else   # No component owns this file, must be an orphan.
        {
        if( $self->Type eq "orphan" )  # Check anyway. Should always be true.
            {
            my $lpth = $self->Path;
            $lpth = "\"$lpth\"" if( $lpth =~ m/\s/ );
            my $fixtext = "binary    $lpth\n";
            $binbag->MrpFixText($fixtext) 
                unless( grep $fixtext, @{$binbag->MrpFixText});    
            }
            
        }
        # Add binbag contents to the array of fixes generated by this problem
        # IF it contains anything.
        push @fixes, $binbag if( ref($binbag->MrpFixText) and
                                 (scalar @{$binbag->MrpFixText}) );

        # Return a reference to the fixes for this problem.
        return \@fixes;
    }

1;

