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
# CBRPatch
# Contains code to patch a CBR to hopefully allow a CBR to be published
# but this version appended with '_PATCHED' (or whatever you choose) for the
# bad components.
# 
#

package CBRPatch;
use strict;
use File::Basename;
use File::Path;

use CBRFix;
use CBRProblem;

#
# new
#
# Create a new CBRPatch object.
#
sub new
    {
    my($arg, $options, $inidat, $envdb, $version, $iversion, $patcharea,
       $unrescomp, $patchver_suffix, $attempts ) = @_;
    my $class = ref($arg) ? ref($arg) : $arg;

    my $self = {  
                     options => $options,
                      inidat => $inidat,
                       envdb => $envdb,
                     version => $version,
                    iversion => $iversion,
                   patcharea => $patcharea,
                   unrescomp => $unrescomp,
             patchver_suffix => $patchver_suffix,
                    attempts => $attempts,

                 cbrproblems => undef,
                ncbrproblems => undef,
                    cbrfixes => undef,
               envinfooutput => undef,
                 baseversion => undef,
              };

    bless $self, $class;

    return $self;
    }

sub IniData
    {
    my $self = shift;
    my $newinidat = shift;
    $self->{inidat} = $newinidat if( defined($newinidat) );
    return $self->{inidat} if( defined($self->{inidat}) );
    $self->{inidat} = IniData->New();
    return $self->{inidat};
    }
sub EnvDb
    {
    my $self = shift;
    my $newenvdb = shift;
    $self->{envdb} = $newenvdb if( defined($newenvdb) );
    return $self->{envdb} if( defined($self->{envdb}) );
    $self->{envdb} = EnvDb->Open($self->IniData);
    return $self->{envdb};
    }
sub Version
    {
    my $self = shift;
    my $newversion = shift;
    $self->{version} = $newversion if( defined($newversion) );
    return $self->{version} if( defined($self->{version}) );
    $self->{baseversion} = $self->EnvDb->Version("gt_techview_baseline")
        unless(defined($self->{baseversion}));
    $self->{version} = $self->{baseversion} .  $self->PatchVerSuffix;
    return $self->{version};
    }
sub Iversion
    {
    my $self = shift;
    my $newiversion = shift;
    $self->{iversion} = $newiversion if( defined($newiversion) );
    return $self->{iversion} if( defined($self->{iversion}) );
    $self->{iversion} = $self->EnvDb->InternalVersion("gt_techview_baseline") .
                            $self->PatchVerSuffix;
    return $self->{iversion};
    }
sub PatchArea
    {
    my $self = shift;
    my $newpatcharea = shift;
    $self->{patcharea} = lc($newpatcharea) if( defined($newpatcharea) );
    $self->{patcharea} = "\\component_defs\\patches"
                                 unless( defined($self->{patcharea}) );
    File::Path::mkpath($self->{patcharea}) unless( -d $self->{patcharea} );
    my $dpol = $self->{patcharea} . "/distribution.policy";
    unless( -f $dpol )
        {
        open DP, "> $dpol";
        print DP "Category E\nOSD:	Test/Reference	Tools\n";
        close DP;
        }
    return $self->{patcharea};
    }
sub UnresComp
    {
    my $self = shift;
    my $newunrescomp = shift;
    $self->{unrescomp} = $newunrescomp if( defined($newunrescomp) );
    return $self->{unrescomp} if( defined($self->{unrescomp}) );
    $self->{unrescomp} = "unresolved";
    return $self->{unrescomp};
    }
sub PatchVerSuffix
    {
    my $self = shift;
    my $newpvs = shift;
    $self->{patchver_suffix} = $newpvs if( defined($newpvs) );
    return $self->{patchver_suffix} if( defined($self->{patchver_suffix}) );
    $self->{patchver_suffix} = "_PATCHED";
    return $self->{patchver_suffix};
    }
sub Attempts
    {
    my $self = shift;
    my $newattempts = shift;
    $self->{attempts} = $newattempts if( defined($newattempts) );
    return $self->{attempts} if( defined($self->{attempts}) );
    $self->{attempts} = 3;
    return $self->{attempts};
    }

