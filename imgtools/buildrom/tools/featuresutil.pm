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

package featuresutil;
        

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	parseXMLDatabase
	createFeatureFile
	convert_FeatRegToFeatMgr
);

use strict;
use XML::Handler::XMLWriter;
use IO;

use featureparser;
use featuremanager;
use featureregistry;
use featuresdat;
use featurecfg;

my $xmlDBHandle = undef; #Object of feature parser

my @includeFeatureList;	#List of included features. The included feature in this list is a hash table giving the 
			#Uid or the name. These features are collected from the iby/obey files.
my @excludeFeatureList;	#List of excluded features.The excluded feature in this list is a hash table giving the 
			#Uid or the name. These features are collected from the iby/obey files.

my $verboseFlg = 0; # verbose mode flag
my $strictFlg = 1; # strict mode flag

# Subroutine to generate warning messages.
sub WARN 
{
	print "WARNING: ".$_[0]."\n"; 
}

# Subroutine to generate error messages.
sub ERROR 
{ 
	print "ERROR: ".$_[0]."\n"; 
}

# Verbose mode output routine
sub MSG 
{
	if($verboseFlg) {
		print "**".$_[0]."...\n";
	}
}

# Subroutine to parse feature list XML database file.
# @param dbfileList					- List of XML database file names seperated by commas.
# @param fmFlag						- Flag to generate features data file.
# @param strictFlg					- Flag to enable strict mode (optional).
# @param verboseFlg                 - Flag to enable verbose mode (optional).
sub parseXMLDatabase
{
	my $dbfileList = shift;
	my $fmFlag = shift;
	$strictFlg = shift;
	$verboseFlg = shift;
	
	# list of xml databases
	my @filelist = split(/,/,$dbfileList);
	
	# return status
	my $retStatus = 0;
	
	# default mode is strict
	$strictFlg=0 if(!defined $strictFlg);
	# default mode is nonverbose
	$verboseFlg=0 if(!defined $verboseFlg);
	
	# multiple file support is not applicable for feature registry option
	if( (@filelist > 1) && (!$fmFlag) ) {
		&ERROR("Multiple XML database file support is not applicable for featureregistry option");
		return 0;
	}
	
	if($fmFlag) # Feature manager option handling
	{
		# create the object of feature manager class
		$xmlDBHandle = new featuremanager;
		
		if($xmlDBHandle) {
			foreach my $file (@filelist) 
			{
				my $status = 1;
				if(-e $file) {
					
					&MSG("Parsing $file");
					
					# parse the feature manager xml file
					$status = $xmlDBHandle->parseXMLFile($file);
					if(! $status) {
					
						# create the object of feature registry class
						my $registryObj = new featureregistry;
						# parse the feature registry xml file
						$status = $registryObj->parseXMLFile($file);
						if($status < 0) {
							if($strictFlg) {
								&ERROR("Invalid features database $file");
								$xmlDBHandle = undef;
								return 0;
							}
							else {
								&WARN("Invalid features database $file");
							}
						}
						elsif(! $status) {
							# if the xml file is not valid feature list xml file
							if($strictFlg) {
								&ERROR("Error in reading features database file \"$file\"");
								$xmlDBHandle = undef;
								return 0;
							}
							else {
								&WARN("Error in reading features database file \"$file\"");
							}
						}
						else {
							MSG("Converting featureregistry database to featuremanager");
							
							# add the feature registry file object to the feature manager file object
							if(! $xmlDBHandle->addFeatureRegistry($registryObj)) {
								if($strictFlg) {
									MSG("Error in reading features database file \"$file\"");
									$xmlDBHandle = undef;
									return 0;
								}
								else {
									&WARN("Error in reading features database file \"$file\"");
								}
							}
							else {
								# parsing feature registry database success
								$retStatus = 1;
							}
						}
					}
					elsif( $status < 0 ) {
						if($strictFlg) {
							&ERROR("Invalid features database $file");
							$xmlDBHandle = undef;
							return 0;
						}
						else {
							&WARN("Invalid features database $file");
						}
					}
					else {
						# parsing feature manager database success
						$retStatus = 1;
					}
				}
				else {
					if(!$strictFlg) {
						&WARN($file." doesn\'t exist");
						next;
					}
					else {
						&ERROR($file." doesn\'t exist");
						$xmlDBHandle = undef;
						return 0;
					}
				}
			}
		}
		else {
			&ERROR("Couldn't create feature parser object");
		}
	}
	else # Feature registry file handling
	{
		if(@filelist) {
			my $file = $filelist[0];
			$xmlDBHandle = new featureregistry;
			
			if($xmlDBHandle) {
				if(-e $file) {
				
					MSG("Parsing $file");
					
					my $status = $xmlDBHandle->parseXMLFile($file);

					if($status < 0) {
						&ERROR($file." is invalid feature registry file");
						$xmlDBHandle = undef;
						return 0;
					}
					elsif(!$status) {
						&ERROR("Error in reading feature registry file ".$file);
						$xmlDBHandle = undef;
					}
					else {
						# parsing feature registry database success
						$retStatus = 1;
					}
				}
				else {
					if(!$strictFlg) {
						&WARN($file." doesn\'t exist -- ");
					}
					else {
						&ERROR($file." doesn\'t exist -- ");
					}				
					$xmlDBHandle = undef;
				}
			}
			else {
				&ERROR("Couldn't create feature parser object");
			}
		}
	}
	
	if($retStatus) {
		return $xmlDBHandle
	}
	else {
		return $retStatus;
	}
}

