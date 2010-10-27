# Copyright (c) 2003-2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of "Eclipse Public License v1.0"
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

package GenBuild;

use strict;
use Carp;
use IO::File;

# Global Variables

my @components;
my $iIDCount;
my $iStageCount;
my %arm_assplist;
my $savespace="";
my $keepgoing="";
my $build_tools=0;
my $build_cwtools=0;
my $build_winc=0;
my $build_thumb=0;
my $build_armi=0;
my $build_arm4=0;
my $build_arm4t=0;
my $build_armv5=0;
my $build_arm3=0;
my $epoc_only=0;
my $build_winscw=0;
my $build_wins=0;
my $build_bootstrap;
my $basename;
my $iSourceDir;
my $build_UREL=0;
my $build_UDEB=0;
my $build_urel_udeb="";
my $build_test=0;

my ($XMLFileH, $gLogFileH);

my ($gHiResTimer) = 0; #Flag - true (1) if HiRes Timer module available

# Check if HiRes Timer is available
if (eval "require Time::HiRes;") {
  $gHiResTimer = 1;
} else {
  print "Cannot load HiResTimer Module\n";
}

sub Start
{
  my ($iDataSource, $iDataOutput, $iLogFile, $iSourceDir, $iReallyClean, $iClean) = @_;

  # Copied from genbuild.pl

  # Check for EPOCROOT
  # It's not used directly by GENBUILD, but this is a good early stage at which
  # to discover that it hasn't been set...

  my $epocroot = $ENV{EPOCROOT};
  die "ERROR: Must set the EPOCROOT environment variable\n" if (!defined($epocroot));
  $epocroot =~ s-/-\\-go;	# for those working with UNIX shells
  die "ERROR: EPOCROOT must not include a drive letter\n" if ($epocroot =~ /^.:/);
  die "ERROR: EPOCROOT must be an absolute path without a drive letter\n" if ($epocroot !~ /^\\/);
  die "ERROR: EPOCROOT must not be a UNC path\n" if ($epocroot =~ /^\\\\/);
  die "ERROR: EPOCROOT must end with a backslash\n" if ($epocroot !~ /\\$/);
  die "ERROR: EPOCROOT must specify an existing directory\n" if (!-d $epocroot);

  # $iSourceDir must en in a \
  # Add a \ if not present
  if ($iSourceDir !~ /\\$/)
  {
    $iSourceDir .= "\\";
  }

  for(my $j = 0; $j < scalar(@$iDataSource); $j++)
  {
    $GenBuild::basename .= " " if ($j > 0);
    my ($iFile) = @$iDataSource[$j] =~ m#.*([\\\/]|^)(.*?)\..*$#;
    $GenBuild::basename .= @$iDataSource[$j];
  }

  #Set the global iSourceDir
  $GenBuild::iSourceDir = $iSourceDir;

  # Open Log file
  $GenBuild::gLogFileH = IO::File->new("> $iLogFile")
    or croak "Couldn't open $iLogFile for writing: $!\n";

  print $GenBuild::gLogFileH "===-------------------------------------------------\n";
  print $GenBuild::gLogFileH "=== Genxml\n";
  print $GenBuild::gLogFileH "===-------------------------------------------------\n";
  print $GenBuild::gLogFileH "=== Genxml started ".localtime()."\n";

  for(my $j = 0; $j < scalar(@$iDataSource); $j++)
  {
    # Open DataSource
    my ($iFile) = @$iDataSource[$j];
    open FILE, "< $iFile" or die "Can't read $iFile\n";

    print $GenBuild::gLogFileH "=== Genxml == $iFile\n";

    print $GenBuild::gLogFileH "-- Genxml\n";
    # Add the per command start timestamp
    print $GenBuild::gLogFileH "++ Started at ".localtime()."\n";
    # Add the per command start HiRes timestamp if available
    if ($gHiResTimer == 1)
    {
      print $GenBuild::gLogFileH "+++ HiRes Start ".Time::HiRes::time()."\n";
    } else {
      # Add the HiRes timer missing statement
      print $GenBuild::gLogFileH "+++ HiRes Time Unavailable\n";
    }

    # Process the Txt file in the same manner as the old genbuild
    # Note:
    # Additional options 'udeb', 'urel' and 'test' were added in response 
    # to a specific request, but are not otherwise supported by Symbian.
    while (<FILE>)
    {
    s/\s*#.*$//;
    s/^\s*//;
    my $line = lc $_;
    if ($line =~ /^$/)
      {
      next;
      }

    if ($line =~ /<option (\w+)\s*(.*)>/)
      {
      my $option = $1;
      my $optargs= $2;
      if ($option =~ "savespace")
        {
        $GenBuild::savespace = "-savespace";
        next;
        }
      if ($option =~ "keepgoing")
        {
        $GenBuild::keepgoing = "-keepgoing";
        next;
        }
      if ($option =~ "tools")
        {
        $GenBuild::build_tools = 1;
        next;
        }
      if ($option eq "cwtools")
        {
        $GenBuild::build_cwtools = 1;
        next;
        }
      if ($option =~ "winc")
        {
        $GenBuild::build_winc = 1;
        next;
        }

      # Do not build winc, wins or winscw
      if ($option =~ "epoconly")
        {
        $GenBuild::build_winc = 0;
        $GenBuild::epoc_only = 1;
        next;
        }
      if ($option =~ "thumb")
        {
        $GenBuild::build_thumb = 1;
        next;
        }

      # ARMI option
      if ($option =~ "armi")
        {
        $GenBuild::build_armi = 1;
        next;
        }

      # ARM4
      if ($option eq "arm4")
        {
        $GenBuild::build_arm4 = 1;
        next;
        }

      # ARM4T
      if ($option eq "arm4t")
        {
        $GenBuild::build_arm4t = 1;
        next;
        }

      # ARMv5
      if ($option =~ "armv5")
        {
        $GenBuild::build_armv5 = 1;
        next;
        }

      if ($option =~ "arm3")
        {
        $GenBuild::build_arm3 = 1;
        next;
        }

      # Use Visual Studio
      if ($option eq "wins")
        {
        $GenBuild::build_wins = 1;
        next;
        }

      # Use CodeWarrior
      if ($option eq "winscw")
        {
        $GenBuild::build_winscw = 1;
        next;
        }

      if ($option eq "udeb") 
        {
        $GenBuild::build_UDEB = 1;
        next;
        }

      if ($option eq "urel") 
        {
        $GenBuild::build_UREL = 1;
        next;
        }

      if ($option eq "test") 
        {
        $GenBuild::build_test = 1;
        next;
        }

      if ($option =~ "arm_assp")
        {
        $GenBuild::arm_assplist{$optargs} = 1;
        next;
        }


      print "Option $1 not yet implemented\n";
      next;
      }
    if ($line =~ /^([^<]\S+)\s+(\S+)/)
    {
      if (!-e "$GenBuild::iSourceDir$2\\bld.inf")
      {
        print $GenBuild::gLogFileH "MISSING COMPONENT $1: can't find $GenBuild::iSourceDir$2\\bld.inf\n";
        next;
      }
    }
    if ($line =~ /<special bldfiles e32toolp group>/)
    {
      # Handle Special
      $GenBuild::build_bootstrap = 1;
      next;
    }

    push @GenBuild::components, $line;
    }

    close(FILE);
    # Add the per command end HiRes timestamp if available
    print $GenBuild::gLogFileH "+++ HiRes End ".Time::HiRes::time()."\n" if ($gHiResTimer == 1);
    # Add the per command end timestamp
    print $GenBuild::gLogFileH "++ Finished at ".localtime()."\n";
  }

  print $GenBuild::gLogFileH "=== Genxml == Output\n";

  print $GenBuild::gLogFileH "-- Genxml\n";
  # Add the per command start timestamp
  print $GenBuild::gLogFileH "++ Started at ".localtime()."\n";
  # Add the per command start HiRes timestamp if available
  if ($gHiResTimer == 1)
  {
    print $GenBuild::gLogFileH "+++ HiRes Start ".Time::HiRes::time()."\n";
  } else {
    # Add the HiRes timer missing statement
    print $GenBuild::gLogFileH "+++ HiRes Missing\n";
  }

  &PBuildLevels($iDataOutput);

  # Generate additional ReallyClean and Clean XML files if required
  &GenReallyClean($iReallyClean) if (defined $iReallyClean);
  &GenClean($iClean) if (defined $iClean);

  # Close file handles
  close($GenBuild::gLogFileH);

}

