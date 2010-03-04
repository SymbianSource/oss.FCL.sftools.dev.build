# This file is part of Nokia EC Tools release
#
#============================================================================ 
#Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
#All rights reserved.
#This component and the accompanying materials are made available
#under the terms of the License "Eclipse Public License v1.0"
#which accompanies this distribution, and is available
#at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
#Initial Contributors:
#Nokia Corporation - initial contribution.
#
#Contributors:
#
#Description: 
# 
#==============================================================================

my $version=35;

# 35 2008-09-26 jaakpaak:ou1tools#2679 Changed copyright symbol. Two days to go and I'm off to Atomia. Have fun.
# 34 2008-09-23 jaakpaak:ou1tools#2677 Added command line options to revert to "make" instead of anything else for selected commands
# 33 2008-09-19 jaakpaak:ou1tools#2673 Added copyright notice
# 32 2008-09-11 jaakpaak:ou1tools#2661 Changed abld what and abld check targets to always use "make" in MAKE variable
# 31 2008-09-03 jaakpaak:ou1tools#2627 Added creation of *-other-files.txt and *-other.zip
# 30 2008-08-05 jaakpaak:ou1tools#2610 Add quoting of direct to file operator >
# 29 2008-07-17 jaakpaak:ou1tools#2611 Get rid of symbian tool chain patching for emake
# 28 2008-07-07 jaakpaak:ou1tools#2607 sysdef2make.pl to generate correct makefile independent of the location where the script is located
# 27 2008-07-01 jaakpaak:ou1tools#2604 -n configuration option to sysdef2make to make it generate only configuration specific makefile
# 26 2008-05-23 jaakpaak:ou1tools#2566 Improve output warnings and errors to be symbian compatible
# 25 2008-03-26 jaakpaak:ou1tools#2531 Fix the output for log processor to be more compatible with EBS, increased quoting for special characters
# 24 2008-03-13 jaakpaak:ou1tools#2522 Fix for last special instruction missing
# 23 2008-03-07 jaakpaak:ou1tools#2516 Fix for buildLayer instructions which are executed twice
# 22 2008-03-03 jaakpaak:ou1tools#2511 Targets for creating zip files from your workarea
# 21 2008-02-29 jaakpaak:ou1tools#2510 Do not overwrite configuration-task targets targets with layer-task targets, printing of filters
# 20 2008-02-28 jaakpaak:ou1tools#2495 Fix for specialInstruction dependencies and build time loggin dependencies
# 19 2007-12-20 jaakpaak:ou1tools#2440 Fix for unitlists containing white spaces
# 18 2007-12-17 jaakpaak:ou1tools#2432 Restructured variables, quoted echoing of command line
# 17 2007-11-29 jaakpaak:ou1tools#2427 Fix to layer names containing white spaces, prefix also to specialInstructions
# 16 2007-11-15 jaakpaak:ou1tools#2420 Fixed issue with multiple filters and empty unit lists
# 15 2007-11-15 jaakpaak:ou1tools#2408 Added configuration-UNITS variable and optionless generic component rules
# 14 2007-11-12 jaakpaak:ou1tools#2407 Added warning to layers not having any units
# 13 2007-11-09 jaakpaak:ou1tools#2405 Fix to layers
# 12 2007-10-31 jaakpaak:ou1tools#2402 Added -s option for path prefix and priorities
# 11 2007-10-18 jaakpaak:ou1tools#2356 Fixed problems with filters and buildtime logging
# 10 2007-10-18 jaakpaak:ou1tools#2356 Fixed dependency problems on EC, made everyting unit based (previously bld.inf based)
# 09 2007-09-07 jaakpaak:ou1tools#2351 Added build time logging
# 08 2007-09-01 jaakpaak:ou1tools#2340 Added error ignoring for selected commands and -v option
# 07 2007-08-23 jaakpaak:ou1tools#2320 Submaked execution
# 06 2007-08-15 jaakpaak:ou1tools#2311 Removed printing of empty unit lists, timestamp as perl script, makefiled unitlist/layernames
# 05 2007-08-08 jaakpaak:ou1tools#2291 Added -filter option for user defined filters
# 04 2007-08-07 jaakpaak:ou1tools#2290 Added tags for scanlog to specialInstructions also
# 03 2007-07-04 jaakpaak:ou1tools#2275 htmlscanlog compatibility fixes
# 02 2007-07-03 jaakpaak:ou1tools#2274 fixed specialInstructions handling
# 01 2007-06-29 jaakpaak:ou1tools#2273 abldOption also valid for bldmake commands

my $scriptDir=$0;
# Strip the file from the path
$scriptDir =~ s{[^\\\/]*$}{};

use lib "$ENV{EPOCROOT}epoc32/tools/build/lib";
use XML::DOM;

my @userFilters = ();
my @forceMakeCommands = ("abld.*\-(w|what|c|check|checkwhat|cw)[^a-zA-Z0-9]");
my $file = "";
my $pathPrefix = "";

my @userConfigurations = ();
my @configurations = ();
my $makefileName = "makefile";
my $makefileOption = "";
my $i=0;

while ( $i < scalar (@ARGV) ) {
	if ( $ARGV[$i] eq "-filter" ) {
		push( @userFilters, $ARGV[$i+1] );
		$i += 2;
	} elsif ( $ARGV[$i] eq "-forcemake" ) {
		push( @forceMakeCommands, $ARGV[$i+1] );
		$i += 2;
	} elsif ( $ARGV[$i] eq "-s" ) {
		$pathPrefix = $ARGV[$i+1];
		$i += 2;
	} elsif ( $ARGV[$i] eq "-n" ) {
		push( @configurations, $ARGV[$i+1] );
		$i += 2;
	} else {
		$file = $ARGV[$i];
		$i++;
	}
}
my $otherCommandLineOptions;

my $i=1;
while ( $i < scalar(@forceMakeCommands) ) {
    $otherCommandLineOptions.="-forcemake \"".quoteCommandForEcho($forceMakeCommands[$i])."\" ";
    $i++;
}


if ( @configurations ) {
    push(@userConfigurations,@configurations);
    $makefileName = join("_",@configurations).".make";
} 
open(MAKEFILE,"> $makefileName");


my $parser = XML::DOM::Parser->new();