# Subroutine to generate feature manager database file from the given feature registry database
# @param strictFlg - strict mode flag
# @param verboseFlg - verbose mode flag
# @param outpath - destination path for the converted database file(s)
# @param dblist - list of xml file names
sub convert_FeatRegToFeatMgr
{
	$strictFlg = shift;
	$verboseFlg = shift;
	my $outpath = shift;
	my @dblist = @_;
	
	# default mode is strict
	$strictFlg=0 if(!defined $strictFlg);
	# default mode is nonverbose
	$verboseFlg=0 if(!defined $verboseFlg);

	foreach my $file (@dblist)
	{
		# Create the object of feature registry
		my $fileHandle = new featureregistry;
		
		if(-e $file) {
			# Parse the database
			if($fileHandle->parseXMLFile($file) > 0) {
				MSG("Converting Feature Registry database $file");
				
				# Create directory if it doesn't exists
				if(!(-e $outpath)) {
					if(!mkdir($outpath)) {
						&ERROR("Failed to create $outpath folder");
						return 0;
					}
				}
				# Emit the contents of feature registry object into an feature manager database file
				&generateXML($fileHandle, $outpath);
			}
		}
		else {
			if(!$strictFlg) {
				&WARN($file." doesn\'t exist -- ");
				next;
			}
			else {
				&ERROR($file." doesn\'t exist -- ");
				return 0;
			}
		}
	}
}

# Subroutine to emit XML output for the given featureregistry object
# @param frObject - object of feature registry database
# @param outPath - destination path for the converted database file
sub generateXML
{
	my ($frObject, $outPath) = @_;
		
	my $outputFile = $frObject->fileName();
	
	# Extract absolute file name
	if( $outputFile =~ /[\\\/]/) {
		$outputFile =~ /.*[\\\/](.+)\z/;
		$outputFile = $1;
	}
	
	# Add suffix _converted
	$outputFile =~ s/(.*)([\.].+)\z/$1_converted$2/;
	
	my $fileHandle = new IO::File(">$outPath$outputFile");
	
	if($fileHandle) {
		my $writer = XML::Handler::XMLWriter->new(Output => $fileHandle);
		
		# Header
		$writer->start_document();
		$writer->print("<!--Converted from the feature registry ".$frObject->fileName()."-->\n\n");
		# DOCTYPE
		$writer->print("<!DOCTYPE featuredatabase SYSTEM \"featuredatabase.dtd\">\n\n");
		
		# Root element begin
		$writer->start_element({Name => 'featuredatabase', Attributes => {}});
		
		# FeatureSet element
		$writer->print("\n\t");
		$writer->start_element({Name => 'featureset', Attributes => {}});
		my $nameuidmap = $frObject->featureNameUidMap();
		foreach my $uid (sort(values %$nameuidmap)) {
			my $featinfo = $frObject->getFeatureInfo($uid);
			my %attributes = ();
			
			$attributes{uid} = sprintf("0x%08X",$uid);
			$attributes{statusflags} = "0x00000001";
			$attributes{name} = $featinfo->{name};
			
			$writer->print("\n\t\t");
			$writer->start_element({Name => 'feature', Attributes => \%attributes});
			$writer->end_element({Name => 'feature'});
		}
		$writer->print("\n\t");
		$writer->end_element({Name => 'featureset'});
		
		# defaultfeaturerange element
		my $rangeList = $frObject->defaultRangeList();
		foreach my $range (@$rangeList) {
			my %attributes = ();
			
			next if(lc($range->{support}) eq "exclude");
			
			$attributes{higheruid} = sprintf("0x%08X",$range->{max});
			$attributes{loweruid} = sprintf("0x%08X",$range->{min});
			
			$writer->print("\n\t");
			$writer->start_element({Name => 'defaultfeaturerange', Attributes => \%attributes});
			$writer->end_element({Name => 'defaultfeaturerange'});
		}
		
		# Root element close
		$writer->print("\n");
		$writer->end_element({Name => 'featuredatabase'});
		
		# Footer
		$writer->end_document();
	}
	else {
		&ERROR("Failed to create $outPath$outputFile file");
	}
}

