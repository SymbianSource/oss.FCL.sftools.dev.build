#
# Copyright (c) 1997-2009 Nokia Corporation and/or its subsidiary(-ies).
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

# This package contains routines to read the information from the Component Description Files.
package cdfparser;

# Include Module package to use APIs to parse an XML file.
use genericparser;

require Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(
	CreateCDFFileBinaryMapFromDir
	GetBinaries
	GetCDFFileName
	LoadCDF
	GetDynamicDependencies
	GetBinaryInfo
	GetIncludedFeatureList
	GetExcludedFeatureList
);

use strict;

# Map between the CDF File Name and the corresponding list of binaries
# This is required so that one can fetch the list of binaries for a particular CDF file.
my %binaryCDFFileMap=();

# Include Feature List
# The list of features to be included for a given binary.
my @includeFeatureList;

# Exclude Feature List
# The list of features to be excluded for a given binary.
my @excludeFeatureList;

# List that contains the complete information of each binary
my %binaryInfo=();

my $warning_level = 0;

# Absolute path that contains the CDF Files
my @cdfDirectories;

# To extract the cdf files from the directory specified as input. The default directory is chosen if no 
# input is specified.
sub CreateCDFFileBinaryMapFromDir
{

	my @acdfDirList = @_;
	# To store the list of cdf file names specified under the directory
	my @cdfFileList;

	if ((scalar @acdfDirList) != 0)
	{
		foreach my $acdfDir (@acdfDirList)
		{
			opendir DIR, "$acdfDir";
			if(not grep /$acdfDir/i, @cdfDirectories)
			{
				push @cdfDirectories, $acdfDir;
			}

			push (@cdfFileList, (grep /\.cdf/i, readdir DIR));
			foreach my $filename (@cdfFileList)
			{
				&CreateCDFFileBinaryMap(lc($filename), $acdfDir);
				$binaryCDFFileMap{$filename}{path} = $acdfDir;
			}
		}
	}
}

# To create a mapping between the CDF file name and the corresponding list of binaries
sub CreateCDFFileBinaryMap
{
	my ($cdffilename, $aCdfDir) = @_;

	if( defined $binaryCDFFileMap{$cdffilename} )
	{
		return;
	}

	my $path;
	if( defined $aCdfDir)
	{
		$path = "$aCdfDir\\$cdffilename";
	}
	else
	{
		$path = $cdffilename;
	}

	my $rootNode = &genericparser::getRootElement($path);
	$binaryCDFFileMap{$cdffilename}{root} = $rootNode;

	my @binaryList = &genericparser::getChildElements($rootNode);

	my $binaryInfoRef;
	foreach my $binary (@binaryList)
	{
		my $filename = &genericparser::getAttrValue($binary, "id");
		push @{$binaryCDFFileMap{$cdffilename}{binaries}}, $filename;
# This is required so that one can fetch the CDF file name in which the binary is present
		$binaryInfoRef = \%{$binaryInfo{$filename}};
		$binaryInfoRef->{"filename"} = $cdffilename;
	}
}

# To get the complete list of binaries present in a given CDF file
# Input Parameter : CDF filename
# Returns the complete list of binaries
sub GetBinaries
{
	my $cdffilename = shift;
	if (exists $binaryCDFFileMap{$cdffilename})
	{
		return @{$binaryCDFFileMap{$cdffilename}{binaries}};
	}
	else
	{
		return undef;
	}
}


# To get the name of the CDF file that contains the input binary
# Input Parameter : Binary Name
# Returns the CDF file name
sub GetCDFFileName
{
	my $aBinary = lc(shift);

	if (exists $binaryInfo{$aBinary})
	{
		my $binInfo = \%{$binaryInfo{$aBinary}};
		return $binInfo->{filename};
	}
	else
	{
		return undef;
	}

}

#Loads all the specified CDF files.
sub LoadCDF
{
	my @cdfFileList = @_;

	foreach my $afile (@cdfFileList)
	{
		CreateCDFFileBinaryMap($afile);
		my $rootNode = $binaryCDFFileMap{$afile}{root};

		# Get the total list of files present in the cdf file.
		my @binaryList = &genericparser::getChildElements($rootNode);

		# Hash Reference to the hash map binaryInfo
		my $binaryInfoHashRef;

		foreach my $binaryNode (@binaryList)
		{
			my $fileId = &genericparser::getAttrValue($binaryNode, "id");
			$binaryInfoHashRef = \%{$binaryInfo{$fileId}};
			&setBinaryInfo($binaryInfoHashRef, $binaryNode);
		}
	}

}