my $doc = $parser->parsefile($file);


# Commands which' errors will be ignored 
my %ignoreErrorCommands = ( "mkdir" => 1,
                            "md" => 1,
                            "del" => 1,
                            "rmdir" => 1,
                            "echo" => 1,
                            "rem" => 1,
                            "xcopy" => 1,
                            "dir" => 1 );
                            
# Hash containing unitID's and bldFiles.
# Keys are unitID's
my %bldFiles;

# Hash containing the units of each layer and unitlist
# Key is the name of list, value is a list of unitId.s
# The bldFile has to be obtained from unitIDs
my %units;

# Hash containing the actual abldTarget's of the command line. 
# The key is the name of the target in System Definition xml
my %targets;

# Hash containing arrays of the real abldTarget's 
# Key is the name defined in targetList in system definition xml
my %targetLists;

# Hash containing the default unitlists of each configuration
# Key is the name of the configuration
my %unitLists;

# Hash containing contents of each specialInstruction
# Key is the makefile target name of each specialInstruction
# Value is the command line including cd part
my %specialInstructions;

# The bldfiles which are excluded from each configuration
my %excludedUnits;

# Hash containing the makefile targets for each task
# Key is the task as a makefile target and values is a hash of buildlayer task
my %buildLayerTasks;


# So you cannot execute _any_ buildLayer command for _any_ unitList or layer
# The combination must exist also in system definition xml

# $unitId -> filterhash
my %unitFilters;

# List of all filters set in units
my %filters;

# Priorities of each unit
# unitId -> priority
my %unitPriorities;

# Configuration makefile rules
my %configurationTasks = ();

my %optionNames;
my %options;

# Set verbose option on manually
push( @{$options{abldOption}},"VERBOSE");
push( @{$options{bldmakeOption}},"VERBOSE");
$optionNames{"VERBOSE"} = "-v";

# Loop through all the layers
foreach my $layer ( $doc->getElementsByTagName('layer') ) {
    my $layerName = $layer->getAttribute('name');

    # Loop through all the units in the layer
    foreach my $unit ( $layer->getElementsByTagName('unit') ) {
        my $unitID = $unit->getAttribute('unitID');
        my $bldFile = $unit->getAttribute('bldFile');
        my $priority = $unit->getAttribute('priority');

        # Set the filter status
        $unitFilters{$unitID} = $unit->getAttribute('filter');

        # Set filters to global hash
        foreach my $word ( split(/,/,$unitFilters{$unitID}) ) {
            $word =~ s{^!}{};
            $filters{$word} = 1;
        }
        
        if ( $pathPrefix &&
             $bldFile !~ m{^\Q$pathPrefix\E}i ) {
            $bldFile = $pathPrefix.$bldFile;
        }
        if (-d $bldFile) {
	        # Set bldFile to the unitID
    	    $bldFiles{$unitID} = $bldFile;
        } else {
            print(STDERR "ERROR: could not find $bldFile.\n");
            next;
        }

        # Set the default priority
        if ( ! $priority ) {
            $priority = 1000;
        }
        
        $unitPriorities{$unitID} = $priority;
        
        # Set the bldfile to the unitlist
        my $i = scalar(@{$units{$layerName}});
        while ( $i > 0 ) {
            my $prevUnit = $units{$layerName}[$i-1];
                
            if ( $unitPriorities{$prevUnit} <= $unitPriorities{$unitID}  ) {
                last;
            } else {
                $i--;
            }           
        }
        # Insert init to slot $i
        splice( @{$units{$layerName}},$i,0,$unitID);
    }
}

# Loop through all unitLists
foreach my $unitList ( $doc->getElementsByTagName('unitList') ) {
	my $unitListName = $unitList->getAttribute('name');

	# Loop through all unitRefs inside the unitLiss
	foreach my $unitRef ( $unitList->getElementsByTagName('unitRef') ) {
		my $unitID = $unitRef->getAttribute('unit');

		# Set the bldfile to the unitlist
		if ( $bldFiles{$unitID} ) {
			
			my $i = scalar(@{$units{$unitListName}});
			while ( $i > 0 ) {
				my $prevUnit = $units{$unitListName}[$i-1];
				
				if ( $unitPriorities{$prevUnit} <= $unitPriorities{$unitID}  ) {
					last;
				} else {
					$i--;
				}			
			}
            # Insert init to slot $i
			splice( @{$units{$unitListName}},$i,0,$unitID);
		} else {
			print(STDERR "ERROR: unitList by the name \"".$unitListName."\" has unitRef to \"".$unitID."\" which is not defined.\n");
		}
	}
}

# Get targets from the whole SystemDefinition.xml
foreach my $target ( $doc->getElementsByTagName('target') ) {
	my $targetName = $target->getAttribute('name');
	my $abldTarget = $target->getAttribute('abldTarget');

	$targets{$targetName} = $abldTarget;
}


# Get targetLists
foreach my $targetList ( $doc->getElementsByTagName('targetList') ) {
	my $name = $targetList->getAttribute('name');
	my $targetString = $targetList->getAttribute('target');

	foreach my $target ( split( /\s+/, $targetString ) ) {
		push( @{$targetLists{$name}}, $targets{$target} )
	}
}

# Get options
foreach my $option ( $doc->getElementsByTagName('option') ) 
# Loop through all option elements
{
	my $attributes = $option->getAttributes();
	my $i = 0;

	my %attributeHash;
	
	while ( $i < $attributes->getLength() ) 
	# go through all attributes
	{
		my $item = $attributes->item($i);
		# Get name and value for each item in option attributes
		my $name = $item->getName();
		my $value = $item->getValue();
		
		# Insert attribute value into hash by key as name
		$attributeHash{$name} = $value;
		$i++;
	}

	foreach my $key ( keys(%attributeHash) ) 
	# Go through generated attribute hash
	{
		if ( $key =~ m{.*Option} && $attributeHash{'enable'} =~ m{y}i ) 
		# Attribute key is somethingOption and it is enabled
		{
			# Set options hash
			$optionNames{$attributeHash{"name"}} = $attributeHash{$key};
			
			push( @{$options{$key}}, $attributeHash{"name"} );

			# abldOptions become bldmakeOptions
			# bldMake only supports -keepgoing and -verbose options
			if ( $key eq "abldOption" && 
				 ( $attributeHash{$key} =~ /^\s*-k/i ||
				   $attributeHash{$key} =~ /^\s*-v/i )) {
				push( @{$options{bldmakeOption}}, $attributeHash{"name"} );
			}
		}
	}
}