# Subroutine to create Feature Registry/Features Data file
# @param romimage				 - Rom image number.
# @param featurefile			 - Feature file number.
# @param featurefilename		 - Name of the feature file to be generated.
# @param featureslist			 - Reference to array of hashes containing features to included/excluded.
# @param featuremanager			 - Flag to generate features data file.
# @param singleDATfile           - Flag to generate single features.dat file.
sub createFeatureFile
{
	if($xmlDBHandle == undef) 
	{
		ERROR("No XML Database opened");
		return 0;
	}	
	my ($romimage,$featurefile,$featurefilename,$featureslist,$featuremanager,$singleDATfile) = @_;
	
	# Default setting for singleDATfile flag
	$singleDATfile = 0 if(!defined $singleDATfile);
	
	# Clear the global include/exclude feature list.
	@includeFeatureList = (); 
	@excludeFeatureList = ();


	for(my $k=0;$k<scalar @$featureslist;$k++)
	{
		if(($singleDATfile) || ($featureslist->[$k]{rom}==$romimage && $featureslist->[$k]{cfgfile} == $featurefile))
		{			
			AddToFeatureList($featureslist->[$k],$featuremanager);
		}
	}

	my $features = &featureparser::getFeatures(\@includeFeatureList, \@excludeFeatureList);
	if (!$features)
	{
		ERROR("No feature file generated for ROM_IMAGE[".$romimage."]");
		return 0;
	}
	else
	{
		my $object;
		if ($featuremanager) 
		{
			$object = new featuresdat($xmlDBHandle);
		}
		else
		{
			$object = new featurecfg($xmlDBHandle);
		}		
		return $object->createFile($featurefilename, $features , $featuremanager);
	}	
}

# Subroutine to add the feature specified to the included/excluded feature list
# @param featureData				 - Reference to hash containing feature information (i.e. name/uid,
# 									   included/excluded,SF and UD).  
# @param featuremanager				 - Flag to generate features data file.
sub AddToFeatureList
{
	my ($featureData, $featuremanager) = @_; 	
	
	my %feat = ();
	my $feature = $featureData->{feature};		
	
#	Check if the given value is a feature name.
	my $value = $xmlDBHandle->getFeatureUID($feature);

#	If not a feature, then may be uid value
	if(!defined $value)
	{
		if (!featureparser::IsValidNum($feature)) 
		{
			ERROR("Feature \"".$feature."\" not found in feature list XML");
			return;
		}
		if (&featureparser::ValidateUIDValue($feature))
		{
			my $featureUid = $feature;
			$feature = &featureparser::ConvertHexToDecimal($feature);
			my $featureInfo = $xmlDBHandle->getFeatureInfo($feature);
			if (!$featureInfo)
			{
				ERROR("Feature \"".$featureUid."\" not found in feature list XML");
				return;
			}
			else
			{
				$feat{uid} = $feature;
				$feat{name} = $featureInfo->{name};				
			}
		}
		else
		{
			return;
		}
	}
	else
	{
		$feat{name} = $feature;
		$feat{uid} = $value;		
	}		

	# Set the values of "SF" and "UD" for feature manager.
	if ($featuremanager) 
	{		
		&setFeatureArguments(\%feat,$featureData->{SF},$featureData->{UD});
	}	

	if($featureData->{include} == 1)
	{
		$feat{include} = 1;
		push @includeFeatureList, \%feat;
	}
	else
	{
		$feat{exclude} = 1;
		push @excludeFeatureList, \%feat;
	}
}

# Subroutine to set the values of "SF" and "UD" for the specified feature
# @param feat						- Reference to hash containing information(i.e. name and uid) 
#									  of the specified feature.
# @param SF							- Value of "SF" provided in the iby/oby file. 
# @param UD							- Value of "UD" provided in the iby/oby file.
sub setFeatureArguments
{
	my($feat,$SF,$UD)= @_;
	
	my $featureInfo = $xmlDBHandle->getFeatureInfo($feat->{uid});
	
	# If the values of 'SF' and 'UD' are not provided in the iby/oby file, then take the values
	# from Feature Database XML file.
	if ($SF && featureparser::IsValidNum($SF))  
	{
		$feat->{SF} = &featureparser::ConvertHexToDecimal($SF);
	}
	else 
	{
		# Generate warning if the value of "SF" provided for the feature in iby/oby file
		# is invalid.
		if ($SF) 
		{
			WARN("Invalid SF value \"$SF\" provided for feature \"$feat->{name}\". Defaulting to value provided in XML file");
		}
		$feat->{SF} = &featureparser::ConvertHexToDecimal($featureInfo->{statusflags});			
	}
	if ($UD && featureparser::IsValidNum($UD))  					
	{			
		$feat->{UD} = &featureparser::ConvertHexToDecimal($UD);						
	}
	else 
	{
		# Generate warning if the value of "UD" provided for the feature in iby/oby file
		# is invalid.
		if ($UD) 
		{
			WARN("Invalid UD value \"$UD\" provided for feature \"$feat->{name}\". Defaulting to value provided in XML file");
		}
		$feat->{UD} = &featureparser::ConvertHexToDecimal($featureInfo->{userdata});				
	}				
}

1;
