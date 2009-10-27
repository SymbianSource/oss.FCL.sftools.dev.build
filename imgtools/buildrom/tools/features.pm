#
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

# This package contains routines to create the feature header and iby files.
package features;

require Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(
	open_Database
	generate_Headerfile
	generate_Obeyfile
	generate_DATfile
	set_DefaultPath
	set_VerboseMode
	set_StrictMode
);

use strict;

# Include the featureutil module to use API to read from XML file.
use featuresutil;

# Object of featureparser
my $xmlDBHandle = undef;

# Mask value for supported feature flag
use constant BIT_SUPPORTED=>0x00000001;

# Feature dat file name
use constant DAT_FILE=>"features.dat";

# Feature manager support flag
use constant FM_FLG=>0x01;

# Feature registry support flag
use constant FR_FLG=>0x02;

# single dat file generation
use constant SINGLE_DATFILE=>1;

# none value
use constant NONE=>-1;

# verbose mode flag
my $verboseMode = 0;

# strict mode flag
my $strictMode = 0;

#
# Open and parse the given xml database
# @param - xml file name
#
sub open_Database
{
	my ($xmlDBFile) = join(',',@_);
	
	$xmlDBHandle = &featuresutil::parseXMLDatabase($xmlDBFile,FM_FLG,$strictMode,$verboseMode);
	
	return 0 if(!$xmlDBHandle);
	return 1;
}

#
# set the default path settings for header and iby files
#
sub set_DefaultPath
{
	my ($epocroot, $hdrpath, $ibypath, $datpath, $convpath) = @_;
	
	$$hdrpath = $epocroot."epoc32/include/";
	$$ibypath = $epocroot."epoc32/rom/include/";
	$$datpath = "./"; # current folder
	$$convpath = "./"; # current folder
}

