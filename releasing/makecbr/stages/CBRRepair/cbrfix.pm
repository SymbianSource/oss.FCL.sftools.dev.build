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
# cbrfix
# Support for the CBRPatch code, here we record potential fixes for a
# damaged CBR environment.
# 
#

package CBRFix;

use strict;

#
# new
# 
# Create a new CBRFix object.
#
sub new
    {
    my($arg, $component, $mrpfixtext, 
       $mrpfile, $newmrpfile, $notesrcline) = @_;
    my $class = ref($arg) ? ref($arg) : $arg;

    my $self = { component => undef,
                mrpfixtext => [],
                   mrpfile => undef,
              notessrcline => undef,
                newmrpfile => undef };
    bless $self, $class;

    $self->Component($component)   if( $component );
    $self->MrpFixText($mrpfixtext) if( $mrpfixtext );
#    $self->CbrProb($cbrprobref)    if( $cbrprobref );
    $self->MrpFile($mrpfile)       if( $mrpfile );
    $self->NewMrpFile($newmrpfile) if( $newmrpfile );
    $self->NotesSrcLine($notesrcline) if( $notesrcline );

    return $self;
    }

#
# Component
#
# Setter/getter for component member of this CBRFix object. Component is
# just scalar text. If no component is passed to this, keep the old. In any
# case return the current value of component.
# If the component is provided, the mrpfile will become undefined. We
# *could* trigger finding that out, but that could be really inefficient..
#
sub Component
    {
    my $self = shift;
    return unless( ref($self) );
    my $newcomp = lc(shift);
    return $self->{component} unless $newcomp;
    $self->{component} = $newcomp;
    undef($self->{mrpfile});
    return $self->{component};
    }

#
# MrpFile
#
# Setter/getter for the mrpfile for the CBRFix object. Takes what it is
# given on trust if it's there. If nothing is given, return the mrpfile
# name, which we may have to work out.
#
sub MrpFile
    {
    my $self = shift;
    return unless( ref($self) );
    my $mrpfile = lc(shift);

    # We're provided with the mrpfile. Set it.
    $self->{mrpfile} = $mrpfile if($mrpfile);

    # Make sure it has backslashes, not forward slashes.
    $self->{mrpfile} =~ s^\/^\\^g;
    
    # We're already know the mrpfile. Return it.
    return $self->{mrpfile} if( defined($self->{mrpfile}) );

    # We're provided with nothing and don't yet know our mrpfile. Find it
    # out, store it and return it.
    my $comp = $self->{component};
    my $inidata = IniData->New();
    my $envdb = EnvDb->Open($inidata);
    my $mrpname = $envdb->MrpName($comp);
    $self->{mrpfile} = $mrpname if( $mrpname );
    $self->{mrpfile} =~ s^\/^\\^g;
    return $self->{mrpfile};
    }

#
# Setter/getter for the 'newmrpfile' member, this is used when a component
# to be fixed must have a 'new' mrp location (usually /component_defs..)
#
sub NewMrpFile
    {
    my $self = shift;

    return unless( ref($self) );
    my $newmrpfile = shift;
    return $self->{newmrpfile} unless defined($newmrpfile);
    $newmrpfile =~ s^\/^\\^g;
    $self->{newmrpfile} = lc($newmrpfile);
    return $self->{newmrpfile};
    }

#
# MrpFixText
#
# Setter/getter for mrpfixtext member of this CBRFix object. Mrpfixtext is
# a reference to an array containing blocks (probably lines) of scalar text.
# If no value is passed to this do nothing. In any case return the current
# value of mrpfixtext, a reference to an array holding all of the lines.
#
sub MrpFixText
    {
    my $self = shift;
    return unless( ref($self) );
    my $newtext = shift;
    push @{$self->{mrpfixtext}}, $newtext if( defined($newtext));
    return $self->{mrpfixtext};
    }

# Setter/getter for notes_source line. This is only ever used if the component
# did not previously exist in the environment before the fix is written.
# Should only happen for the 'unresolved' component.
sub NotesSrcLine
    {
    my $self = shift;
    my $newnsl = shift;
    $self->{notessrcline} = $newnsl if( defined($newnsl) );
    return $self->{notessrcline} if( defined($self->{notessrcline}) );
    $self->{notessrcline} = "notes_source \\component_defs\\release.src\n";
    return $self->{notessrcline};
    }
