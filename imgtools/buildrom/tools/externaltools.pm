#
# Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# This package invokes single and multiple external tools
#

package externaltools;

require Exporter;
@ISA=qw (Exporter);
@EXPORT=qw (
	loadTools
	runExternalTool
		
);

use Modload; # Dynamically loads the module
my %invocations; # Indexed by invocation name;

#Set the Module path to load perl modules
{
	my $epocToolsPath = $ENV{EPOCROOT}."epoc32\\tools\\";
	Load_SetModulePath($epocToolsPath);
}

# Get all the external tool perl module files to load them
sub loadTools{
	
	my $toolList = shift;
	my @toolModules = split(/,/,$toolList);
	foreach my $tool (@toolModules) {
		# An optional command line can be passed to the tool if it is of the form "<toolname>[:<cmdline>]"
		if ($tool !~ /^([^:]+)(:(.*))?$/) {
			print "No tool specified as parameter for external tool invocation\n";
		}
		my $toolName = $1;
		my $toolCmdLine = $3;
		&Load_ModuleL($toolName);
		my $toolDetailsMap = $toolName.'::' . $toolName.'_info';
		update(&$toolDetailsMap, $toolCmdLine);
	}
}

#Initialises information from external tool
sub update 
{
	my ($info, $toolCmdLine) = @_;
	my $toolName;
	my $toolStage;

	# name - name of the tool. used to associate with appropriate oby tool
	#		keyword
	# invocation - stage when tool shall be invoked.
	# multiple - routine to invoke for multiple invocation
	# single - routine to invoke for single invocation
	# initialize - optional routine to initialize tool before main invocation.
	# 
	if (defined ($info->{name})) {
		$toolName = $info->{name};
	}
	if (defined ($info->{invocation})) {
		$toolStage = lc $info->{invocation};
	}
    
    push @{$invocations{$toolStage}}, $info;
	
	if (defined ($info->{initialize}))
		{
		&{$$info{'initialize'}}($toolCmdLine);
		}
}

# Called between the buildrom stage to invoke single or multiple invocation
sub runExternalTool {
	
	my ($stageName,$OBYData) = @_;
	$stageName = lc $stageName;
	my @toolInfoList =  @{$invocations{$stageName}}; # Collect Tools with respect to its stagename.
	
	foreach my $tool (@toolInfoList) { # Traverse for the tools

		if (exists($tool->{single})) {#Check if single invocation exists
			if (defined ($OBYData)) {
				invoke_single($OBYData, $tool);
			}				
			else {
				print "Empty OBYData array reference in Single Invocation\n";
			}

		}#End Single if 

		if (exists($tool->{multiple})) { #Check if multiple invocation exists
			if (defined ($OBYData)) { 
				# Called from appropriate stage to invoke multiple invocation
				invoke_multiple($OBYData, $tool);
			}
			else {
				print "Empty OBYData Line in Multiple Invocation\n";
			}

		}#End Multiple if 

	}#End of tool traversal
	
}#End of Method

#Runs Tool for each line of the OBY file
#Gets modified line and adds to OBY line data reference
sub invoke_multiple
{
    my ($OBYDataRef,$tool) = @_;
	my $modifiedOBYLine;
	my $toolName;
	my $index = 0;# Index each OBY line
	my $arrayLength = scalar(@$OBYDataRef);
	my $OBYLineRef;

	while ($index < $arrayLength) {

		$OBYLineRef = \$OBYDataRef->[$index];# Get the line reference
			
		if ($$OBYLineRef =~/tool=(\w+)/){ # Match for 'tool' keyword
			$toolName = $1;

			if ($toolName eq $tool->{name}) {# Match the tool name
				my $routine=$tool->{multiple};
				$modifiedOBYLine = &$routine($$OBYLineRef); #Invoke multiple Invocation, get modified line
			
				if (defined ($modifiedOBYLine)) { # If line is not empty
					$$OBYLineRef = $modifiedOBYLine; # Modify the line reference with new line
				}

			}#End of if toolname match

		}#End of if 'tool' keyword match

		$index++; # For each line of OBY file.
	
	}#End of oby line traversal <while>

}

#Runs Tool only once.
#Add new data to the obydata array reference.
sub invoke_single {

    my ($OBYDataRef,$tool) = @_;
    my $routine = $tool->{single};
    &$routine($OBYDataRef);#Invoke single Invocation, update new data
}



1;