#
# Generate the header file for each featureset
# @param - destination path for the header file(s)
#
sub generate_Headerfile
{
	my $featureList=(); 
	my $featureSetList = ();
	my $hdrpath = shift;
	my $aliasfeatureList = ();
	
	# Get the list of featuresets exists in the xml database
	$featureSetList = $xmlDBHandle->getFeatureset();
	foreach my $featureSet (@$featureSetList) {
		my @defPresent=();
		my @defNotPresent=();
		my @defPresentAlias = ();
		my @defNotPresentAlias = ();
		my $tab = "\t";
		
		# if the headerfile name is not there then just return
		if(!defined $featureSet->{hfilename}) {
			MSG("No header file generated for the featureset $featureSet->{namespace}");
			next;
		}
		
		# Get the filename
		my $hfile = $featureSet->{hfilename};
		
		# Create directory if it doesn't exists
		return if(!createDirectory($hdrpath));
		
		my $hfileHandle = openFile($hdrpath.$hfile);
		if(!$hfileHandle) {
			print "ERROR: Cannot open file $hdrpath$hfile\n";
			next;
		}
		
		MSG("Creating headerfile $hdrpath$hfile");
		
		# Get the name->uid map for the features given in the selected featureset
		$featureList = $featureSet->{feature_list};
		# Create two sets of feature name list for the default present and notpresent
		foreach my $name (keys %$featureList)
		{
			if(defaultPresent($featureList->{$name})){
				push @defPresent, $name;
			}
			else {
				push @defNotPresent, $name;
			}
		}
		#for alias
		$aliasfeatureList = $featureSet->{alias_feature_list};
		foreach my $alias_name (keys %$aliasfeatureList)
		{
			if(defaultPresent($aliasfeatureList->{$alias_name}))
			{
				push @defPresentAlias, $alias_name;
			}
			else
			{
				push @defNotPresent, $alias_name;
			}
		}

		# sort them
		@defPresent = sort(@defPresent);
		@defNotPresent = sort(@defNotPresent);
		
		# insert the file header attribute value
		my $comment = $featureSet->{hfileheader};
		if($comment) {
			trimString(\$comment);
			
			# insert the interfacevisibility and interfacestatus attribute values
			writeFile($hfileHandle, $comment."\n/**\n".$featureSet->{interfacevisibility}."\n".
						 $featureSet->{interfacestatus}."\n*/\n");
		}
					 
		if(defined $featureSet->{namespace}) {
			writeFile($hfileHandle, "namespace ".$featureSet->{namespace}." {\n");
		}
		else {
			$tab = "";
		}
		
		# for each feature list insert an entry in the current namespace
		writeFile($hfileHandle,$tab."// default present\n") if(@defPresent);
		foreach my $name (@defPresent) {
			$comment = $featureSet->{feature}{$featureList->{$name}}{comment};
			if(defined $comment) {
				trimString(\$comment);
				$comment =~ s/\n/\n$tab/mg;
				chop($comment) if($tab eq "\t");
				writeFile($hfileHandle, $tab.$comment);
			}
			
			writeFile($hfileHandle,$tab."const TUid K", $featureSet->{feature}{$featureList->{$name}}{name},
						 sprintf(" = {0x%X};\n", $featureList->{$name}));
			writeFile($hfileHandle,"\n") if(defined $comment);
		}

		foreach my $alias_name (@defPresentAlias)
		{
			$comment = $featureSet->{alias_feature}{$aliasfeatureList->{$alias_name}}{comment};
			if(defined $comment)
			{
				trimString(\$comment);
				$comment =~ s/\n/\n$tab/mg;
				chop($comment) if ($tab eq "\t");
				writeFile($hfileHandle, $tab.$comment);
			}
			writeFile($hfileHandle, $tab."const TUid K", $featureSet->{alias_feature}{$aliasfeatureList->{$alias_name}}{name}, sprintf(" = {0x%X};\n", $aliasfeatureList->{$alias_name}));
			writeFile($hfileHandle, "\n") if(defined $comment);
		}

		writeFile($hfileHandle, "\n".$tab."// default not present\n") if(@defNotPresent);
		foreach my $name (@defNotPresent) {
			$comment = $featureSet->{feature}{$featureList->{$name}}{comment};
			if(defined $comment) {
				trimString(\$comment);
				$comment =~ s/\n/\n$tab/mg;
				chop($comment) if($tab eq "\t");
				writeFile($hfileHandle,$tab.$comment);
			}
			
			writeFile($hfileHandle,$tab."const TUid K", $featureSet->{feature}{$featureList->{$name}}{name},
						 sprintf(" = {0x%X};\n", $featureList->{$name}));
			writeFile($hfileHandle,"\n") if(defined $comment);
		}
		foreach my $alias_name (@defNotPresentAlias)
		{
			$comment = $featureSet->{alias_feature}{$aliasfeatureList->{$alias_name}}{comment};
			if(defined $comment)
			{
				trimString(\$comment);
				$comment =~ s/\n/\n$tab/mg;
				chop($comment) if ($tab eq "\t");
				writeFile($hfileHandle, $tab.$comment);
			}
			writeFile($hfileHandle, $tab."const TUid K", $featureSet->{alias_feature}{$aliasfeatureList->{$alias_name}}{name}, sprintf(" = {0x%X};\n", $aliasfeatureList->{$alias_name}));
			writeFile($hfileHandle, "\n") if(defined $comment);
		}
		
		if(defined $featureSet->{namespace}) {
			writeFile($hfileHandle,"}\n");
		}
		
		closeFile($hfileHandle);
	}
}