my @xmlConfigurations = ();
# This loop digs out unitlists, layers and tasks from each configuration
foreach my $xmlConfiguration ( $doc->getElementsByTagName('configuration') ) {
    my $configurationName = $xmlConfiguration->getAttribute('name');

    # Store all configurations to a list
    push( @xmlConfigurations, $configurationName );

    # Check we are not using configuration name which overlaps with unit list name
    foreach my $layer ( keys(%units)) {
        if ( lc($layer) eq lc($configurationName) ) {
            print(STDERR "ERROR: Configuration \"$configurationName\" is defined also as unitList/layer \"$layer\". Names MUST BE UNIQUE!\n");
            last;
        }
    }
    my $taskId=1;

    # Get the filters of the configuration
    my @configurationFilters = split( /,/, $xmlConfiguration->getAttribute('filter') );

    # Add user specified filters to current configuration
    push( @configurationFilters, @userFilters );

    # Get the first child of the configuration
    my $xmlElement = $xmlConfiguration->getFirstChild();

    # This variable keeps track when specialInstruction changes 
    # by storing the name of the current specialInstruction
    my %currentSpecialInstruction=();

    do { 
        my $tagName = $xmlElement->getNodeName();

        # Both unitListRef and layerRef end up to same place; unitLists hash
        # From makefile point of view they have no difference what so ever
        if ( $tagName eq "unitListRef" || 
            $tagName eq "layerRef" ) {
            my $unitList;

            if ( $tagName eq "unitListRef" ) {
                $unitList = $xmlElement->getAttribute('unitList'); 
            } else {
                $unitList = $xmlElement->getAttribute('layerName');
            }

            if ( scalar(@{$units{$unitList}}) == 0 ) {
                print(STDERR "WARNING: unit list \"$unitList\" included to configuration \"$configurationName\" has no units.\n");
            } else {
                # Go through bldfiles and check their filters
                foreach my $unit ( @{$units{$unitList}} ) {
                    my $i = 0;
                    my $exclude = check_filter( $unitFilters{$unit}, \@configurationFilters);
                    
                       
                    if ( $exclude )
                    # If there was an exclusion filter, exclude
                    # If bldfile had filters set but include filter was not among them, exclude
                    {
                        push( @{$excludedUnits{$configurationName}}, $unit );
                    }
                }
            }
            # Add the new unitlist to current configuration
            push( @{$unitLists{$configurationName}}, $unitList );
        }

        if ( $tagName eq "task" ) {
            # The unitlists applied for the current task
            my @taskUnitLists=();

            # First get possible task specific unitListRefs
            foreach my $xmlUnitListRef ( $xmlElement->getElementsByTagName('unitListRef') ) {
                push( @taskUnitLists, $xmlUnitListRef->getAttribute('unitList') );
            }

            my $xmlTask = $xmlElement->getFirstChild();
            do {
                my $taskType = $xmlTask->getNodeName();

                # For specialInstructions we only need the name
                # This is because the content in specialInstructions is determined later
                if ( $taskType eq "specialInstructions" ) {
                    my $name = $xmlTask->getAttribute('name');

                    if ( $name ne $currentSpecialInstruction{specialInstruction} ) 
                    # The specialInstruction has just changed
                    {
                        if ( $currentSpecialInstruction{specialInstruction} ) 
                        # but it's not the first one
                        {
                            # Store the previous special instruction
                            my %configurationTask = %currentSpecialInstruction;
                            push( @{$configurationTasks{$configurationName}}, \%configurationTask );

                            # And clear up for next one
                            %currentSpecialInstruction = ();
                        }
                        $currentSpecialInstruction{specialInstruction} = $name;
                        $currentSpecialInstruction{taskId} = $taskId++;
                    } 
                     
                    my $cwd = $xmlTask->getAttribute('cwd');
                    my $command = quoteCommand($xmlTask->getAttribute('command'));

                    if ( $cwd ne "." ) {
                        $command = "cd ".$cwd." && ".$command." ";
                    }

                    if ( $ignoreErrorCommands{getExecutable($command)} ) 
                    # Command is listed as "ignore error" command
                    {
                        $command = "-".$command;
                    } 
                    push( @{$currentSpecialInstruction{commands}}, $command );
                } 

                if ( $taskType eq "buildLayer" ) {
                    if ( $currentSpecialInstruction{specialInstruction} ) 
                    # Last task was a specialInstruction
                    {
                        # Store the previous special instruction
                        my %configurationTask = %currentSpecialInstruction;
                        push( @{$configurationTasks{$configurationName}}, \%configurationTask );
                    }
                    # And clear up for next one
                    %currentSpecialInstruction = ();

                    # Set command and targets
                    my $targetList = $xmlTask->getAttribute('targetList');
                    my @targets = @{$targetLists{$targetList}};
                    my $command = $xmlTask->getAttribute('command');
                    my $executable = getExecutable($command);

                    my $option;
                    # abldOption specified, append makefile variable to command
                    # you can screw up what check and export by defining wrong options

                    # We are ignoring the fact that abld export doesnt work with all possible
                    # options. 
                    # It is more important to relay the -keepgoing to abld export
                    # than try to protect the environment from user who uses abldOption wrong
                    if ( @{$options{$executable.'Option'}} &&
                         $command !~ m{abld.*\-(w|what|c|check|checkwhat|cw)\s}i ) {
                        $option =" \$(".$executable."Option)";
                    }

                    if ( ! @targets ) {
                        my %configurationTask;
                        $configurationTask{executable} = $executable;
                        $configurationTask{command} = quoteCommand($command);
                        $configurationTask{option} = $option;

                        if ( @taskUnitLists ) {
                            $configurationTask{unitLists} = \@taskUnitLists;
                        } else {
                            if ( ! @{$unitLists{$configurationName}} ) {
                                print(STDERR "Warning: buildLayer task \"".$command."\" in configuration \"".$configurationName."\" does not contain any units.\n");
                            }
                        }
                        $configurationTask{taskId} = $taskId++;

                        push( @{$configurationTasks{$configurationName}},\%configurationTask );

                    } else {
                        foreach my $target ( @targets ) {
                            my %configurationTask;

                            # Append the target to the command
                            $configurationTask{executable} = $executable;
                            $configurationTask{command} = quoteCommand($command);
                            $configurationTask{option} = $option;
                            $configurationTask{target} = $target;

                            if ( @taskUnitLists ) {
                                $configurationTask{unitLists} = \@taskUnitLists;
                            } elsif ( ! @{$unitLists{$configurationName}} ) {
                                print(STDERR "Warning: buildLayer task \"".$command."\" in configuration \"".$configurationName."\" does not contain any units.\n");
                            }
                            $configurationTask{taskId} = $taskId++;

                            push( @{$configurationTasks{$configurationName}},\%configurationTask );
                        }
                    }
                }
            } while ( $xmlTask = $xmlTask->getNextSibling() ) ;
        }
    } while ( $xmlElement = $xmlElement->getNextSibling() ) ;

    if ( $currentSpecialInstruction{specialInstruction} ) 
    # Last task was a specialInstruction
    {
        # Store the previous special instruction
        my %configurationTask = %currentSpecialInstruction;
        push( @{$configurationTasks{$configurationName}}, \%configurationTask );
    }
    # And clear up for next one
    %currentSpecialInstruction = ();
}