#
# CbrProb
#
# Records a reference to the CBRProblem object that triggered this fix.
# Possibly not needed.
#
#sub CbrProb
#    {
#    my $self = shift;
#    return unless( ref($self) );
#    my $newprob = shift;
#    return $self->{cbrprob} unless $newprob;
#    $self->{cbrprob} = $newprob;
#    return $self->{cbrprob};
#    }

#
# WriteFix
#
# Copy over the original mrp file for the component that this problem
# occurs in to the patcharea, unless that has already been done.
# If the copy doesn't happen, create a new mrp file and add a component and
# notes_src line.
# Add the fix text to the new mrp file. In the case of '-source' which isn't
# supported, try to find the line with the source to be removed and comment
# it out.
#
sub WriteFix
    {
    my $self = shift;
    return unless( ref($self) );

    # Get component name.
    my $comp = $self->Component;

    # Mrpfile name. If new name is not defined, we just have a dirty component
    # that will be preprel'd only.
    my $oldmrp = $self->MrpFile;
    my $newmrp = $self->NewMrpFile;
    return unless( defined($newmrp) );

    # Do we have the nasty source missing case?
    my $source_missing=undef;
    if( defined($self->MrpFixText) )
        {
        my $firstfix = ${$self->MrpFixText}[0];
        if( $firstfix =~ m/-source\s+(.*)$/i )
            {
            shift @{$self->MrpFixText};
            $source_missing=$1;
            }
        }

    # Copy the old mrp over to the new location unless the new one already
    # exists, in which case this component actually lives here (e.g for
    # the binbag) or another fix object has already copied it.
    if ( (-f $oldmrp) && ($oldmrp ne $newmrp ) && (! (-f $newmrp)) )
        {
        File::Copy::copy( $oldmrp, $newmrp ) or print "CBRFIX COPY FAILED! Dollar bang is ", $!, "\n";
        my $mode = 0644; chmod $mode, $newmrp;
        open NEWMRP, ">> $newmrp" or print "Cannot append to $newmrp, dollar bang is '$!'\n";
        print NEWMRP "\n# Automatic CBR patches follow.\n" or print "Couldn't write to NEWMRP!\n";
        close NEWMRP;
        }

    # If this fix is to remove a superfluous source line, then read in the
    # file as it is and rewrite it. Perhaps one day '-source' might be
    # implemented.
    if($source_missing)
        {
        open MRP, $newmrp;
        my @oldmrparr = <MRP>;
        close MRP;
        open MRP, "> $newmrp";
        my @removedsource;
        for my $line (@oldmrparr)
            {
            if( $line =~ m/^\s*source\s+\Q$source_missing\E\s*$/i )
                {
                push @removedsource, "# AutoFIX CBR code removed the following line, the source seems to be missing.\n";
                push @removedsource, "# $line\n";
                next;
                }
            print MRP $line;
            }
        for my $line (@removedsource) { print MRP $line; }
        close MRP;
        }
       
    # The new mrp file should now exist. If it doesn't then add a
    # component and notes_src line to it. Should only happen for
    # the 'binbag' unresolved component.
    unless( -f $newmrp )
        {
        open NEWMRP, "> $newmrp";
        print NEWMRP "# Automatic CBR patching code generated this file..\n";
        print NEWMRP "component    $comp\n";
        print NEWMRP $self->NotesSrcLine;
        close NEWMRP;
        }

    #
    # Dirty the old MRP file so that next time a (hopefully good) build
    # happens the difference is spotted and the component is re-issued.
    #
    if( -f $oldmrp and ($oldmrp ne $newmrp) )
        {
        my $oldmrpmessage = "# AutoCBR repair code: This component has problems and has been patched.\n";
        open OLDMRP, $oldmrp;
        my @oldmrp = <OLDMRP>; close OLDMRP;
        unless( grep( /$oldmrpmessage/, @oldmrp ) )
            {
            open OLDMRP, ">> $oldmrp";
            print OLDMRP $oldmrpmessage;
            close OLDMRP;
            }
        }
    
    # Now add the extra 'fix' lines onto the new mrp file.
    if(ref($self->MrpFixText))
        {
        open NEWMRP, ">> $newmrp" or print "Couldn't open $newmrp\n";;
        for my $fixline (@ { $self->MrpFixText } )
            {
            print NEWMRP $fixline;
            }
        close NEWMRP;
        }
    else
        {
#            print "MrpFixText not a reference!!\n";
        }
    return;
    }
1;