#
# Generate the obey file for each featureset
# @param - destination path for the iby file(s)
#
sub generate_Obeyfile
{
	my $featureSet=(); my $feature=(); my $featureList=(); my $featureSetList=();
	my $aliasfeatureList = ();
	my $ibypath = shift;
	
	# Get the list of featuresets exists in the xml database
	$featureSetList = $xmlDBHandle->getFeatureset();
	foreach my $featureSet (@$featureSetList) {
		# if the obey file name is not there then just return
		if(!defined $featureSet->{ibyname}) {
			MSG("No IBY file generated for the featureset $featureSet->{namespace}");
			next;
		}
		
		# Get the file name
		my $ibyfile = $featureSet->{ibyname};
		
		# Create the directory if it doesn't exists
		return if(!createDirectory($ibypath));
		
		my $ibyfilehandle = openFile($ibypath.$ibyfile);
		if(!$ibyfilehandle) {
			print "*ERROR: Cannot open file $ibypath$ibyfile\n";
			next;
		}
		
		MSG("Creating IBY file $ibypath$ibyfile");
		
		$ibyfile =~ s/\./\_/g;
		$ibyfile = uc($ibyfile);
		
		# insert the file header
		writeFile($ibyfilehandle, "#ifndef\t__",$ibyfile,"__\n#define\t__",$ibyfile,"__\n\n");

		# get the name->uid map of features for the given featureset
		$featureList = $featureSet->{feature_list};
		$aliasfeatureList = $featureSet->{alias_feature_list};
		my %combine_list = (%$featureList, %$aliasfeatureList);
		foreach my $name (sort keys %combine_list)
		{
			my $defblock=(); my $flags=(); my $comment=();
			
			my $uid = $xmlDBHandle->getFeatureUID($name,$featureSet->{namespace});
			
			# get the featureset attributes
			$feature = $xmlDBHandle->getFeatureInfo($uid,$featureSet->{namespace});
			
			# check to see this feature to be included in iby file
			next if(!$feature->{infeaturesetiby});
			# get the feature flags
			$flags = "SF ".$feature->{statusflags} if(defined $feature->{statusflags});
			if(defined $feature->{userdata}) {
				$flags .= " "."UD ".$feature->{userdata};
			}
			else {
				$flags .= " "."UD 0x00000000";
			}

			# get the comment value
			if(defined $feature->{comment}) {
				$comment = $feature->{comment};
				trimString(\$comment);
			}
			
			if(defined $feature->{includemacro}) { # if the include macro is specified
				$defblock = "\n#ifdef ".$feature->{includemacro}."\n";
				$defblock .= $comment;
				$defblock .= "FEATURE ".$feature->{name}." ".$flags."\n";
				$defblock .= "#else\nEXCLUDE_FEATURE ".$feature->{name}." ".$flags."\n#endif\n"
			}
			elsif(defined $feature->{excludemacro}) { # if the exclude macro is specified
				$defblock = "\n#ifdef ".$feature->{excludemacro}."\n";
				$defblock .= "EXCLUDE_FEATURE ".$feature->{name}." ".$flags."\n#else\n";
				$defblock .= $comment;
				$defblock .= "FEATURE ".$feature->{name}." ".$flags."\n#endif\n"
			}
			else {  # default case
				# No system wide macro defined for this feature
				next;
			}
			
			# insert #ifdef block
			writeFile($ibyfilehandle, $defblock);
		}
		
		writeFile($ibyfilehandle, "\n\n#endif //__",$ibyfile,"__");
		closeFile($ibyfilehandle);
	}
}