#
# Runs envinfo if there is an argument or if it hasn't been run inside
# this object before.
# Always uses the '-ffv' options. This is fixed because other code depends
# on the format of the output. Returns a reference to an array containing
# the output.
#
sub EnvinfoOutput
    {
    my $self = shift;
    my $arg = shift;
    return $self->{envinfooutput}
          if( !defined($arg) && defined($self->{envinfooutput}) );

    $self->Print("INFO: Running 'envinfo -ffv'....\n");
    my @arr;
    unless(open ENVINFO, "envinfo -ffv 2>&1 |")
        {
        # Don't to a $self->Error here, CCheckEnv knows what to do with this..
        push @arr, "ERROR: Failed to run envinfo.\n";
        return \@arr;
        }
    @arr = <ENVINFO>;
    $self->{envinfooutput} = \@arr;

    undef($self->{cbrproblems}); # We've rerun envinfo, so any old results
    undef($self->{cbrfixes});    # here are garbage.
    return $self->{envinfooutput};
    }
sub ProvideEnvinfoOutput
    {
    my $self = shift;
    my $arg = shift;                # MUST be a reference to an array!
    $self->{envinfooutput} = $arg;
    undef($self->{cbrproblems}); # New envinfo data, so any old results
    undef($self->{cbrfixes});    # here are garbage.
    return $self->{envinfooutput};
    }
    
