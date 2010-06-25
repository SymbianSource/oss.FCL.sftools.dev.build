#!perl
# Copyright (c) 2003-2009 Nokia Corporation and/or its subsidiary(-ies).
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

package GetEnv;

use strict;


#
# Public.
#

sub GetEnvFromRelData {
  my $iniData = shift;
  my $comp = shift;
  my $ver = shift;
  my $installSource = shift;
  my $sourceInstallPath = shift;
  my $overwriteSource = shift;
  my $removeSource = shift;
  my $verbose = shift;
  my $excludeComponents = shift;
  my $forceExclusion = shift;
  
  

  my $envDb = EnvDb->Open($iniData, $verbose);
  $iniData->PathData()->CheckReleaseExists($comp, $ver);

  print "Gathering environment information...\n";
  my $relData = RelData->Open($iniData, $comp, $ver, $verbose);
  my $env = $relData->Environment();
  GetEnv($iniData, $env, $installSource, $sourceInstallPath, $overwriteSource, $removeSource, $verbose, $excludeComponents, $forceExclusion);
}

sub GetEnv {
  my $iniData = shift;
  my $env = shift;
  my $installSource = shift;
  my $sourceInstallPath = shift;
  my $overwriteSource = shift;
  my $removeSource = shift;
  my $verbose = shift;
  my $excludeComponents = shift;
  my $forceExclusion = shift;

  my $envDb = EnvDb->Open($iniData, $verbose);
  my %compsToInstall;
  my %cleanComps;
  my @compsToRemove;
  
  
  # Edit the list of components if $excludeComponents is set
  if (defined $excludeComponents){
	  $env = FilterCompsToExclude($env, $excludeComponents, $verbose, $forceExclusion);
  }
  

  # Check the status of each component in the new environment.
  my $error = 0;
  foreach my $thisComp (sort keys %{$env}) {
    my $thisVer = $env->{$thisComp};
    $iniData->PathData()->CheckReleaseExists($thisComp, $thisVer);

    my $installedVer = $envDb->Version($thisComp);
    if (defined $installedVer) {
      if ($installedVer eq $thisVer) {
        # The requested version is already installed, so check its status.
        (my $status) = $envDb->CheckComp($thisComp);
        if ($status == EnvDb::STATUS_CLEAN) {
          # Do nothing.
          if ($verbose) { print "$thisComp $thisVer is already installed, and is clean\n"; }
          $cleanComps{$thisComp} = 1;
        }
        elsif ($status == EnvDb::STATUS_PENDING_RELEASE && !$overwriteSource) {
          print "Error: $thisComp is pending release\n";
          $error = 1;
        }
        elsif ($status == EnvDb::STATUS_DIRTY || $status == EnvDb::STATUS_DIRTY_SOURCE || $status == EnvDb::STATUS_PENDING_RELEASE) {
          if ($verbose) { print "$thisComp $thisVer is already installed, but is dirty\n"; }
          push (@compsToRemove, $thisComp);
          $compsToInstall{$thisComp} = $thisVer;
        }
        elsif ($status == EnvDb::STATUS_NOT_INSTALLED) {
          die;
        }
      }
      else {
        if ($envDb->Status($thisComp) == EnvDb::STATUS_PENDING_RELEASE && !$overwriteSource) {
          print "Error: $thisComp is pending release\n";
          $error = 1;
        }
        if ($verbose) { print "$thisComp $installedVer currently installed\n"; }
        push (@compsToRemove, $thisComp);
        $compsToInstall{$thisComp} = $thisVer;
      }
    }
    else {
      $compsToInstall{$thisComp} = $thisVer;
    }
  }

  if ($error) {
    die "\n";
  }

  # Add to the remove list components in the current environment that aren't in the new environment.
  my $currentEnv = $envDb->VersionInfo();
  foreach my $thisComp (keys %{$currentEnv}) {
    unless (exists $compsToInstall{$thisComp} or exists $cleanComps{$thisComp}) {
      (my $status) = $envDb->CheckComp($thisComp);
      if ($status == EnvDb::STATUS_CLEAN) {
	if ($verbose) { print "$thisComp currently installed (clean), but not in new environment - will be removed\n"; }
	push (@compsToRemove, $thisComp);
      }
      elsif ($status == EnvDb::STATUS_DIRTY || $status == EnvDb::STATUS_DIRTY_SOURCE) {
	if ($verbose) { print "$thisComp currently installed (dirty), but not in new environment - will be removed\n"; }
	push (@compsToRemove, $thisComp);
      }
      elsif ($status == EnvDb::STATUS_PENDING_RELEASE) {
	print "Warning: $thisComp is pending release - its binaries cannot be automatically removed.\n";
	print "         Continue with GetEnv? [y/n] ";
	my $response = <STDIN>;
	chomp $response;
	if (lc $response eq 'y') {
	  # Remove EnvDb entry.
	  my $ver = $envDb->Version($thisComp);
	  if (defined $ver) {
	    $envDb->DeleteSignature($thisComp, $ver);
	    $envDb->SetVersion($thisComp, undef);
	  }
	  else {
	    die;
	  }
	}
	else {
	  die "GetEnv aborted\n";
	}
      }
      elsif ($status == EnvDb::STATUS_NOT_INSTALLED) {
	die;
      }
    }
  }

  # Remove old binaries and source.
  foreach my $thisComp (@compsToRemove) {
    print "Removing $thisComp...\n";
    
    if ($removeSource) {
      $envDb->DeleteSource($thisComp, 0, 1);
    }
    
    $envDb->RemoveComponent($thisComp);
  }

  # Install new binaries (and possibly source).
  foreach my $thisComp (sort keys %compsToInstall) {
    my $thisVer = $compsToInstall{$thisComp};
    print "Installing $thisComp $thisVer...\n";
    $envDb->InstallComponent($thisComp, $thisVer, $overwriteSource);
    if ($installSource) {
      my $installPath = $sourceInstallPath;
      if (!defined ($installPath)) {
        $installPath="\\";
      }
      $envDb->UnpackSource($thisComp, $thisVer, $installPath, $overwriteSource, 1);
    }
  }
}