# If no configuration specified on command line, use all configurations collected from xml
if ( ! @configurations ) {
    push(@configurations,@xmlConfigurations);
}

# Print help

print(MAKEFILE "\# Set the script directory\n");
print(MAKEFILE "\# The directory is trailed with a space to\n");
print(MAKEFILE "\# prevent continuing line side effects of trailing backslash\n");
print(MAKEFILE "\# We need strip to remove the trailing space.\n");
print(MAKEFILE "SCRIPTDIR:=$scriptDir \n\n");
print(MAKEFILE "SCRIPTDIR:=\$(strip \$(SCRIPTDIR))\n\n");
print(MAKEFILE "# Export MAKE variable in order to abld.pl to see it\n");
print(MAKEFILE "export MAKE\n\n");

print(MAKEFILE "SYSTEMDEFINITIONXML:=".$file."\n\n");

if ( @userFilters ) {
    print(MAKEFILE "FILTERS:=".join(" ",@userFilters)."\n\n");
}

if ( @userConfigurations )
# User configuration was set on command line
{
    print(MAKEFILE "CONFIGURATION=$userConfigurations[0]\n\n");
    print(MAKEFILE "export CONFIGURATION\n\n");
    # Set the configuration as default target
    print(MAKEFILE "\$(CONFIGURATION):\n\n");
}

# Print out options
print(MAKEFILE "# Option names\n");

foreach my $optionName ( keys(%optionNames) ) {
	print(MAKEFILE "$optionName := ".$optionNames{$optionName}." \n");
}
print(MAKEFILE "\n");

print(MAKEFILE "# command options\n");
foreach my $cmdOption ( keys(%options)) {
	print(MAKEFILE $cmdOption." := ");
	foreach my $optionName ( @{$options{$cmdOption}} ) {
		print(MAKEFILE "\$\($optionName\) ");
	}
	print(MAKEFILE "\n");
}
print(MAKEFILE "\n");

if ( $makefileName ne "makefile" ) {
    print(MAKEFILE "CURRENT_MAKEFILE:=$makefileName\n");
}

if ( $otherCommandLineOptions ) {
    print(MAKEFILE "SYSDEF2MAKEFLAGS:=$otherCommandLineOptions\n\n");
}

print(MAKEFILE ".PHONY : help\n");
print(MAKEFILE "help:\n");
print(MAKEFILE "\t\@cmd /c echo.\n");
print(MAKEFILE "\t\@echo This is a makefile \$(CURRENT_MAKEFILE) created by sysdef2make.pl version $version with command line:\n");
print(MAKEFILE "\t\@echo  perl \$(SCRIPTDIR)sysdef2make.pl \$(addprefix -filter ,\$(FILTERS)) \$(addprefix -n ,\$(CONFIGURATION)) \$(SYSDEF2MAKEFLAGS) \$(SYSTEMDEFINITIONXML)\n");
print(MAKEFILE "\t\@cmd /c echo.\n");
if ( scalar(@userFilters) ) {
	print(MAKEFILE "\t\@echo User defined filters added to all configurations: ".join(" ",@userFilters)."\n\n");
}
print(MAKEFILE "\t\@cmd /c echo.\n");
print(MAKEFILE "\t\@echo To start up (hopefully) helpful web page, type:\n");
print(MAKEFILE "\t\@echo  make \$(addprefix -f ,\$(CURRENT_MAKEFILE)) nethelp\n");
print(MAKEFILE "\t\@cmd /c echo.\n");
print(MAKEFILE "\t\@echo To get a list of all the buildable configurations:\n");
print(MAKEFILE "\t\@echo  make \$(addprefix -f ,\$(CURRENT_MAKEFILE)) configurations\n");
print(MAKEFILE "\t\@cmd /c echo.\n");
print(MAKEFILE "\t\@echo To get a list of all the executable special instructions:\n");
print(MAKEFILE "\t\@echo  make \$(addprefix -f ,\$(CURRENT_MAKEFILE)) specialInstructions\n");
print(MAKEFILE "\t\@cmd /c echo.\n");
print(MAKEFILE "\t\@echo Any of the previous configurations or specialInstructions\n");
print(MAKEFILE "\t\@echo can be executed as they are by adding the name after make.\n");
print(MAKEFILE "\t\@cmd /c echo.\n");
print(MAKEFILE "\t\@echo To get a list of tasks executable for any component\n");
print(MAKEFILE "\t\@echo  make \$(addprefix -f ,\$(CURRENT_MAKEFILE)) tasks\n");
print(MAKEFILE "\t\@cmd /c echo.\n");
print(MAKEFILE "\t\@echo Components and tasks are combined with\n");
print(MAKEFILE "\t\@echo  make \$(addprefix -f ,\$(CURRENT_MAKEFILE)) \[component\]-\[task\]\n");
print(MAKEFILE "\t\@cmd /c echo.\n");
print(MAKEFILE "\t\@echo For instance:\n");
print(MAKEFILE "\t\@echo  make s60\\yourcomponent\\group-task\n");
print(MAKEFILE "\t\@cmd /c echo.\n");
print(MAKEFILE "\t\@cmd /c echo.\n");
print(MAKEFILE "\t\@echo Any amount of configurations, special instructions and\n");
print(MAKEFILE "\t\@echo component-task combinations can be combined on one command line.\n");
print(MAKEFILE "\t\@cmd /c echo.\n");
print(MAKEFILE "\t\@echo Instead of make you can use any gnu make compatible framework like emake.\n");
print(MAKEFILE "\t\@cmd /c echo.\n");
print(MAKEFILE "\t\@echo To get more information about the gnu make options google \"gnu make manual\"\n");
print(MAKEFILE "\t\@echo or type \"make --help\"\n\n");