#Sets the information of the CDF file to a hash map
sub setBinaryInfo
{
	my ($aBinaryInfoRef, $aBinaryNode) = @_;

	# Set the File attributes
	$aBinaryInfoRef->{"id"}		  = &genericparser::getAttrValue($aBinaryNode, "id");
	$aBinaryInfoRef->{"customisable"} = &genericparser::getAttrValue($aBinaryNode, "customisable");
	$aBinaryInfoRef->{"addressable"}  = &genericparser::getAttrValue($aBinaryNode, "addressable");
	$aBinaryInfoRef->{"compress"}	  = &genericparser::getAttrValue($aBinaryNode, "compress");
	$aBinaryInfoRef->{"type"}	  = &genericparser::getAttrValue($aBinaryNode, "type");
  	$aBinaryInfoRef->{"plugin_name"}  = &genericparser::getAttrValue($aBinaryNode, "plugin_name");
  
  	# Check for the plugin, setting the plugin type as ECOM_PLUGIN
   
  	if (defined $aBinaryInfoRef->{"plugin_name"})
  	{
  		$aBinaryInfoRef->{"IsFoundInCDF"} = 1;
  		$aBinaryInfoRef->{"source"} = "ABI_DIR\\BUILD_DIR\\$aBinaryInfoRef->{id}";
  		$aBinaryInfoRef->{"plugin_name"} =~ s/$aBinaryInfoRef->{plugin_name}/ECOM/;
  	}
  
  	else {

		# Get all the nodes of element 'file'
		my @children = &genericparser::getChildElements($aBinaryNode);

		foreach my $childNode (@children)
		{
			$aBinaryInfoRef->{"IsFoundInCDF"} = 1;

			if (&genericparser::getElementName($childNode) eq "source")
			{
				$aBinaryInfoRef->{"source"} = &genericparser::getElementValue($childNode);
			}

			if (&genericparser::getElementName($childNode) eq "destination")
			{
				$aBinaryInfoRef->{"destination"} = &genericparser::getElementValue($childNode);
			}

			if (&genericparser::getElementName($childNode) eq "features")
			{
				# The children nodes will specify the list of features
				my @aFeatureNodes = &genericparser::getChildElements($childNode);
				foreach my $aFeatureChildNode (@aFeatureNodes)
				{
					# A list of features can be listed out either for supported case or for the prevented case.
					if (&genericparser::getElementName($aFeatureChildNode) eq "supports")
					{
						my @aSupportedFeatureNodes = &genericparser::getChildElements($aFeatureChildNode);
						foreach my $aSuppChildNode (@aSupportedFeatureNodes)
						{
							my %feat = ();
							my $featureName = &genericparser::getAttrValue($aSuppChildNode, "name");
							my $featureUID = &genericparser::getAttrValue($aSuppChildNode, "uid");
							if (defined ($featureName) and ($featureName ne ""))
							{
								$feat{name} = $featureName ;
								$feat{uid} = undef;
							}
							elsif(defined ($featureUID) and ($featureUID ne ""))
							{
								if(&featureparser::ValidateUIDValue($featureUID))
								{
									$featureUID = &featureparser::ConvertHexToDecimal($featureUID);
									$feat{uid} = $featureUID;
									$feat{name} = undef;
								}
								else
								{
									print "The uid value $featureUID specified for the Include feature list for the Binary, $aBinaryInfoRef->{id}, is not a valid number\n";
								}
							}
							else
							{
								print ("Warning: Feature $featureName has both name and Uid mentioned\n") if ($warning_level < 2);
								next;
							}

							$feat{include} = 1;
							push @includeFeatureList, \%feat;
					 
						}
					}
					if (&genericparser::getElementName($aFeatureChildNode) eq "prevents")
					{
						my @aPreventedFeatureNodes = &genericparser::getChildElements($aFeatureChildNode);
						foreach my $aPreventedChildNode (@aPreventedFeatureNodes)
						{
							my %feat = ();
							my $featureName = &genericparser::getAttrValue($aPreventedChildNode, "name");
							my $featureUID = &genericparser::getAttrValue($aPreventedChildNode, "uid");
							if (defined ($featureName) and ($featureName ne ""))
							{
								$feat{name} = $featureName ;
								$feat{uid} = undef;
							}
							elsif(defined ($featureUID) and ($featureUID ne ""))
							{
								if(&featureparser::ValidateUIDValue($featureUID))
								{
									$featureUID = &featureparser::ConvertHexToDecimal($featureUID);
									$feat{uid} = $featureUID;
									$feat{name} = undef;
								}
								else
								{
									print "The uid value $featureUID specified for the Exclude feature list for the Binary, $aBinaryInfoRef->{id}, is not a valid number\n";
								}
							}
							else
							{
								print "Warning: Feature $featureName has both name and Uid mentioned\n" if ($warning_level < 2);
								next;
							}

							$feat{exclude} = 1;
							push @excludeFeatureList, \%feat;
					 
						}
						push @{$aBinaryInfoRef->{"prevents"}}, (&genericparser::getElementValue($aFeatureChildNode));
					}
				}
			}

			if (&genericparser::getElementName($childNode) eq "dynamicdependencies")
			{
				# The children nodes will contain the file name.
				my @aDynDependNodes = &genericparser::getChildElements($childNode);
				
				foreach my $aDynDependChildNode (@aDynDependNodes)
				{
					# There can be a list of binaries for dynamic dependencies
					if (&genericparser::getElementName($aDynDependChildNode) eq "depend")
					{
						push @{$aBinaryInfoRef->{"depend"}}, (&genericparser::getElementValue($aDynDependChildNode));
					}
				}
			}

			if (&genericparser::getElementName($childNode) eq "localisation")
			{
				# The children nodes will contain the language code
				my @aLocalisationNodes = &genericparser::getChildElements($childNode);
				
				foreach my $aLocalisationChildNode (@aLocalisationNodes)
				{
					# There can be a list of binaries for dynamic dependencies
					if (&genericparser::getElementName($aLocalisationChildNode) eq "default")
					{
						$aBinaryInfoRef->{"default"} = &genericparser::getElementValue($aLocalisationChildNode);
					}
					if (&genericparser::getElementName($aLocalisationChildNode) eq "language")
					{
						push @{$aBinaryInfoRef->{"language"}}, (&genericparser::getElementValue($aLocalisationChildNode));
					}
				}
			}

			if (&genericparser::getElementName($childNode) eq "options")
			{
				# The children nodes will contain the option details
				my @aOptionNodes = &genericparser::getChildElements($childNode);
				foreach my $aOptionChildNode (@aOptionNodes)
				{
					if (&genericparser::getElementName($aOptionChildNode) eq "multilinguify")
					{
						$aBinaryInfoRef->{"multilinguify"} = &genericparser::getElementValue($aOptionChildNode);
					}
					if (&genericparser::getElementName($aOptionChildNode) eq "stack")
					{
						$aBinaryInfoRef->{"stack"} = &genericparser::getElementValue($aOptionChildNode);
					}
					if (&genericparser::getElementName($aOptionChildNode) eq "heapmin")
					{
						$aBinaryInfoRef->{"heapmin"} = &genericparser::getElementValue($aOptionChildNode);
					}
					if (&genericparser::getElementName($aOptionChildNode) eq "heapmax")
					{
						$aBinaryInfoRef->{"heapmax"} = &genericparser::getElementValue($aOptionChildNode);
					}
					if (&genericparser::getElementName($aOptionChildNode) eq "fixed")
					{
						$aBinaryInfoRef->{"fixed"} = &genericparser::getElementValue($aOptionChildNode);
					}
					if (&genericparser::getElementName($aOptionChildNode) eq "priority")
					{
						$aBinaryInfoRef->{"priority"} = &genericparser::getElementValue($aOptionChildNode);
					}
					if (&genericparser::getElementName($aOptionChildNode) eq "uid1")
					{
						$aBinaryInfoRef->{"uid1"} = &genericparser::getElementValue($aOptionChildNode);
					}
					if (&genericparser::getElementName($aOptionChildNode) eq "uid2")
					{
						$aBinaryInfoRef->{"uid2"} = &genericparser::getElementValue($aOptionChildNode);
					}
					if (&genericparser::getElementName($aOptionChildNode) eq "uid3")
					{
						$aBinaryInfoRef->{"uid3"} = &genericparser::getElementValue($aOptionChildNode);
					}
					if (&genericparser::getElementName($aOptionChildNode) eq "dll")
					{
						$aBinaryInfoRef->{"dll"} = &genericparser::getElementValue($aOptionChildNode);
					}
					if (&genericparser::getElementName($aOptionChildNode) eq "dlldatatop")
					{
						$aBinaryInfoRef->{"dlldatatop"} = &genericparser::getElementValue($aOptionChildNode);
					}
				}
			}
		}
	}
}

# To get the complete list of information for a given binary
# Input Parameter : Binary
# Returns the detailed information for each binary
sub GetBinaryInfo
{
	my $aBinary = shift;
	my $aBinaryInfoHash = \%{$binaryInfo{$aBinary}};
	if ($aBinaryInfoHash->{IsFoundInCDF})
	{
		return $aBinaryInfoHash;
	}
	return undef;
}

# To get the complete list of dynamic dependencies for a given binary
# Input Parameter : Binary
# Returns the complete list of dynamic dependencies
sub GetDynamicDependencies
{
	my $aBinary = shift;

	my $bin = \%{$binaryInfo{$aBinary}};

	return \@{$bin->{"depend"}};
}

#Returns the included feature list
sub GetIncludedFeatureList
{
	return \@includeFeatureList;
}

#Returns the excluded feature list
sub GetExcludedFeatureList
{
	return \@excludeFeatureList;
}

1;