#
# Generate the feature DAT file
# @param - destination path for the features.DAT file
#
sub generate_DATfile
{
	my $featureSet=(); my $feature=(); my $featureList=(); my $featureSetList=();
	my @featList=();
	my $aliasfeatureList = ();
	my $aliasfeatlist = ();
	my %uidtoaliasname = ();
	my $datpath = shift;
	
	# Get the list of featuresets exists in the xml database
	$featureSetList = $xmlDBHandle->getFeatureset();
	$aliasfeatlist = $xmlDBHandle->getAliasFeatureList();
	foreach my $aliasname (keys %$aliasfeatlist)
	{
		$uidtoaliasname{$aliasfeatlist->{$aliasname}} = $aliasname;
	}
	foreach my $featureSet (@$featureSetList) {
		# get the name->uid map of features for the given featureset
		$featureList = $featureSet->{feature_list};
		foreach my $name (keys %$featureList)
		{
			if (exists $uidtoaliasname{$featureList->{$name}})
			{
				next;
			}
			my $statusflag = 0;
			my %featinfo = ();
			
			$featinfo{feature} = $name;
			$featinfo{SF} = $xmlDBHandle->getStatusFlag($name, $featureSet->{namespace});
			$featinfo{UD} = $xmlDBHandle->getUserData($name, $featureSet->{namespace});
			$statusflag = &featureparser::ConvertHexToDecimal($featinfo{SF});
			if($statusflag & BIT_SUPPORTED) {
				$featinfo{include} = 1;
			}
			else {
				$featinfo{include} = 0;
			}
			
			push @featList, {%featinfo};
		}
		$aliasfeatureList = $featureSet->{alias_feature_list};
		foreach my $alias_name (keys %$aliasfeatureList)
		{
			my $statusflag = 0;
			my %featinfo = ();
			
			$featinfo{feature} = $alias_name;
			$featinfo{SF} = $xmlDBHandle->getStatusFlag($alias_name, $featureSet->{namespace});
			$featinfo{UD} = $xmlDBHandle->getUserData($alias_name, $featureSet->{namespace});
			$statusflag = &featureparser::ConvertHexToDecimal($featinfo{SF});
			if($statusflag & BIT_SUPPORTED) {
				$featinfo{include} = 1;
			}
			else {
				$featinfo{include} = 0;
			}
			push @featList, {%featinfo};
		}


	}
	
	if(@featList) {
		# Create the directory if doesn't exists
		return if(!createDirectory($datpath));
		
		# Create features.dat file
		&featuresutil::createFeatureFile(NONE,NONE,$datpath.DAT_FILE,\@featList,FM_FLG,SINGLE_DATFILE);
	}
}

#
# Converts the feature registry object to feature manager xml
# @param - destination path for the output file
# @param - input file list as an array
#
sub convert_FeatRegToFeatMgr
{
	&featuresutil::convert_FeatRegToFeatMgr($strictMode,$verboseMode,@_);
}

#
# Enable verbose mode
# 
sub set_VerboseMode
{
	$verboseMode = 1;
}

#
# Enable strict mode
# 
sub set_StrictMode
{
	$strictMode = 1;
}

# --Utility Functions

#
# Check whether the given feature uid is present in default include list
# @param - feature uid value
#
sub defaultPresent
{
	my ($uid) = shift;
	
	my $defaultRanges = $xmlDBHandle->defaultRangeList();
	
	foreach my $range (@$defaultRanges)
	{
		if ( (lc($range->{"support"}) eq "include") and ($range->{"min"} <= $uid) and ($range->{"max"} >= $uid) ) {
			return 1;
		}
	}
	return 0;
}

#
# Trim the given string for trailing whitespaces
# @param - string to be trimmed
#
sub trimString
{
	my $str = shift;
	
	$$str =~ s/^[ \t]+//mg;
	$$str =~ s/^\n//mg;
	
	$$str .= "\n" if($$str !~ /\n$/m);
}

#
# Verbose mode output routine
# @param - Message to be displayed
#
sub MSG 
{
	print "**".$_[0]."...\n" if($verboseMode);
}

#
# Open a text file in write mode
# @param - name of the file to open
#
sub openFile
{
	my $file = shift;
	
	open(FILEP,">$file") or (return 0);
	
	return *FILEP;
}

#
# Writes string to the file stream
# @param filehandle - reference to the file handle
# @param data - array of string to be written
#
sub writeFile
{
	my ($filehandle, @data) = @_;
	
	printf $filehandle "%s",$_ foreach (@data);
}

#
# Closes the file stream
# @param filehanlde - referece to the file handle
#
sub closeFile
{
	my $filehandle = shift;
	
	close $filehandle;
}

#
# Check the existance of the directory and create one if it doesn't exist
# @param dir - directory name
#
sub createDirectory
{
	my $dir = shift;
	
	if(!(-e $dir)) {
		if(!mkdir($dir)) {
			print "ERROR: Failed to create $dir folder\n";
			return 0;
		}
	}
	return 1;
}

1;