# PBuildLevels
#
# Inputs
# $iDataOutput - Filename for normal build xml
#
# Outputs
#
# Description
# This function generates a xml file to run normal buildon all components
sub PBuildLevels
{
  my ($iDataOutput) = @_;
  # Print the XML file
  $GenBuild::XMLFileH = IO::File->new("> $iDataOutput")
    or croak "Couldn't open $iDataOutput for writing: $!\n";

  $GenBuild::iIDCount = 1;
  $GenBuild::iStageCount = 1;

  my ($epocroot) = $ENV{'EPOCROOT'};

  &PrintXMLHeader($GenBuild::XMLFileH);

  if (($GenBuild::build_UREL) && (!$GenBuild::build_UDEB)) 
  {
	$GenBuild::build_urel_udeb = " UREL";
  }
  elsif ((!$GenBuild::build_UREL) && ($GenBuild::build_UDEB)) 
  {
	$GenBuild::build_urel_udeb = " UDEB";
  }

  if ($GenBuild::build_bootstrap)
  {
    # Do the BootStrapping
    # Temporary workaround for non-common code between old setup and Beech
    # Defaults to old setup
    # This will be removed when final functionality is added
    if ($ENV{'Platform'} eq 'beech')
    {
      print $GenBuild::XMLFileH qq{\t\t<Execute ID="$GenBuild::iIDCount" Stage="$GenBuild::iStageCount" Component="BootStrap" Cwd="$GenBuild::iSourceDir}.qq{beech\\generic\\tools\\e32toolp\\group" CommandLine="setupprj.bat"/>\n};
    } elsif ($ENV{'Platform'} eq 'cedar') {
      print $GenBuild::XMLFileH qq{\t\t<Execute ID="$GenBuild::iIDCount" Stage="$GenBuild::iStageCount" Component="BootStrap" Cwd="$GenBuild::iSourceDir}.qq{os\\buildtools\\sbsv1_os\\e32toolp\\group" CommandLine="setupprj.bat"/>\n};
    } else {
      print $GenBuild::XMLFileH qq{\t\t<Execute ID="$GenBuild::iIDCount" Stage="$GenBuild::iStageCount" Component="BootStrap" Cwd="$GenBuild::iSourceDir}.qq{tools\\e32toolp\\group" CommandLine="setupprj.bat"/>\n};
    }
    $GenBuild::iIDCount++;
    $GenBuild::iStageCount++;
    # Temporary workaround for non-common code between old setup and Beech
    # Defaults to old setup
    # This will be removed when final functionality is added
    if ($ENV{'Platform'} eq 'beech')
    {
      print $GenBuild::XMLFileH qq{\t\t<Execute ID="$GenBuild::iIDCount" Stage="$GenBuild::iStageCount" Component="BootStrap" Cwd="$GenBuild::iSourceDir}.qq{beech\\generic\\tools\\e32toolp\\group" CommandLine="bld.bat rel"/>\n};
    } elsif  ($ENV{'Platform'} eq 'cedar') {
      print $GenBuild::XMLFileH qq{\t\t<Execute ID="$GenBuild::iIDCount" Stage="$GenBuild::iStageCount" Component="BootStrap" Cwd="$GenBuild::iSourceDir}.qq{os\\buildtools\\sbsv1_os\\e32toolp\\group" CommandLine="bld.bat rel"/>\n};
    } else {
      print $GenBuild::XMLFileH qq{\t\t<Execute ID="$GenBuild::iIDCount" Stage="$GenBuild::iStageCount" Component="BootStrap" Cwd="$GenBuild::iSourceDir}.qq{tools\\e32toolp\\group" CommandLine="bld.bat rel"/>\n};
    }
    $GenBuild::iIDCount++;
    $GenBuild::iStageCount++;
  }

  &BuildLevels("0", "bldmake bldfiles $GenBuild::keepgoing");
  $GenBuild::iStageCount++;
  &BuildLevels("0", "abld export $GenBuild::keepgoing");
  &BuildLevels("0", "abld test export $GenBuild::keepgoing") if ($GenBuild::build_test);
  $GenBuild::iStageCount++;

  if ($GenBuild::build_tools)
  {
    &BuildLevels("0", "abld makefile $GenBuild::keepgoing $GenBuild::savespace", "tools");
    $GenBuild::iStageCount++;
    &BuildLevels("1", "abld library $GenBuild::keepgoing", "tools");
    &BuildLevels("1", "abld target $GenBuild::keepgoing $GenBuild::savespace", "tools", "rel");
    &BuildLevels("0", "abld -what build", "tools", "rel");
    &BuildLevels("0", "abld -check build", "tools", "rel");
    $GenBuild::iStageCount++;
  }

  if ($GenBuild::build_cwtools)
  {
    &BuildLevels("0", "abld makefile $GenBuild::keepgoing $GenBuild::savespace", "cwtools");
    $GenBuild::iStageCount++;
    &BuildLevels("1", "abld library $GenBuild::keepgoing", "cwtools");
    &BuildLevels("1", "abld target $GenBuild::keepgoing $GenBuild::savespace", "cwtools", "rel");
    &BuildLevels("0", "abld -what build", "cwtools", "rel");
    &BuildLevels("0", "abld -check build", "cwtools", "rel");
    $GenBuild::iStageCount++;
  }

  if ($GenBuild::build_winc)
  {
    &BuildLevels("0", "abld makefile $GenBuild::keepgoing $GenBuild::savespace", "winc");
    $GenBuild::iStageCount++;
    &BuildLevels("1", "abld library $GenBuild::keepgoing", "winc");
    &BuildLevels("1", "abld target $GenBuild::keepgoing $GenBuild::savespace", "winc");
    &BuildLevels("0", "abld -what build", "winc");
    &BuildLevels("0", "abld -check build", "winc");
    $GenBuild::iStageCount++;

  }

  unless ($epoc_only)
  {
    # Emulator things, WINS, up to resources
    if ($GenBuild::build_wins)
    {
      &BuildLevels("0", "abld makefile $GenBuild::keepgoing $GenBuild::savespace", "wins");
	  &BuildLevels("0", "abld test makefile $GenBuild::keepgoing $GenBuild::savespace", "wins") if ($GenBuild::build_test);
      $GenBuild::iStageCount++;
      &BuildLevels("1", "abld resource $GenBuild::keepgoing", "wins$GenBuild::build_urel_udeb");
	  &BuildLevels("1", "abld test resource $GenBuild::keepgoing", "wins$GenBuild::build_urel_udeb") if ($GenBuild::build_test);
      &BuildLevels("1", "abld library $GenBuild::keepgoing", "wins");
	  &BuildLevels("1", "abld test library $GenBuild::keepgoing", "wins") if ($GenBuild::build_test);
    }

    # Emulator things, WINSCW, up to resources
    if ($GenBuild::build_winscw)
    {
      &BuildLevels("0", "abld makefile $GenBuild::keepgoing $GenBuild::savespace", "winscw");
	  &BuildLevels("0", "abld test makefile $GenBuild::keepgoing $GenBuild::savespace", "winscw") if ($GenBuild::build_test);
      $GenBuild::iStageCount++;
      &BuildLevels("1", "abld resource $GenBuild::keepgoing", "winscw$GenBuild::build_urel_udeb");
	  &BuildLevels("1", "abld test resource $GenBuild::keepgoing", "winscw$GenBuild::build_urel_udeb") if ($GenBuild::build_test);
      &BuildLevels("1", "abld library $GenBuild::keepgoing", "winscw");
	  &BuildLevels("1", "abld test library $GenBuild::keepgoing", "winscw") if ($GenBuild::build_test);
    }
  }
  # Arm Stuff
  if ($GenBuild::build_arm4)
  {
    &BuildLevels("0", "abld makefile $GenBuild::keepgoing $GenBuild::savespace", "arm4");
	&BuildLevels("0", "abld test makefile $GenBuild::keepgoing $GenBuild::savespace", "arm4") if ($GenBuild::build_test);
    $GenBuild::iStageCount++;
  }
  if ($GenBuild::build_arm4t)
  {
    &BuildLevels("0", "abld makefile $GenBuild::keepgoing $GenBuild::savespace", "arm4t");
	&BuildLevels("0", "abld test makefile $GenBuild::keepgoing $GenBuild::savespace", "arm4t") if ($GenBuild::build_test);
    $GenBuild::iStageCount++;
  }
  if ($GenBuild::build_armv5)
  {
    &BuildLevels("0", "abld makefile $GenBuild::keepgoing $GenBuild::savespace", "armv5");
	&BuildLevels("0", "abld test makefile $GenBuild::keepgoing $GenBuild::savespace", "arm5") if ($GenBuild::build_test);
    $GenBuild::iStageCount++;
  }
  if ($GenBuild::build_armi)
  {
    &BuildLevels("0", "abld makefile $GenBuild::keepgoing $GenBuild::savespace", "armi");
	&BuildLevels("0", "abld test makefile $GenBuild::keepgoing $GenBuild::savespace", "armi") if ($GenBuild::build_test);
    $GenBuild::iStageCount++;
  }
  if ($GenBuild::build_thumb)
  {
    &BuildLevels("0", "abld makefile $GenBuild::keepgoing $GenBuild::savespace", "thumb");
	&BuildLevels("0", "abld test makefile $GenBuild::keepgoing $GenBuild::savespace", "thumb") if ($GenBuild::build_test);
    $GenBuild::iStageCount++;
  }
  if ($GenBuild::build_arm3)
  {
    &BuildLevels("0", "abld makefile $GenBuild::keepgoing $GenBuild::savespace", "arm3");
	&BuildLevels("0", "abld test makefile $GenBuild::keepgoing $GenBuild::savespace", "arm3") if ($GenBuild::build_test);
    $GenBuild::iStageCount++;
  }
  foreach my $iAssp (sort keys %GenBuild::arm_assplist)
  {
    &BuildLevels("0", "abld makefile $GenBuild::keepgoing $GenBuild::savespace", $iAssp);
	&BuildLevels("0", "abld test makefile $GenBuild::keepgoing $GenBuild::savespace", $iAssp) if ($GenBuild::build_test);
    $GenBuild::iStageCount++;
  }

  &BuildLevels("1", "abld resource $GenBuild::keepgoing", "arm4$GenBuild::build_urel_udeb") if ($GenBuild::build_arm4);
  &BuildLevels("1", "abld test resource $GenBuild::keepgoing", "arm4$GenBuild::build_urel_udeb") if (($GenBuild::build_arm4) && ($GenBuild::build_test));
  &BuildLevels("1", "abld resource $GenBuild::keepgoing", "arm4t$GenBuild::build_urel_udeb") if ($GenBuild::build_arm4t);
  &BuildLevels("1", "abld test resource $GenBuild::keepgoing", "arm4t$GenBuild::build_urel_udeb") if (($GenBuild::build_arm4t) && ($GenBuild::build_test));
  &BuildLevels("1", "abld resource $GenBuild::keepgoing", "armv5$GenBuild::build_urel_udeb") if ($GenBuild::build_armv5);
  &BuildLevels("1", "abld test resource $GenBuild::keepgoing", "armv5$GenBuild::build_urel_udeb") if (($GenBuild::build_armv5) && ($GenBuild::build_test));
  &BuildLevels("1", "abld resource $GenBuild::keepgoing", "armi$GenBuild::build_urel_udeb") if ($GenBuild::build_armi);
  &BuildLevels("1", "abld test resource $GenBuild::keepgoing", "armi$GenBuild::build_urel_udeb") if (($GenBuild::build_armi) && ($GenBuild::build_test));
  &BuildLevels("1", "abld resource $GenBuild::keepgoing", "thumb$GenBuild::build_urel_udeb") if ($GenBuild::build_thumb);
  &BuildLevels("1", "abld test resource $GenBuild::keepgoing", "thumb$GenBuild::build_urel_udeb") if (($GenBuild::build_thumb) && ($GenBuild::build_test));
  &BuildLevels("1", "abld resource $GenBuild::keepgoing", "arm3$GenBuild::build_urel_udeb") if ($GenBuild::build_arm3);
  &BuildLevels("1", "abld test resource $GenBuild::keepgoing", "arm3$GenBuild::build_urel_udeb") if (($GenBuild::build_arm3) && ($GenBuild::build_test));

  foreach my $iAssp (sort keys %GenBuild::arm_assplist)
  {
    &BuildLevels("1", "abld resource $GenBuild::keepgoing", "$iAssp$GenBuild::build_urel_udeb");
	&BuildLevels("1", "abld test resource $GenBuild::keepgoing", "$iAssp$GenBuild::build_urel_udeb") if ($GenBuild::build_test);
  }

  &BuildLevels("1", "abld library $GenBuild::keepgoing", "arm4") if ($GenBuild::build_arm4);
  &BuildLevels("1", "abld test library $GenBuild::keepgoing", "arm4") if (($GenBuild::build_arm4) &&($GenBuild::build_test));
  &BuildLevels("1", "abld library $GenBuild::keepgoing", "arm4t") if ($GenBuild::build_arm4t);
  &BuildLevels("1", "abld test library $GenBuild::keepgoing", "arm4t") if (($GenBuild::build_arm4t) && ($GenBuild::build_test));
  &BuildLevels("1", "abld library $GenBuild::keepgoing", "armv5") if ($GenBuild::build_armv5);
  &BuildLevels("1", "abld test library $GenBuild::keepgoing", "armv5") if (($GenBuild::build_armv5) && ($GenBuild::build_test));
  &BuildLevels("1", "abld library $GenBuild::keepgoing", "armi") if ($GenBuild::build_armi);
  &BuildLevels("1", "abld test library $GenBuild::keepgoing", "armi") if (($GenBuild::build_armi) && ($GenBuild::build_test));
  &BuildLevels("1", "abld library $GenBuild::keepgoing", "thumb") if ($GenBuild::build_thumb);
  &BuildLevels("1", "abld test library $GenBuild::keepgoing", "thumb") if (($GenBuild::build_thumb) && ($GenBuild::build_test));
  &BuildLevels("1", "abld library $GenBuild::keepgoing", "arm3") if ($GenBuild::build_arm3);
  &BuildLevels("1", "abld test library $GenBuild::keepgoing", "arm3") if (($GenBuild::build_arm3) && ($GenBuild::build_test));

  foreach my $iAssp (sort keys %GenBuild::arm_assplist)
  {
    &BuildLevels("1", "abld library $GenBuild::keepgoing", $iAssp);
	&BuildLevels("1", "abld test library $GenBuild::keepgoing", $iAssp) if ($GenBuild::build_test);
  }

  # Build all targets
  my @iTargets;
  # Push the defaults on
  push @iTargets, "wins$GenBuild::build_urel_udeb" if (($GenBuild::build_wins) && (!$GenBuild::epoc_only));
  push @iTargets, "arm4$GenBuild::build_urel_udeb" if ($GenBuild::build_arm4);
  push @iTargets, "arm4t$GenBuild::build_urel_udeb" if ($GenBuild::build_arm4t);
  push @iTargets, "armv5$GenBuild::build_urel_udeb"  if ($GenBuild::build_armv5);
  push @iTargets, "armi$GenBuild::build_urel_udeb" if ($GenBuild::build_armi);
  push @iTargets, "winscw$GenBuild::build_urel_udeb" if (($GenBuild::build_winscw) && (!$GenBuild::epoc_only));
  push @iTargets, "thumb$GenBuild::build_urel_udeb" if ($GenBuild::build_thumb);
  push @iTargets, "arm3$GenBuild::build_urel_udeb" if ($GenBuild::build_arm3);
  foreach my $iAssp (sort keys %GenBuild::arm_assplist)
  {
    push @iTargets, "$iAssp$GenBuild::build_urel_udeb";
  }
  &BuildTargets("0", "abld target $GenBuild::keepgoing $GenBuild::savespace", @iTargets);
  &BuildTargets("0", "abld test target $GenBuild::keepgoing $GenBuild::savespace", @iTargets) if ($GenBuild::build_test);

  unless ($epoc_only)
  {
    if ($GenBuild::build_wins)
    {
      # Final Part of WINS
      &BuildLevels("1", "abld final $GenBuild::keepgoing", "wins","$GenBuild::build_urel_udeb");
	  &BuildLevels("1", "abld test final $GenBuild::keepgoing", "wins","$GenBuild::build_urel_udeb") if ($GenBuild::build_test);
      &BuildLevels("0", "abld -what build", "wins","$GenBuild::build_urel_udeb");
	  &BuildLevels("0", "abld test -what build", "wins","$GenBuild::build_urel_udeb") if ($GenBuild::build_test);
      $GenBuild::iStageCount++;
      &BuildLevels("0", "abld -check build", "wins","$GenBuild::build_urel_udeb");
	  &BuildLevels("0", "abld test -check build", "wins","$GenBuild::build_urel_udeb") if ($GenBuild::build_test);
      $GenBuild::iStageCount++;
    }

    if ($GenBuild::build_winscw)
    {
      # Final Part of WINSCW
      &BuildLevels("1", "abld final $GenBuild::keepgoing", "winscw$GenBuild::build_urel_udeb");
	  &BuildLevels("1", "abld test final $GenBuild::keepgoing", "winscw$GenBuild::build_urel_udeb") if ($GenBuild::build_test);
      &BuildLevels("0", "abld -what build", "winscw$GenBuild::build_urel_udeb");
	  &BuildLevels("0", "abld test -what build", "winscw$GenBuild::build_urel_udeb") if ($GenBuild::build_test);
      $GenBuild::iStageCount++;
      &BuildLevels("0", "abld -check build", "winscw$GenBuild::build_urel_udeb");
	  &BuildLevels("0", "abld test -check build", "winscw$GenBuild::build_urel_udeb") if ($GenBuild::build_test);
      $GenBuild::iStageCount++;
    }
  }

  # Other Final Parts
  &BuildLevels("1", "abld final $GenBuild::keepgoing", "arm4$GenBuild::build_urel_udeb") if ($GenBuild::build_arm4);
  &BuildLevels("1", "abld test final $GenBuild::keepgoing", "arm4$GenBuild::build_urel_udeb") if (($GenBuild::build_arm4) && ($GenBuild::build_test));
  &BuildLevels("1", "abld final $GenBuild::keepgoing", "arm4t$GenBuild::build_urel_udeb") if ($GenBuild::build_arm4t);
  &BuildLevels("1", "abld test final $GenBuild::keepgoing", "arm4t$GenBuild::build_urel_udeb") if (($GenBuild::build_arm4t) && ($GenBuild::build_test));
  &BuildLevels("1", "abld final $GenBuild::keepgoing", "armv5$GenBuild::build_urel_udeb") if ($GenBuild::build_armv5);
  &BuildLevels("1", "abld test final $GenBuild::keepgoing", "armv5$GenBuild::build_urel_udeb") if (($GenBuild::build_armv5) && ($GenBuild::build_test));
  &BuildLevels("1", "abld final $GenBuild::keepgoing", "armi$GenBuild::build_urel_udeb") if ($GenBuild::build_armi);
  &BuildLevels("1", "abld test final $GenBuild::keepgoing", "armi$GenBuild::build_urel_udeb") if (($GenBuild::build_armi) && ($GenBuild::build_test));
  &BuildLevels("1", "abld final $GenBuild::keepgoing", "thumb$GenBuild::build_urel_udeb") if ($GenBuild::build_thumb);
  &BuildLevels("1", "abld test final $GenBuild::keepgoing", "thumb$GenBuild::build_urel_udeb") if (($GenBuild::build_thumb) && ($GenBuild::build_test));
  &BuildLevels("1", "abld final $GenBuild::keepgoing", "arm3$GenBuild::build_urel_udeb") if ($GenBuild::build_arm3);
  &BuildLevels("1", "abld test final $GenBuild::keepgoing", "arm3$GenBuild::build_urel_udeb") if (($GenBuild::build_arm3) && ($GenBuild::build_test));
  foreach my $iAssp (sort keys %GenBuild::arm_assplist)
  {
    &BuildLevels("1", "abld final $GenBuild::keepgoing", $iAssp);
	&BuildLevels("1", "abld test final $GenBuild::keepgoing", $iAssp) if ($GenBuild::build_test);
  }

  &BuildLevels("0", "abld -what build", "arm4$GenBuild::build_urel_udeb") if ($GenBuild::build_arm4);
  &BuildLevels("0", "abld test -what build", "arm4$GenBuild::build_urel_udeb") if (($GenBuild::build_arm4) && ($GenBuild::build_test));
  &BuildLevels("0", "abld -what build", "arm4t$GenBuild::build_urel_udeb") if ($GenBuild::build_arm4t);
  &BuildLevels("0", "abld test -what build", "arm4t$GenBuild::build_urel_udeb") if (($GenBuild::build_arm4t) && ($GenBuild::build_test));
  &BuildLevels("0", "abld -what build", "armv5$GenBuild::build_urel_udeb") if ($GenBuild::build_armv5);
  &BuildLevels("0", "abld test -what build", "armv5$GenBuild::build_urel_udeb") if (($GenBuild::build_armv5) && ($GenBuild::build_test));
  &BuildLevels("0", "abld -what build", "armi$GenBuild::build_urel_udeb") if ($GenBuild::build_armi);
  &BuildLevels("0", "abld test -what build", "armi$GenBuild::build_urel_udeb") if (($GenBuild::build_armi) && ($GenBuild::build_test));
  &BuildLevels("0", "abld -what build", "thumb$GenBuild::build_urel_udeb") if ($GenBuild::build_thumb);
  &BuildLevels("0", "abld test -what build", "thumb$GenBuild::build_urel_udeb") if (($GenBuild::build_thumb) && ($GenBuild::build_test));
  &BuildLevels("0", "abld -what build", "arm3$GenBuild::build_urel_udeb") if ($GenBuild::build_arm3);
  &BuildLevels("0", "abld test -what build", "arm3$GenBuild::build_urel_udeb") if (($GenBuild::build_arm3) && ($GenBuild::build_test));

  foreach my $iAssp (sort keys %GenBuild::arm_assplist)
  {
    &BuildLevels("0", "abld -what build", $iAssp);
	&BuildLevels("0", "abld test -what build", $iAssp) if ($GenBuild::build_test);
  }
  $GenBuild::iStageCount++;

  &BuildLevels("0", "abld -check build", "arm4$GenBuild::build_urel_udeb") if ($GenBuild::build_arm4);
  &BuildLevels("0", "abld test -check build", "arm4$GenBuild::build_urel_udeb") if (($GenBuild::build_arm4) && ($GenBuild::build_test));
  &BuildLevels("0", "abld -check build", "arm4t$GenBuild::build_urel_udeb") if ($GenBuild::build_arm4t);
  &BuildLevels("0", "abld test -check build", "arm4t$GenBuild::build_urel_udeb") if (($GenBuild::build_arm4t) && ($GenBuild::build_test));
  &BuildLevels("0", "abld -check build", "armv5$GenBuild::build_urel_udeb") if ($GenBuild::build_armv5);  
  &BuildLevels("0", "abld test -check build", "armv5$GenBuild::build_urel_udeb") if (($GenBuild::build_armv5) && ($GenBuild::build_test));
  &BuildLevels("0", "abld -check build", "armi$GenBuild::build_urel_udeb") if ($GenBuild::build_armi);  
  &BuildLevels("0", "abld test -check build", "armi$GenBuild::build_urel_udeb") if (($GenBuild::build_armi) && ($GenBuild::build_test));
  &BuildLevels("0", "abld -check build", "thumb$GenBuild::build_urel_udeb") if ($GenBuild::build_thumb);
  &BuildLevels("0", "abld test -check build", "thumb$GenBuild::build_urel_udeb") if (($GenBuild::build_thumb) && ($GenBuild::build_test));
  &BuildLevels("0", "abld -check build", "arm3$GenBuild::build_urel_udeb") if ($GenBuild::build_arm3);
  &BuildLevels("0", "abld test -check build", "arm3$GenBuild::build_urel_udeb") if (($GenBuild::build_arm3) && ($GenBuild::build_test));

  foreach my $iAssp (sort keys %GenBuild::arm_assplist)
  {
    &BuildLevels("0", "abld -check build", $iAssp);
	&BuildLevels("0", "abld test -check build", $iAssp) if ($GenBuild::build_test);
  }

  # Print the XML Footer
  print $GenBuild::XMLFileH qq{\t</Commands>\n</Product>};

  # Add the per command end HiRes timestamp if available
  print $GenBuild::gLogFileH "+++ HiRes End ".Time::HiRes::time()."\n" if ($gHiResTimer == 1);
  # Add the per command end timestamp
  print $GenBuild::gLogFileH "++ Finished at ".localtime()."\n";

  # Print Genxml log footer
  print $GenBuild::gLogFileH "=== Genxml finished ".localtime()."\n";

  # Close XML File
  close($GenBuild::XMLFileH);
}