print(MAKEFILE ".PHONY : nethelp\n\n");
print(MAKEFILE "nethelp : \n");
print(MAKEFILE "\tcmd /c \"start http://s60wiki/S60Wiki/Sysdef2make\"\n\n");

print(MAKEFILE "# Printing out messsages\n");
print(MAKEFILE ".PHONY : \%-print\n\n");
print(MAKEFILE "\%-print : \n\t\@echo \$\*\n\n");

print(MAKEFILE "\n");
print(MAKEFILE "\%.html : \%.log\n");
print(MAKEFILE "\t\@-del \$\@\n");
print(MAKEFILE "\tperl -S htmlscanlog.pl -l \$\< -o \$\@ -v -v\n\n");

print(MAKEFILE "define STARTTASK\n");
print(MAKEFILE "\@echo === \$(CONFIGURATION) == \$\*\n");
print(MAKEFILE "\t\@echo -- \$\(1\) \n");
print(MAKEFILE "\t-\@perl -e \"print '++ Started at '.localtime().\\\"\\n\\\"\"\n");
print(MAKEFILE "\t-\@python -c \"import time; print '+++ HiRes Start ',time.time();\"\n");
print(MAKEFILE "endef\n\n");


print(MAKEFILE "define ENDTASK\n");
print(MAKEFILE "\t\-\@python -c \"import time; print '+++ HiRes End ',time.time();\"\n");
print(MAKEFILE "\t-\@perl -e \"print '++ Finished at '.localtime().\\\"\\n\\\"\"\n");
print(MAKEFILE "endef\n\n");

print(MAKEFILE "# Rule for starting up a configuration\n");
print(MAKEFILE ".PHONY : timestart.txt\n\n");
print(MAKEFILE "timestart.txt \:\n");
print(MAKEFILE "\t\@echo ===-------------------------------------------------\n");
print(MAKEFILE "\t\@echo === \$\(CONFIGURATION)\n");
print(MAKEFILE "\t\@echo ===-------------------------------------------------\n");
print(MAKEFILE "\t\@\-perl -e \"print '=== \$(CONFIGURATION) started '.localtime().\\\"\\n\\\"\"\n");
print(MAKEFILE "\t\@\-perl -e \"print time\" \> \$\@\n");
print(MAKEFILE "\n\n");

print(MAKEFILE "define LOGBUILDTIME\n");
print(MAKEFILE "\-\(echo \$(CONFIGURATION)\$(CONFIGURATIONSUFFIX) \& type \$\< \) \| perl \$(SCRIPTDIR)send_data.pl\n");
print(MAKEFILE "endef\n\n");

print(MAKEFILE "# Do not delete generated \*-files.txt files afterwards\n");
print(MAKEFILE ".PRECIOUS : \%-files.txt\n\n");

print(MAKEFILE "# ... unless there was an error generating \*-files.txt file, the delete it\n");
print(MAKEFILE ".DELETE_ON_ERROR : \%-files.txt\n\n");


print(MAKEFILE "\%-otherfiles.txt : %-files.txt\n");
print(MAKEFILE "\tperl \$(SCRIPTDIR)filter-out.pl \$\< \$(filter-out \$\<,\$(wildcard \$(\*)\*-files.txt)) > \$\@\n");

print(MAKEFILE "\%-files.txt  : \n");
print(MAKEFILE "\tperl \$(SCRIPTDIR)find.pl \$\(subst \_,\/,\$\*\) \> \$\@\n\n");

print(MAKEFILE "\%others.zip : \%-otherfiles.txt\n");
print(MAKEFILE "\ttype \$\< \| zip \-\@ \$\@\n\n");

print(MAKEFILE "\%.zip : \%-files.txt\n");
print(MAKEFILE "\ttype \$\< \| zip \-\@ \$\@\n\n");



print(MAKEFILE "# Creating cmd file for configuration using ebs tools\n");
print(MAKEFILE "\%\-ebs.xml : \$(SYSTEMDEFINITIONXML)\n");
print(MAKEFILE "\tperl \$(EPOCROOT)epoc32/tools/build/genxml.pl -o \$\@ -s \"\\\" -n \$\* -x \$\<\n");
print(MAKEFILE "\n");

print(MAKEFILE "\%.cmd : \%-ebs.xml\n");
print(MAKEFILE "\tperl \$(SCRIPTDIR)getEbsCommands.pl -d \$\< \> \$\@\n");
print(MAKEFILE "\n");

print(MAKEFILE "# Automatic dependencies\n");
print(MAKEFILE "\%\/abld.bat : \%\/bld.inf\n");
print(MAKEFILE "\t\$(call STARTTASK,bldmake bldfiles -v -k)\n");
print(MAKEFILE "\t\@echo Error 42 abld command issued when bldmake was not done first\n");
print(MAKEFILE "\t\@echo Error 42 This is a serious error in your build configuration and must be fixed.\n");
print(MAKEFILE "\t\@echo Error 42 In this build the error has been fixed automatically.\n");
print(MAKEFILE "\tcd \$* && bldmake bldfiles -v -k\n");
print(MAKEFILE "\t\$(ENDTASK)\n\n");
print(MAKEFILE "\n");