#
# CBRProblems
#
# Re-determines problems if there is an argument. Does
# NOT trigger re-run of envinfo. If its been run before this would
# just use the old data.
#
sub CBRProblems
    {
    my $self = shift;
    my $arg = shift;
    my @missinglist;
    return $self->{cbrproblems}
          if( !defined($arg) && defined($self->{cbrproblems}) );

    # Rats. We have to work out what the problems are.
    undef($self->{cbrproblems});
    undef($self->{cbrfixes});
    $self->{ncbrproblems} = 0;
    for my $ev (@{$self->EnvinfoOutput})
        {
        #
        # Check for files that have no known origin. We'll call
        # these 'orphans'.
        #
        if( $ev =~ m/^(\S+): (.+) has unknown origin/)
            {
            my $path = $2;
            my $prob = CBRProblem->new($path, "orphan");
            push @{$self->{cbrproblems}}, $prob;
            $self->{ncbrproblems}++;
            $self->Error("CBRPatch: Orphan file '$path' detected.\n");
            next;
            }

        #
        # Now check for files that are multiply owned.
        #
        if( $ev =~ m/^(\S+):\s+(\S+) attempting to release (\S+) which has already been released by (\S+)/)
            {
            my $comp1 = $2;
            my $path = $3;
            my $comp2 = $4;
            my %hsh = ( $comp1 => 1,   # Hash of components with problem.
                        $comp2 => 1, );

            my $prob = CBRProblem->new($path, "multi", \%hsh );
            push @{$self->{cbrproblems}}, $prob;
            $self->{ncbrproblems}++;
            $self->{options}->Component($comp1);
            $self->Error("CBRPatch: Multi-owned file '$path' detected, owned by $comp1 and $comp2.\n");
            next;
            }

        #
        # Now look for files that are absent, i.e referenced by
        # component(s) but don't exist.
        #
        if( $ev =~ m/^(\S+)\s+(\S+)\s+(\S+)\s+missing$/ )  #
            {
            my $comp = $1;
            my $path = $3;
            my %hsh = ( $comp => 1 );
            my $prob = CBRProblem->new($path, "absent", \%hsh );
            push @{$self->{cbrproblems}}, $prob;
            $self->{ncbrproblems}++;
            $self->{options}->Component($comp);
            $self->Error("CBRPatch: Absent file '$path' detected, owned by $comp. (missing)\n");
            next;
            }
        if( $ev =~ m/^(\S+): Error: \"?(.*?)\"? does not exist/ )
            {
            my $comp = $1;
            my $path = $2;
            my %hsh = ( $comp => 1 );
            my $prob = CBRProblem->new($path, "absent", \%hsh );
            push @{$self->{cbrproblems}}, $prob;
            $self->{ncbrproblems}++;
            $self->{options}->Component($comp);
            $self->Error("CBRPatch: Absent file '$path' detected, owned by $comp.(does not exist)\n");
            next;
            }
        if( $ev =~ m/^Error: \"?(.*?)\"? does not exist/ )
            {
            # One of these ghastly cases where we get a bunch of 'does not
            # exist' errors followed by a 'Multiple errors' warning. We must
            # stack up the missing paths until we hit a 'multiple errors'.
            my $path = $1;
            push @missinglist, $path;
            next;
            }
        if( $ev =~ m/^(\S+): Multiple errors \(first - Error: .*? does not exist\)/ )
            {
            # We've got the multiple errors line. Now create all of the problem
            # objects for this component.
            my $comp = $1;
            for my $path (@missinglist)
                {
                my %hsh = ( $comp => 1 );
                my $prob = CBRProblem->new($path, "absent", \%hsh );
                push @{$self->{cbrproblems}}, $prob;
                $self->{ncbrproblems}++;
                }
            $self->{options}->Component($comp);    
            $self->Error("CBRPatch: Multiple files (" . scalar(@missinglist) . ") owned by $comp do not exist.\n");
            @missinglist = ();
            next;
            }

        #
        # Last, check for failures where a component is dirty for some other
        # reason. This will just trigger a preprel on this component, nothing
        # more.
        #
        if( $ev =~ m/^(\S+)\s+(\S+)\s+(.+)\s+failed\scheck$/ )
            {
            my $comp1 = $1;
            my $ver = $2;
            my $path = $3;
            my %hsh = ( $comp1 => 1 );  # Hash of components with problem.
            $self->{options}->Component($comp1);
            $self->{options}->Print($ev);
            my $prob = CBRProblem->new($path, "dirty", \%hsh );
            push @{$self->{cbrproblems}}, $prob;
            $self->{ncbrproblems}++;
            next;
            }

        }

    return $self->{cbrproblems}
    }

#
# CBRFixes
#
# Works out what fixes are required (and places them in the internal
# array 'cbrfixes') to fix the problems in the internal array 'cbrproblems'.
# This uses the accessor 'CBRProblems', so this can indirectly trigger
# a run of the CBRProblems code, which itself can trigger a run of
# envinfo.
#
# Currently self->{cbrfixes} is a reference to an array. It occurs to
# me that if I made this a reference to a hash with keys being component
# names, and content being arrays of cbrfix's some processing could be simpler.
#
sub CBRFixes
    {
    my $self = shift;
    my $arg = shift;

    # If no argument is passed and the fixes have already been worked
    # out, just return them.
    return($self->{cbrfixes}) if( defined($self->{cbrfixes}) &&
                                  !defined($arg) );

    my $probref = $self->CBRProblems; # Get the list of problems.
    if( $self->{ncbrproblems} == 0 )
        {
        $self->Print("INFO: There are no detected problems in the CBR.\n");
        undef($self->{cbrfixes});
        return $self->{cbrfixes};
        }
    #
    # There are some problems. 
    # For each problem, generate the fixes and stick them in our
    # array of fixes.
    #
    for my $cbrprob (@$probref)
        {
        my @thesefixes = @{$cbrprob->GetFixes($self->IniData,
                                              $self->EnvDb,
                                              $self->PatchArea,
                                              $self->UnresComp)};
        push @{$self->{cbrfixes}}, @thesefixes;
        }
    # If there are any fixes then we will also need to preprel the baseline.
    # The baseline name should probably not be hardwired, but this was a late
    # change.
    if($self->{cbrfixes})
        {
        my $baselinefix = CBRFix->new( "gt_techview_baseline", undef,
                                        undef, undef );
        push @{$self->{cbrfixes}}, $baselinefix;
        }

    
    return $self->{cbrfixes};
    }

#
# ImplementFixes
#
# Get whatever fixes are required and implement them, including the preprel.
# Only do one iteration though. Re-run the envinfo/problem/fix generation
# cycle when complete, 'cos we're going to need to know if there is more
# trouble.
#
sub ImplementFixes
    {
    my $self = shift;

    my %comps;
    # Define the fixes that need doing.
    my $fixes = $self->CBRFixes;
    my $nfixes = scalar(@$fixes);
    # Return immediately if there is nothing to fix.
    return 0 unless($nfixes);

    # Make sure that no old copies of mrp files are lying around in the
    # patcharea. Basically this deletes ANYTHING that isn't an mrp file
    # owned by a component in the current environment. Too brutal?
    $self->CleanPatchArea;
    
    $self->Print("REMARK: There are " . scalar(@$fixes) . " fixes.\n");
    for my $fix (@$fixes)
        {
        $self->Print("REMARK: Patching component '" . $fix->Component . "'\n")
            unless( defined($comps{$fix->Component}) );
        $fix->WriteFix;

        # Only preprel the component if it hasn't been preprel'd to the
        # location this fix wants. NewMrpFile won't be defined if this is
        # a 'preprel' only fix (which comes up if a component is dirty
        # but doesn't have multiply owned or missing files).
        my $mrp = $fix->NewMrpFile;
        $mrp = $fix->MrpFile unless(defined($mrp));
        if( !defined($comps{$fix->Component}) or
                                ($mrp ne $comps{$fix->Component}) )
            {
            $comps{$fix->Component} = $mrp; # Record the current location.
            my $prepline = "preprel ";
            # The mrp file may be unchanged. Only use -m if necessary.
            $prepline .= "-m " . $fix->NewMrpFile
                if( defined($fix->NewMrpFile) );
            my $vver = $self->Version;
	    $vver = $self->{baseversion}
                if(lc($fix->Component) eq "gt_techview_baseline" );
            $prepline .= " " .
                    $fix->Component . " " .
                    $vver  . " " .
                    $self->Iversion;
            $self->Print("REMARK: Running '$prepline'\n");
            system($prepline);
            }
        }
    # There could well be further problems. For example, some components
    # generate temporary files when e.g abld export -what is run, so
    # another patch cycle may be required. The following lines re-run
    # envinfo and regenerate the problem and fixes arrays.
    $self->EnvinfoOutput(1);
    $self->CBRFixes; # Above trashes problem and fix arrays, this regens them

    # How many fixes did we write?
    return $nfixes;
    }

#
# Run 'ImplementFixes' a maximum of attempts times. Returns the number of
# problems that remain.
#
sub FixCBR
    {
    my $self=shift;

    for(1..$self->Attempts)
        {
        $self->Print("REMARK: Running CBR Patch code. Iteration number $_.\n");
        my $nfixes = $self->ImplementFixes;
        if( $nfixes == 0 )
            {
            $self->Print("REMARK: No CBR Patches were required.\n");
            last;
            }

        # Get the problems. We didn't have to do this here, the
        # ImplementFixes on the next iteration would trigger it anyway
        # if there are more problems, but nice to exit here if we're fixed.
        my $probref = $self->CBRProblems;
        
        $self->{options}->Component('CBRPatch: Miscellaneous');
        
        unless($self->{ncbrproblems})
            {
            $self->Print("REMARK: No further problems with CBR detected. Patch complete.\n");
            last;
            }

        }
    if( $self->{ncbrproblems} != 0 )
        {
        $self->Print("REMARK: " . $self->{ncbrproblems} .  " CBR problems remain!\n");
        }
    return( $self->{ncbrproblems} );
    }

#
# CleanPatchArea
#
# Delete all mrp files in the patch area that are not in the current
# environment.
#
sub CleanPatchArea
    {
    my $self = shift;
    my $versinfo = $self->EnvDb->VersionInfo;
    my %mrps;
    # Build a list of mrp files in the current environment.
    for(keys %$versinfo)
        {
        my $comp = $_;
        my $mrp = lc($self->EnvDb->MrpName($comp));
        $mrp = "\\" . $mrp unless( $mrp =~ m/^\\/ );
        $mrps{$mrp} = 1;
        }

    for my $file (glob($self->PatchArea . "\\*.mrp") )
        {
        $file = lc($file);
        $file =~ s!\/!\\!g;
        $file = "\\" . $file unless( $file =~ m/^\\/ );
        unless( defined($mrps{$file} ) )
            {
            $self->Print("REMARK: Deleting file '$file' from patcharea.\n");
            unlink $file;
            }
        }
    }
sub Print # Should we concatenate multiple args? With a list only first prints
    {
    my $self = shift;
    return unless ref($self);

    if( ref($self->{options} ) )
        {
        $self->{options}->Print(@_) 
        }
        else
        {
        print @_, "\n";
        }
    return;
    }
sub Error # Should we concatenate multiple args? With a list only first prints
    {
    my $self = shift;
    return unless ref($self);
    if( ref( $self->{options} ) )
        {
        $self->{options}->Error(@_);
        }
    else
        {
        print @_, "\n";
        }
    return;
    }

1;