sub FilterCompsToExclude {
	my $editEnv = shift;
	my $excludeComp = lc (shift); 
	my $verbose = shift;
	my $forceExclusion = shift;
	my $editFlag = 0;
			
	print "Checking components to exclude...\n";
	
	if(-f $excludeComp) {			# file
		open FILE, "$excludeComp" or die "Unable to open exclude file $excludeComp - $!. Requested components for exclusion will not be excluded. ";
		
		while (<FILE>) {	
			if(ExcludeComp($_, $editEnv, $verbose) and ($editFlag == 0)){
				$editFlag = 1;
			}
		}				
	}
	else{							# single component name
		if(ExcludeComp($excludeComp, $editEnv, $verbose)){
			$editFlag = 1;
		}
	}	
	
	# Make user aware of what they are doing
	if(($editFlag) and not ($forceExclusion)){
		print "Are you happy to continue installing a Release with excluded components? - y/n\n";
		my $input = <STDIN>;
		unless($input =~ /^y$/i){
			die "Getenv aborted.\n";
		}	
	}	
	print "\n";	
	return $editEnv;
}


sub ExcludeComp{
	
	my $component = shift;
	my $env = shift;
	my $verbose = shift;
	my $editFlag = 0;

	chomp ($component);
	$component =~ s/\s+$//;
	$component =~ s/^\s+//;	
	$component = lc ($component);
	
	if($component =~ /^$/){					# empty string
	}
	elsif($component =~ /^[\w\.-]+\*$/){			# wild cards
		$component =~ s!([\w\.-]+)\*$!$1!;
		foreach my $comp (keys %{$env}){
			if($comp =~ /^\Q$component\E/){
				$editFlag = ExcludeComp($comp, $env, $verbose);
			}
		}
	}	
	elsif($component =~ /\*$/){
		print "$component - did not understand line - ignoring.\n";	# do nothing
	}			 
	elsif($component !~ /\s/){				# possible component name
		if (exists $$env{$component}){
			print "$component will be excluded from the new environment as requested.\n" if $verbose;				
			delete $$env{$component};
			$editFlag = 1;
		}
		else{
			print "$component is not in the archive so cannot exclude it from the new environment.\n" if $verbose;			
		}
	}
	else{
		print "'$component' contains spaces in its name - this is not a valid component name.\n";
	}	
	return $editFlag;
}

1;

__END__

=head1 NAME

GetEnv.pm - Provides an interface for installing and upgrading environments.

=head1 INTERFACE

=head2 GetEnv

Expects to be passed an C<IniData> reference, a reference to a hash containing the required component release versions, a flag indicating if to install source, a source install path (which may be undefined), a flag indicating if to overwrite source, a flag indicating whether there are components to be excluded or not and a verboisty level. Installs the specified component releases by adding, removing and upgrading existing components as required.

=head2 GetEnvFromRelData

Expects to be passed an C<IniData> reference, a component name, a version, a flag indicating if to install source, a source install path (which may be undefined), a flag indicating if to overwrite source, a flag indicating whether there are components to be excluded or not and a verboisty level. Retreives the version information associated with the specified component release version, and calls C<GetEnv> to install them.


=head1 KNOWN BUGS

None.

=head1 COPYRIGHT

 Copyright (c) 2003-2009 Nokia Corporation and/or its subsidiary(-ies).
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

__END__