print(MAKEFILE "# If we are working on EC \"patched\" system\n");
print(MAKEFILE "ifeq (\$(strip \$(MAKE)),emake)\n");
print(MAKEFILE " \# We assume this to be Electric Cloud build\n");
print(MAKEFILE " CONFIGURATIONSUFFIX=-ECBS\n");
print(MAKEFILE "endif\n\n");
	

print(MAKEFILE "# Configurations\n");
print(MAKEFILE "CONFIGURATIONS:=");
foreach my $configurationName (sort(keys(%configurationTasks))) {
	print(MAKEFILE " \\\n ".makefileTargetName($configurationName));
}
print(MAKEFILE "\n\n");



print(MAKEFILE "# Printing out the configurations\n");
print(MAKEFILE "configurations : \$(addsuffix -print,\$(CONFIGURATIONS))\n\n");

# Filter current makefile out of this rule in order to avoid trying to regenerate current makefile
# in situations where for one reason or another system definition xml file is not present.
print(MAKEFILE "\$(filter-out \$(CURRENT_MAKEFILE),\$(addsuffix .make,\$(CONFIGURATIONS))) : \%.make : \$(SYSTEMDEFINITIONXML) ");

# If this is the root level makefile, add this makefile to dependencies also
# to avoid configuration specific sub makefiles and main level makefile 
# incompatibilities for instance with filters.
if ( $makefileName eq "makefile" ) {
    print(MAKEFILE "makefile");
}
print(MAKEFILE "\n");
print(MAKEFILE "\tperl \$(SCRIPTDIR)sysdef2make.pl \$(addprefix -filter ,\$(FILTERS)) -n \$\* \$(SYSDEF2MAKEFLAGS) \$\<\n\n");

print(MAKEFILE "\$(filter-out \$(CONFIGURATION),\$(CONFIGURATIONS)) : \% : \%.make\n");
print(MAKEFILE "\t\$(MAKE) -f \$\< \$\@\n\n");



# Build up buildlayertasks
foreach my $configurationName ( @configurations ) {
    my $configurationTargetName = makefileTargetName( $configurationName );
    foreach my $looptask ( @{$configurationTasks{$configurationName}} ) {
        my %task = %{$looptask};
        my $taskId = $task{taskId};
        if ( ! $task{specialInstruction} ) {
            my $command = makefileTargetName( $task{command} );
            my $target = makefileTargetName( $task{target} );
            $taskTargetName = makefileTargetName( $task{command},$task{target} );

            # Add task to list of tasks
            $buildLayerTasks{$taskTargetName} = $looptask;
        }
    }
}


# Process buildLayer tasks and derive commands which do not have options incorporated with them
foreach my $taskTarget ( sort(keys(%buildLayerTasks)) ) {
    my %task = %{$buildLayerTasks{$taskTarget}};
    
    my %newTask;
    $newTask{command} = $task{command};

    # Strip any " -XXX" from command
    $newTask{command} =~ s{\s-[^\s]*}{}g;
    
    $newTask{target} = $task{target};

    # Strip leading "-XXX" from target
    $newTask{target} =~ s{^-[^\s]*}{}g;

    # Strip any " -XXX" from target
    $newTask{target} =~ s{\s-[^\s]*}{}g;
    
    my $newTaskTargetName = makefileTargetName( $newTask{command}, $newTask{target} );
    if ( ! exists($buildLayerTasks{$newTaskTargetName}) ) {
        $newTask{option} = $task{option};
        $newTask{executable} = $task{executable};
        $buildLayerTasks{$newTaskTargetName} = \%newTask;
    }
}