sub BuildLevels
{
  my ($iIncStage, $action, $arg1, $arg2, $arg3) = @_;

  for(my $j = 0; $j < scalar(@GenBuild::components); $j++)
  {
    my $line = $GenBuild::components[$j];
    my @MyList;
    my $tempvar;

    @MyList = split(/\s+/,$line);
    $tempvar= lc $MyList[$#MyList];
    $tempvar =~ s/\\group//;
    push @MyList, $tempvar;

    print $GenBuild::XMLFileH qq{\t\t<Execute ID="$GenBuild::iIDCount" Stage="$GenBuild::iStageCount" Component="$MyList[2]" Cwd="$GenBuild::iSourceDir$MyList[1]" CommandLine="$action $arg1 $arg2 $arg3"/>\n};
    $GenBuild::iIDCount++;

    if ( $iIncStage )
    {
      $GenBuild::iStageCount++;
    }
  }

}

sub BuildTargets
{
  my ($iIncStage, $action, @iTargets) = @_;


  for(my $j = 0; $j < scalar(@GenBuild::components); $j++)
  {
    my $line = $GenBuild::components[$j];
    my @MyList;
    my $tempvar;

    @MyList = split(/\s+/,$line);
    $tempvar= lc $MyList[$#MyList];
    $tempvar =~ s/\\group//;
    push @MyList, $tempvar;

    # Process target list
    foreach my $iTarget (@iTargets)
    {
      print $GenBuild::XMLFileH qq{\t\t<Execute ID="$GenBuild::iIDCount" Stage="$GenBuild::iStageCount" Component="$MyList[2]" Cwd="$GenBuild::iSourceDir$MyList[1]" CommandLine="$action $iTarget"/>\n};
      $GenBuild::iIDCount++;
    }
    if ( $iIncStage )
    {
      $GenBuild::iStageCount++;
    }
  }
  $GenBuild::iStageCount++ if (!$iIncStage);

}

# GenReallyClean
#
# Inputs
# $iReallyClean - Filename for reallyclean xml
#
# Outputs
#
# Description
# This function generates a xml file to run abld reallyclean on all components
sub GenReallyClean
{
  my ($iReallyClean) = @_;

  # Reset ID and Stage Counf for New XML File
  $GenBuild::iIDCount = 1;
  $GenBuild::iStageCount = 1;


  # Add the section header
  print $GenBuild::gLogFileH "=== Genxml == ReallyClean\n";

  print $GenBuild::gLogFileH "-- Genxml\n";
  # Add the per command start timestamp
  print $GenBuild::gLogFileH "++ Started at ".localtime()."\n";
  # Add the per command start HiRes timestamp if available
  if ($gHiResTimer == 1)
  {
    print $GenBuild::gLogFileH "+++ HiRes Start ".Time::HiRes::time()."\n";
  } else {
    # Add the HiRes timer missing statement
    print $GenBuild::gLogFileH "+++ HiRes Missing\n";
  }

  # Open XML file
  $GenBuild::XMLFileH = IO::File->new("> $iReallyClean")
    or croak "Couldn't open $iReallyClean for writing: $!\n";

  # Write Header
  &PrintXMLHeader($GenBuild::XMLFileH);
  # Generate XML file
  &BuildLevels("0", "abld reallyclean");
  # Write Footer and Close XML File
  print $GenBuild::XMLFileH qq{\t</Commands>\n</Product>};
  close($GenBuild::XMLFileH);


  # Add the per command end HiRes timestamp if available
  print $GenBuild::gLogFileH "+++ HiRes End ".Time::HiRes::time()."\n" if ($gHiResTimer == 1);
  # Add the per command end timestamp
  print $GenBuild::gLogFileH "++ Finished at ".localtime()."\n";

  # Print Genxml log footer
  print $GenBuild::gLogFileH "=== Genxml finished ".localtime()."\n";
}

# GenClean
#
# Inputs
# $iClean - Filename for reallyclean xml
#
# Outputs
#
# Description
# This function generates a xml file to run abld reallyclean on all components
sub GenClean
{
  my ($iClean) = @_;

  # Reset ID and Stage Counf for New XML File
  $GenBuild::iIDCount = 1;
  $GenBuild::iStageCount = 1;

  # Add the section header
  print $GenBuild::gLogFileH "=== Genxml == Clean\n";

  print $GenBuild::gLogFileH "-- Genxml\n";
  # Add the per command start timestamp
  print $GenBuild::gLogFileH "++ Started at ".localtime()."\n";
  # Add the per command start HiRes timestamp if available
  if ($gHiResTimer == 1)
  {
    print $GenBuild::gLogFileH "+++ HiRes Start ".Time::HiRes::time()."\n";
  } else {
    # Add the HiRes timer missing statement
    print $GenBuild::gLogFileH "+++ HiRes Missing\n";
  }

  # Open XML file
  $GenBuild::XMLFileH = IO::File->new("> $iClean")
    or croak "Couldn't open $iClean for writing: $!\n";

  # Write Header
  &PrintXMLHeader($GenBuild::XMLFileH);
  # Generate XML file
  &BuildLevels("0", "abld clean");

  # Write Footer and Close XML File
  print $GenBuild::XMLFileH qq{\t</Commands>\n</Product>};
  close($GenBuild::XMLFileH);


  # Add the per command end HiRes timestamp if available
  print $GenBuild::gLogFileH "+++ HiRes End ".Time::HiRes::time()."\n" if ($gHiResTimer == 1);
  # Add the per command end timestamp
  print $GenBuild::gLogFileH "++ Finished at ".localtime()."\n";

  # Print Genxml log footer
  print $GenBuild::gLogFileH "=== Genxml finished ".localtime()."\n";
}

# PrintXMLHeader
#
# Inputs
# $iFileHandle
#
# Outputs
#
# Description
# This function print the common start of the XML File
sub PrintXMLHeader
{
  my ($iFileHandle) = @_;

  my ($epocroot) = $ENV{'EPOCROOT'};

  # Print the XML Header
  print $iFileHandle qq{<?xml version="1.0"?>\n};
  print $iFileHandle <<DTD_EOF;
<!DOCTYPE Build  [
  <!ELEMENT Product (Commands)>
  <!ATTLIST Product name CDATA #REQUIRED>
  <!ELEMENT Commands (Execute+ | SetEnv*)>
  <!ELEMENT Execute EMPTY>
  <!ATTLIST Execute ID CDATA #REQUIRED>
  <!ATTLIST Execute Stage CDATA #REQUIRED>
  <!ATTLIST Execute Component CDATA #REQUIRED>
  <!ATTLIST Execute Cwd CDATA #REQUIRED>
  <!ATTLIST Execute CommandLine CDATA #REQUIRED>
  <!ELEMENT SetEnv EMPTY>
  <!ATTLIST SetEnv Order ID #REQUIRED>
  <!ATTLIST SetEnv Name CDATA #REQUIRED>
  <!ATTLIST SetEnv Value CDATA #REQUIRED>
]>
DTD_EOF
  print $iFileHandle qq{<Product Name="$GenBuild::basename">\n\t<Commands>\n};

  #Set EPOCROOT
  print $iFileHandle qq{\t\t<SetEnv Order="1" Name="EPOCROOT" Value="$epocroot"/>\n};

  #Add Tools to the path using EPOCROOT
  print $iFileHandle qq{\t\t<SetEnv Order="2" Name="PATH" Value="}.$epocroot.qq{epoc32\\gcc\\bin;}.$epocroot.qq{epoc32\\tools;%PATH%"/>\n};

}
1;