# Here we determine the content for each special instruction
my $i = 0;
my @specialInstructionList = @{ $doc->getElementsByTagName('specialInstructions') };
my @currentArray = ();
my $name;
while ( $i < scalar(@specialInstructionList) ) 
# There are more specialInstructions
{
	# Set name and specialInstruction to list
	my $specialInstruction = $specialInstructionList[$i];
	$name = $specialInstruction->getAttribute('name');
	my $command = quoteCommand($specialInstruction->getAttribute('command'));
	my $cwd = $specialInstruction->getAttribute('cwd');

	if ( $ignoreErrorCommands{getExecutable($command)} ) 
	# Command is listed as "ignore error" command
	{
		$command = "-cd ".$cwd." && ".$command." ";
	} else {
		$command = "cd ".$cwd." && ".$command." ";
	}

	push( @currentArray, $command );
	
	# Get next element and advance list
	my $prevSpecialInstruction = $specialInstruction;
	$specialInstruction = $specialInstruction->getNextSibling();

	if ( ! $specialInstruction ) 
	# No next sibling. Get first child of parents next sibling
	{
		my $nextParent = $prevSpecialInstruction->getParentNode();
		do {
			$nextParent = $nextParent->getNextSibling();
	 	} while ( $nextParent && $nextParent->getNodeName() =~ m{^\#.*} );
 
		if ( $nextParent ) {
			$specialInstruction = $nextParent->getFirstChild();
		}
	}
	$i++;

	if ( ! $specialInstruction ||
           $specialInstruction->getNodeName() ne "specialInstructions" ||
           $specialInstruction->getAttribute('name') ne $name )
	# Element is not part of same specialInstruction group
	{
		checkRegisterSpecialInstruction( $name, @currentArray );
		# reset tasks
		@currentArray = ();
		$name = ();
	}
}

if ( $name && @currentArray ) {
	checkRegisterSpecialInstruction( $name, @currentArray );
}


sub checkRegisterSpecialInstruction($@) {
	my ($name,@currentArray) = @_;

	if ( $specialInstructions{$name} ) 
	# Same specialInstruction name has been registered
	{ 
		if ( scalar(@{$specialInstructions{$name}}) != scalar(@currentArray) ) 
		# Different amount of tasks
		{
			print(STDERR "ERROR: specialInstruction $name is defined in several places but with different contents.\n");

			if ( scalar(@currentArray) > scalar(@{$specialInstructions{$name}}) ) 
			# The latter instance has more instances
			{
				# Use that one 
				@{$specialInstructions{$name}} = @currentArray;
			}
		} else 
		# Same amount of tasks
		{
			my @registeredTasks = @{$specialInstructions{$name}};
			my $j=0;
			while ( $j < scalar(@currentArray) && 
					$currentArray[$j] eq $registeredTasks[$j] ) {
				$j++;
			}
			if ( $currentArray[$j] ne $registeredTasks[$j] ) {
				print(STDERR "ERROR: specialInstruction $name is defined several places but with different contents.\n");
			}
		}
	} else 
	# Not registered before, this is first time
	{
		push( @{$specialInstructions{$name}}, @currentArray );
	}
}


# Print out component specific rules resulting from buildLayer tasks
print(MAKEFILE "# buildLayer component (group/bld.inf) specific rules\n");
foreach my $makefileTarget ( keys(%buildLayerTasks) ) {
    my %task = %{$buildLayerTasks{$makefileTarget}};
    my $cmdLine = $task{command}." ".$task{option}." ".$task{target};

    # buildLayer tasks end up to pattern rules where pattern is the component directory
    my $match=0;
    foreach my $regexp (@forceMakeCommands) {
        if ( $cmdLine =~ m{$regexp}i ) {
            $match=1;
            last;
        }
    }
    if ( $match ) {
        # Its command matching "force make on this command" regexp
       
        # Make variable must contain standard gnu make, nothing else
        print(MAKEFILE "\%-".$makefileTarget.": MAKE=make\n");
    }
    if ( $task{executable} =~ /^abld/i ) {
        print(MAKEFILE "\%-".$makefileTarget.": %/abld.bat\n");
    } else {
        print(MAKEFILE "\%-".$makefileTarget.": %/bld.inf\n");
    }
    print(MAKEFILE "\t\$(call STARTTASK,".quoteCommandSeparators($task{command}).")\n");
    print(MAKEFILE "\t");
    if ( $ignoreErrorCommands{$task{executable}} ) {
        print(MAKEFILE "-");
    }
    print(MAKEFILE "cd \$* && $cmdLine\n");
    print(MAKEFILE "\t\$(ENDTASK)\n\n");
}


# Print out the contents of specialInstructions
print(MAKEFILE "# specialInstructions\n");
foreach my $specialInstruction ( keys(%specialInstructions) ) {
    my $simpleTarget = makefileTargetName($specialInstruction);
    my $commands = join(" \n\t",@{$specialInstructions{$specialInstruction}});
    
    # buildLayer tasks end up to pattern rules where pattern is the component directory
    my $match=0;
    foreach my $regexp (@forceMakeCommands) {
        if ( $commands =~ m{$regexp}i ) {
            $match=1;
            last;
        }
    }
    if ( $match ) {
        # Its command matching "force make on this command" regexp
       
        # Make variable must contain standard gnu make, nothing else
        print(MAKEFILE $simpleTarget.": MAKE=make\n");
    }
    print(MAKEFILE "$simpleTarget:\n");
    print(MAKEFILE "\t\$(call STARTTASK,\$\@)\n");
    print(MAKEFILE "\t$commands \n");
    print(MAKEFILE "\t\$(ENDTASK)\n\n");
}

# Print out the unitlists 
# Note that this will print unitlists several times if they are in several configurations
print(MAKEFILE "# Component lists based on contents of layers and unitlists\n");
foreach my $configuration ( @userConfigurations ) {
    foreach my $unitList ( @{$unitLists{$configuration}} ) {
        print(MAKEFILE "\n\n");
        print(MAKEFILE makefileTargetName($unitList)." := ");
        foreach my $unit ( @{$units{$unitList}} ) {
            print(MAKEFILE " \\\n ".$bldFiles{$unit});
        }

    }
}
print(MAKEFILE "\n\n");

print(MAKEFILE "# Rules for layers and unitLists\n");
foreach my $configuration ( @userConfigurations) {
    foreach my $unitList ( @{$unitLists{$configuration}} ) {
        # Check there's no matching configuration name
        my $unitListTarget = makefileTargetName($unitList);
        my $matchingLayer=0;
        foreach my $configurationName ( keys(%unitLists) ) {
            if ( makefileTargetName(lc($configurationName)) eq lc($unitListTarget) ) {
                $matchingLayer = 1;
                last;
            }
        }
    
        # Print unitlist-task rule only if it there is no matching configuration-task rule existing anywhere
        if ( ! $matchingLayer ) {
            foreach my $task ( keys(%buildLayerTasks) ) {
                print(MAKEFILE "\n\n".makefileTargetName($unitList)."-$task : \$(addsuffix -$task , \$(filter-out \$(\$(CONFIGURATION)-EXCLUDE),\$(".makefileTargetName($unitList).")))");
            }
        }
    }
}
print(MAKEFILE "\n\n");

foreach my $configurationName ( @userConfigurations ) {
    my $configurationTargetName = makefileTargetName( $configurationName );

    print(MAKEFILE "$configurationTargetName-UNITS := ");
    foreach my $unitList ( @{$unitLists{$configurationName}} ) {
        print(MAKEFILE "\$(".makefileTargetName($unitList).") ");
    }
    print(MAKEFILE "\n\n");

    my @excludedUnits = @{$excludedUnits{$configurationName}};
    
    print(MAKEFILE "# Excluded components in $configurationName\n");
    print(MAKEFILE "$configurationTargetName-EXCLUDE := ");
    foreach my $unit ( @excludedUnits ) {
        print(MAKEFILE " \\\n".$bldFiles{$unit});
    }
    print(MAKEFILE "\n\n");

    my %targetDependencies;
    my %targetCommands;

    push( @{$targetDependencies{$configurationTargetName}}, "timestart.txt" );    
    foreach my $looptask ( @{$configurationTasks{$configurationName}} ) {
        # Build up configuration depencencies list
        my %task = %{$looptask};
        my $taskId = $task{taskId};
        if ( $task{specialInstruction} ) {
            my $taskTargetName = makefileTargetName( $task{specialInstruction} );
            my $target = "$configurationTargetName-$taskTargetName-$taskId";
            push( @{$targetDependencies{$configurationTargetName}}, $target );
            # TODO set the correct file name for the following
            $cmdString = "\$(MAKE) \$(addprefix -f ,\$(CURRENT_MAKEFILE)) $taskTargetName";
            push( @{$targetCommands{$target}}, $cmdString );

        } else {
            my $command = makefileTargetName( $task{command} );
            my $target = makefileTargetName( $task{target} );
            $taskTargetName = makefileTargetName( $task{command},$task{target} );

            # Set unitlist or configuration as a prefix to task rule
            if ( @{$task{unitLists}} ) 
            # Task specific unitlist defined
            {
                $taskTargetName = "\$(addsuffix -".$taskTargetName.",".join(" ",@{$task{unitLists}}).")";
            } else {
                # Prefix the targetname to current dependencies
                $taskTargetName = $configurationTargetName."-".$taskTargetName;
            }
            my $target = "$configurationTargetName-$taskTargetName-$taskId";
            push( @{$targetDependencies{$configurationTargetName}}, $target );
            # TODO set the correct file name for the following
            $cmdString = "\$(MAKE) \$(addprefix -f ,\$(CURRENT_MAKEFILE)) $taskTargetName";
            push( @{$targetCommands{$target}}, $cmdString );
        }
    }

    print(MAKEFILE "$configurationTargetName: CONFIGURATION:=$configurationTargetName\n");
    print(MAKEFILE "$configurationTargetName: ".join(" \\\n  ".(" " x length($configurationTargetName)), @{$targetDependencies{$configurationTargetName}})."\n");

    print(MAKEFILE "\t\@\-perl -e \"print '=== \$(CONFIGURATION) finished '.localtime().\\\"\\n\\\"\"\n");
    print(MAKEFILE "\t\$\(LOGBUILDTIME\)\n");
    print(MAKEFILE "\t\@\-perl -e \"print time\" \> timestop.txt\n");
    print(MAKEFILE "\n\n");

    print(MAKEFILE "# Dependencies between individual tasks\n");

    # Makefile target name for current task 
    # buildLayer tasks: unitlist/configuration-command[-target]

    my $i=1;
    while ( $i < scalar( @{$targetDependencies{$configurationTargetName}} ) ) {
        my $target = $targetDependencies{$configurationTargetName}[$i];
        print(MAKEFILE "$target: ".$targetDependencies{$configurationTargetName}[$i-1]."\n");
        print(MAKEFILE "\t".join(" \n\t",@{$targetCommands{$target}})."\n");
        print(MAKEFILE "\n");
        $i++;
    }
}   



foreach my $configurationName ( @userConfigurations ) {
    print(MAKEFILE getConfigurationTaskRules($configurationName) );
}

sub getConfigurationTaskRules($) {
    my ($configurationName) = @_;
	my $configurationTargetName = makefileTargetName( $configurationName );
    my $output = "# configuration -> unitlists rules for $configurationName\n";

	foreach my $task ( keys(%buildLayerTasks) ) {
		$output.="$configurationTargetName-$task : \$(addsuffix -$task,\$(filter-out \$($configurationTargetName-EXCLUDE),\$($configurationTargetName-UNITS)))\n";
		$output.="\n\n";
	}
	return($output);
}




print(MAKEFILE "# Printing out the tasks for layers unitlists and bld.inf\n");
print(MAKEFILE "tasks : \$(foreach TASK,");
foreach my $command (sort(keys(%buildLayerTasks))) {
	print(MAKEFILE " \\\n  ".quoteCommandForEcho($command));
}
print(MAKEFILE ",-\$(TASK)-print)\n\n");

print(MAKEFILE "# Printing out special instructions\n");
print(MAKEFILE "specialInstructions:\n");
foreach my $specialInstruction (sort(keys(%specialInstructions))) {
	print(MAKEFILE "\t\@echo ".makefileTargetName($specialInstruction)."\n");
}
print(MAKEFILE "\n\n");



print(MAKEFILE "# Printing out layers\n");
print(MAKEFILE "layers:\n");
foreach my $layer (sort(keys(%units))) {
	print(MAKEFILE "\t\@echo $layer\n");
}
print(MAKEFILE "\n\n");

print(MAKEFILE "# Printing out filters\n");
print(MAKEFILE "filters:\n");
foreach my $filter (keys(%filters)) {
    print(MAKEFILE "\t\@echo $filter\n");
}
print(MAKEFILE "\n\n");

close(MAKEFILE);

# Creates a valid makefile target string from name,command and target
sub makefileTargetName {
	my @arguments=@_;

	if ( ! @arguments ) {
		return("");
	}
	my $result=shift(@arguments);
	$result =~ s{[\s\.\%\&\|\;\"\<\>]}{_}g;
	$result =~ s{\\}{/}g;
	$result =~ s{_+}{_}g;


	my $rest = makefileTargetName(@arguments);
	if ( $rest ) {
		$result.="-".$rest;
	}

	$result =~ s{_-}{-}g;
	return $result;
}

sub quoteCommandSeparators($) {
    my ($string) = @_;
    $string =~ s{([\&\|\;\"])}{_}g;
    return($string);
}

sub getExecutable($) {
	my ($command) = @_;
	$command =~ s{^\s*([^\s]+).*}{\1};
	return $command;
}

# Add quoting for echoing commands which have command control characters in them
sub quoteCommandForEcho($) {
	my ($command) = @_;
	$command =~ s{([\%\|\&\<\>])}{\^\1}g;
	return $command;
}

# Add quoting for commands to make them print out in makefile
sub quoteCommand($) {
	my ($command) = @_;
	$command =~ s{\$}{\$\$}g;
	return $command;
}

# check_filter
#
# Inputs
# $item_filter - filter specification (comma-separated list of words)
# $configspec - configuration specification (reference to list of words)
#
# Outputs
# $failed - filter item which did not agree with the configuration (if any)
#           An empty string is returned if the configspec passed the filter
#
# Description
# This function checks the configspec list of words against the words in the
# filter. If a word is present in the filter, then it must also be present in
# the configspec. If "!word" is present in the filter, then "word" must not
# be present in the configspec.
sub check_filter($$) {
    my ($item_filter, $configspec) = @_;
    my $failed = "";

    foreach my $word (split /,/,$item_filter) {
        if ($word =~ /^!/) {
            # word must NOT be present in configuration filter list

            my $notword = substr($word, 1);
            if ( grep(/^$notword$/, @$configspec) ) {
                $failed = $word;
            }
        } else {
            # word must be present in configuration filter list
            $failed = $word unless grep(/^$word$/, @$configspec);
        }
    }
    return $failed;
}
    
