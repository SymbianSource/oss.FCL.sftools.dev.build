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

# This package processes the Image Content XML, and creates an OBY file to create a Rom image.
package ImageContentHandler;


require Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(
	ParseImageContentXML
	ProcessImageContent
	AddBinary
	GetBldRomOpts
	SetBldRomOpts
	GenObyFile
	GetObyFiles
	AddBinaryFromOby
	UpdateObyBinaryStaticDep
	PrintMsg
	DumpBinaries
);

use strict;
use genericparser;
use cdfparser;
use Dep_Lister;

#Error list
my @errors;

my %ImageContent=();		#Image details are stored in this tree
my $RootNode;				#The root node of the XML root document element
my @TargetImageList;		#The list of target element nodes in the XML. These are ordered based on their 
							#  imageid (if it is a number, else, based on the availibility of Rom locations within 0..7).
my @binarySelectionArray;	#This array stores the ABI directories to be looked up to select binaries.
my @ImageContentBinaries;	#This list is for the biaries mentioned in Image content XML for 
							#  keywords like, 'primary', 'secondary', 'device', 'extension', 'variant'.

# List that contains information of binary from OBY file. This list is maintained to check if their static dependencies
#	have been included already in Rom.
my %obyFileInfo=();

my $ImageIndex=-1;

my @Includes;		#List of included features. The included feature in this list is a hash table giving the 
					#Uid or the name. These features are collected either from the Image content or the CDF XMLs.
my @Excludes;		#List of excluded features.The excluded feature in this list is a hash table giving the 
					#Uid or the name. These features are collected either from the Image content or the CDF XMLs.

my %DefaultDirs =();#This hash table records the default ABI and the BUILD directories. These are updated in case
					#  the overriding buildrom options are provided e.g., -D_FULL_DEBUG or -D_PLAT=GCCE etc.

my @BPABIPlats = &BPABIutl::BPABIutl_Plat_List; # Add the BPABI Platforms to be added

my $isEcomPlugin=0; # This flag will be set when PLUGINs are provided in the CDF file.

sub ParseImageContentXML
{
	my $XMLFile = shift;

	$XMLFile =~ s/\\/\//g;
	$RootNode = &getRootElement($XMLFile);

	&SetImageDetails(\%ImageContent, $RootNode);
}


my @padding;
#This subroutine traverses the XML tree and stores the fields in the hast table %ImageContent. The keys
#	are the branch names. For target nodes., it stores the nodes themselves in the hash table and doesn't
#	go deeper. These nodes are processed laster. For the other nodes, it keeps traversing recursively.
# There are some special keys used to store the nodes and values in the tree. While storing an XML::DOM
#  node, it sores with the keys 'nodes', while, for storing a value, it is stored with the key 'vals'.
# These are the keys used to retrieve the contents of the tree while generating the final OBY.
sub SetImageDetails
{
	my ($ImageDetailRef, $ImageNode) = @_;
	my @children = &genericparser::getChildElements($ImageNode);
	my $child;
	my $TreeRef;
	my $branch;
	my $parentName = &genericparser::getElementName($ImageNode);
	my $childCnt = scalar @children;

	my ($indent) = join('', @padding);

	my $val = &genericparser::getElementValue($ImageNode);
	$val = Trim($val);
	if($val ne "")
	{
		push @{$ImageDetailRef->{vals}}, $val;
	}

	my $NodeRef;
	foreach $child (@children)
	{
		$branch = &genericparser::getElementName($child);

		$NodeRef = \%{$ImageDetailRef->{$branch}};

		if($branch eq "cdf" and $parentName eq "romscope")
		{
#			Record the romscope node. This node indicates the oby files or cdf files/directories
#			that may be used.
			push @{$NodeRef->{nodes}}, $child;
			next;
		}
		if($branch eq "target" and $parentName eq "romtarget")
		{
			push @{$NodeRef->{nodes}}, $child;
			next;
		}
		if( ($branch =~ /primary/i  ) ||
			($branch =~ /secondary/i) ||
			($branch =~ /extension/i) ||
			($branch =~ /variant/i  ) ||
			($branch =~ /device/i   ) )
		{
			next;
		}
		
		if( $child->hasChildNodes() )
		{
			$NodeRef->{hasChildren} = 1;
			push @padding, ".";
			SetImageDetails($NodeRef, $child);
		}
		else
		{
			$NodeRef->{hasChildren} = 0;
		}

#		Get all attributes...
		my $attribs = &genericparser::getNodeAttributes($child);
		my $attrib;

		my $nodeName;
		my $nodeVal;
		my %attr=();
		my $attrLen = $attribs->getLength;
		for (my $pos = 0; $pos < $attrLen;$pos++)
		{
			$attrib = $attribs->item($pos);
			if(!$attrib)
			{
				next;
			}
			$nodeName = lc ($attrib->getName);
			$nodeVal = lc  ($attrib->getValue);
			$attr{$nodeName}=$nodeVal;

		}
		push @{$NodeRef->{vals}}, \%attr;
	}

	pop @padding;
}

my @romGeometry;			#Array to store all Roms mentioned in RomGeometry
my %romGeometryHash = ();	#This Hash table records the indices in @romGeometry array, keying on their Ids.

my $curRomImageIndex;		#This scalar records the current Rom image being processed. An binary encountered
							#  becomes part of the Rom image corresponding to this partition.

# This subroutine associates the RomGeometry and the RomTarget sub-trees to set indices for the Rom-target
#   nodes.It stores the Image content XML entries for primary/secondary/device/extension/variant keywords.
#   It also stores the features that are included/excluded in Image content XML.

sub ProcessImageContent
{
	my $TotalImages = &ProcessRomGeometry();

	my @trgList;
	if( defined @{$ImageContent{romtarget}{target}{nodes}})
	{
		@trgList = @{$ImageContent{romtarget}{target}{nodes}};
	}

#	Go through the romgeometry to find the location of each image. The valid IDs are 0 through 7.

	foreach my $trg (@trgList)
	{
#		The ID field in romgeometry can be an integer in the range 0 through 7.
#		If it is not a number, its location is assumed as its sequence number
		my $imageid = &genericparser::getAttrValue($trg, "imageid");
		if($imageid =~ /Any/i)
		{
			next;
		}
		elsif(exists $romGeometryHash{$imageid})
		{
			$ImageIndex = $romGeometryHash{$imageid};
			push @{$TargetImageList[$ImageIndex]} , $trg;
		}
	}

#	Romscope - update the maps if the files and directories are mentioned.
	my @romScopeNodes;
	if(defined @{$ImageContent{romscope}{cdf}{nodes}})
	{
		@romScopeNodes = @{$ImageContent{romscope}{cdf}{nodes}};
	}

	my $type;
	my $file;
	my $dir;
	foreach my $aNode (@romScopeNodes)
	{
		$type = &genericparser::getAttrValue($aNode, "type");
		if( $type =~ /dir/i)
		{
			$dir = &genericparser::getElementValue($aNode);
			&cdfparser::CreateCDFFileBinaryMapFromDir($dir);
		}
		elsif($type =~ /file/i)
		{
			$file = &genericparser::getElementValue($aNode);
			&cdfparser::CreateCDFFileBinaryMap($file);
		}
	}

	my $availablePos = 0;
	foreach my $trg (@trgList)
	{
		if(&genericparser::getAttrValue($trg, "imageid") =~ /Any/i)
		{
			while($availablePos < $TotalImages)
			{
				if( !defined($TargetImageList[$availablePos][0]) )
				{
					push @{$TargetImageList[$availablePos]}, $trg;
					last;
				}
				$availablePos++;
			}
		}
	}

	my $pos = 0;
	while( $pos < 8)
	{
		if( defined $TargetImageList[$pos][0] )
		{
#			Record the current Rom image index so that the binaries are included in the corresponding
#			Rom image.
#			The romGeometry and TargetImageList arrays are associated both being indexed on
#			the Rom-image index.

			$curRomImageIndex = $pos;
			&ProcessTarget($pos, \@{$TargetImageList[$pos]});
		}
		$pos++;
	}

#	Pick the primary/secondary/device binaries
	my @nodes = &genericparser::getNodeFromTree($RootNode, "options", "primary", "file");
	if( defined @nodes)
	{
		&SaveImageContentBinaries(\@nodes, "primary");
	}

	@nodes = &genericparser::getNodeFromTree($RootNode, "options", "secondary", "file");
	if( defined @nodes)
	{
		&SaveImageContentBinaries(\@nodes, "secondary");
	}

	@nodes = &genericparser::getNodeFromTree($RootNode, "options", "extension", "file");
	if( defined @nodes)
	{
		&SaveImageContentBinaries(\@nodes, "extension");
	}

	@nodes = &genericparser::getNodeFromTree($RootNode, "options", "variant", "file");
	if( defined @nodes)
	{
		&SaveImageContentBinaries(\@nodes, "variant");
	}

	@nodes = &genericparser::getNodeFromTree($RootNode, "options", "device", "file");
	if( defined @nodes)
	{
		&SaveImageContentBinaries(\@nodes, "device");
	}

	foreach my $imgBin (@ImageContentBinaries)
	{
		&ProcessStaticDep($imgBin->{source});
	}

#	Pick the binary selection order
	if (exists($ImageContent{options}{binaryselectionorder}{vals}))
	{
	    my ($abiDirs) = @{$ImageContent{options}{binaryselectionorder}{vals}};
	    @binarySelectionArray = split(',', $abiDirs);
	    @binarySelectionArray = Trim(@binarySelectionArray);

	}

	my $featureList = &cdfparser::GetIncludedFeatureList();
	foreach my $feature (@$featureList)
	{
		push @Includes, $feature;
	}

	$featureList = &cdfparser::GetExcludedFeatureList();
	foreach my $feature (@$featureList)
	{
		push @Excludes, $feature;
	}
}

#Arrange the Rom-geometry according to their Id when they are numbers. The named images
#are arranged starting from the empty slots in Rom geometry array.
sub ProcessRomGeometry
{
	my $RomImageCount = 0;
	my $pos = 0;
	while($pos < 8)
	{
		$romGeometry[$pos++] = undef;
	}

	my @roms = @{$ImageContent{romgeometry}{image}{vals}};
	$RomImageCount = scalar (@roms);
	my @namedImages;

#	Visit all images and allocate them the indices they mention.
	foreach my $img (@roms)
	{
		if($img->{id} =~ /(\d+)/)
		{
			$pos = $1;
			if( defined($romGeometry[$pos]) )
			{
				print "Error: $romGeometry[$pos]->{id} and $img->{id} cant be allocated the same position\n";
				exit;
			}
			$romGeometry[$pos] = $img;

#			Record the index of this Rom
			$romGeometryHash{$img->{id}} = $pos;
		}
		else
		{
#			These are the named images that are allocated there positions sequentially starting from
#			the first available empty position
			push @namedImages, $img;
		}
	}

#	Revisit the images and allocate the remaining (unallocated) positions.

	$pos = 0;
	my $namedImageCount = scalar (@namedImages);
	my $firstNamedImgIdx = 0;
	my $img;
	while(	($pos < 8) and ($namedImageCount > 0) )
	{
		if( $romGeometry[$pos] )
		{
#			skip the positions already allocated.
			$pos++;
			next;
		}
		$img = $namedImages[$firstNamedImgIdx];
		$romGeometry[$pos] = $img;

#		Record the index of this Rom
		$romGeometryHash{$img->{id}} = $pos;
		
		$pos++;$firstNamedImgIdx++;
		$namedImageCount--;
	}

	return $RomImageCount;
}

my @ObyFileList;

#This subrouting processes the target nodes that may include OBYs/CDFs or features. For CDFs, the satic/dynamic
#  dependencies are evaluated.

sub ProcessTarget
{
	my ($ImgPos , $trgNodesRef) = @_;
	my @cdfFileList;

#	For all the 'target' nodes associated with an image in romgeometry at the given index...
#	The link between a target and an image in romGeometry is the image id. If the imageid
#	of a target is 'Any', then the first available image in romGeometry is allocated to
#	that target.

	foreach my $target (@$trgNodesRef)
	{

#		Fetch any cdfs included within the Image Content file
		my @cdfs = &getNodeFromTree($target, "include","cdf");

		my $type;
		my $file;
		my $dir;
		foreach my $cdfNode (@cdfs)
		{
			$type = &genericparser::getAttrValue($cdfNode, "type");
			
			if( !($type) || ($type eq "file") )
			{
				$file = &genericparser::getElementValue($cdfNode);
				push @cdfFileList, $file;
			}
			elsif($type eq "dir")
			{
				$dir = &genericparser::getElementValue($cdfNode);
				&cdfparser::CreateCDFFileBinaryMapFromDir($dir);
			}
		}

#		Collect all the obey files mentioned in this 'target' node.
		my @obys = &getNodeFromTree($target, "include","obyFile");
		foreach my $obyNode (@obys)
		{
			$file = &genericparser::getElementValue($obyNode);
			push @ObyFileList, $file;
		}

		&CollectFeatures($target, 1, \@Includes);
		&CollectFeatures($target, 0, \@Excludes);
	}

	ProcessCDFList(\@cdfFileList);
}

# This subroutine updates the include or exclude feature list collected from Image content XML.
sub CollectFeatures
{
#	Collect all the features included/excluded in this 'target' node.

	my ($target, $Inc, $IncludeExcludeListRef) = @_;
	my $IncExcStr;
	if($Inc == 1)
	{
		$IncExcStr = "include";
	}
	else
	{
		$IncExcStr = "exclude";
	}

	my @nodes = &getNodeFromTree($target, $IncExcStr,"feature");

	foreach my $node (@nodes)
	{
		my %aFeatureInfo = ();
		my $isValidFeature = 0;
		my $feature = &genericparser::getAttrValue($node, "name");

		if($Inc)
		{
#			Mark the feature included.
			$aFeatureInfo{include} = 1;
		}
		else
		{
#			Mark the feature excluded.
			$aFeatureInfo{exclude} = 1;
		}

		if(defined $feature and $feature ne "")
		{
			$aFeatureInfo{name}= $feature;
			$aFeatureInfo{uid} = undef;
			$isValidFeature = 1;
		}
		else
		{
			$feature = &genericparser::getAttrValue($node, "uid");
			if(!defined $feature or $feature eq "")
			{
				print "Warning: Neither feature name nor uid is defined \n";
			}
			else
			{
				if(&featureparser::ValidateUIDValue($feature))
				{
					$feature = &featureparser::ConvertHexToDecimal($feature);
					$aFeatureInfo{uid}= $feature;
					$aFeatureInfo{name}= undef;
					$isValidFeature = 1;
				}
				else
				{
					print "The uid value $feature specified in the Image Content Description is not a valid number\n";
				}
			}
		}

		if($isValidFeature)
		{
			push @$IncludeExcludeListRef, \%aFeatureInfo;
		}
	}
}

sub DumpImageDetails
{
	my ($HRef) = @_;
	my %hash = %$HRef;
	my $ChildHRef;

	foreach my $Key (keys %hash)
	{
		if($Key eq "hasChildren" || $Key eq "vals")
		{
			next;
		}
		my $indent = join('', @padding);
		&PrintMsg ($indent. $Key);
		if($hash{$Key}{hasChildren} == 1)
		{
			push @padding, ".";
			&PrintMsg ("\n");
			$ChildHRef = \%{$hash{$Key}};
			&DumpImageDetails($ChildHRef);
		}
		elsif( defined ($hash{$Key}{vals}) )
		{
			&PrintMsg ("\nVals $hash{$Key}{vals}\n");
			push @padding, ".";
			$indent = join('', @padding);
			my @array = @{$hash{$Key}{vals}};
			&PrintMsg ("array len = " . scalar(@array) . "\n");
			foreach my $attrib ( @array )
			{
				foreach my $key1 (keys %$attrib)
				{
					&PrintMsg ($indent . $Key. " ". "$key1=$$attrib{$key1}\n");
				}
				&PrintMsg ("\n");
			}
		}
		elsif( defined (@{$hash{$Key}{nodes}}) )
		{
			my $node = $hash{$Key}{nodes}[0];
			&PrintMsg ("{". scalar(@{$hash{$Key}{nodes}})."}\n");
		}
	}
	pop @padding;
}

sub CheckErrors
{
	if($#errors > -1)
	{
		&PrintMsg ("errors..........$#errors \n");
		foreach (@errors)
		{
			&PrintMsg ($_ ."\n");
		}
		exit;
	}
}

my @ImageBinaryList;#2d array storing the list of binaries per rom image
sub AddBinary
{
	my ($binaryName) = @_;
	{
		push @{$ImageBinaryList[$curRomImageIndex]}, $binaryName;
	}
}

sub SetBldRomOpts
{
	my ($key, $value) = @_;
	if( $key eq undef )
	{
#		The default ABI directory is armv5 unless specified otherwise in the buildrom command-line.
#		The default build directory is urel unless specified otherwise in the buildrom command-line.
		$DefaultDirs{ABI_DIR} = 'ARMV5';
		$DefaultDirs{BUILD_DIR}='urel';

		$DefaultDirs{DEST_DIR}= "\\sys\\bin";

	}
	else
	{
#		trim the value for leading/trailing whitespace
		$value = Trim($value);
		$DefaultDirs{$key} = $value;
	}
}

sub Trim()
{
	my @out = @_;
	for (@out) {
		s/^\s+//;
		s/\s+$//;
	}
	return wantarray ? @out : $out[0];
}

sub GetBldRomOpts
{
	my ($key) = @_;
	return $DefaultDirs{$key};
}

sub DumpBinaries
{
	&PrintMsg ("***********Binaries in ROM***********\n");
	my $img_idx = 0;
	while ($img_idx < 8 and defined ($ImageBinaryList[$img_idx]))
	{
		my @list = @{$ImageBinaryList[$img_idx]};
		&PrintMsg ("Image $img_idx has ". scalar (@list ) . " binaries\n");
		foreach my $bin (@list)
		{
			&PrintMsg ("file[$img_idx]=$bin\n");
		}
		$img_idx++;
	}

	&PrintMsg ("***********END***********\n");
}

sub PrintMsg
{
	my ($msg) = @_;
	print "$msg";
}

# This subroutine is used to generate OBY-contents based on contents of the Image content XML. The image content XML 
#   may have, in turn, included other OBYs/CDFs. These contents are appended to the Phase-I OBY file (where, the 
#   Phase-I OBY file is generated by the preprocessor which is the conglomeration of all the buildrom supplied OBY files).
sub GenObyFile
{
	my ($ObyFileName) = @_;
	open (OBYFH, ">>$ObyFileName") or die("* Can't open $ObyFileName\n");
	my $binRef;
	my $line;
	my $index;
	my $new_src_path;
	my $exec_src_path = $ENV{EPOCROOT};#This is the Executable source path
	$exec_src_path .= "epoc32\\release\\";
	my $abidir = $DefaultDirs{ABI_DIR};
	my $blddir = $DefaultDirs{BUILD_DIR};

	GenObyHeader(*OBYFH);

	for($index = 0;$index < 8;$index++)
	{
		if( !defined $romGeometry[$index] )
		{
			next;
		}

		$line = "rom_image $index ";
		$line .= $romGeometry[$index]{name} . " ";
		$line .= "size=" . $romGeometry[$index]{size} . " ";
		if( $romGeometry[$index]{type} =~ /nonxip/)
		{
			$line .= " non-xip ";
		}
		else
		{
			$line .= " xip ";
		}

		$line .= $romGeometry[$index]{compression} . " ";
		if($romGeometry[$index]{extension} eq "yes")
		{
			$line .= " extension ";
		}

		$line .= "\n";

		print OBYFH $line;

		$line = "ROM_IMAGE[$index] {\n";	#Start of contents of this image
		print OBYFH $line;

		foreach my $binary (@{$ImageBinaryList[$index]}) {
			$binRef = &cdfparser::GetBinaryInfo($binary);
			if( defined ($binRef) and $binRef->{IsFoundInCDF})
			{
				if(exists $binRef->{default})
				{
					$line = "DEFAULT_LANGUAGE $binRef->{default} \n";
					print OBYFH "$line";
				}
				
				if(exists $binRef->{language})
				{
					my $langCodes = $binRef->{language};
 					foreach my $lang (@$langCodes)
					{
						$line = "LANGUAGE_CODE $lang \n";
						print OBYFH "$line";
					}
				}

#				Replace the BUILD_DIR with udeb or urel
#				Default BUILD_DIR is urel and can be overridden by using cmd line option '_FULL_DEBUG'
#				If a binary is to be picked always from udeb, then the src path in CDF must be mentioned
#				as udeb e.g. <source>abi_dir\udeb\drtaeabi.dll</source>, in which case, the mentioned dir
#				is picked as it is.

				$new_src_path = $binRef->{source};

				$new_src_path =~ s/ABI_DIR/$abidir/i;
				$new_src_path =~ s/BUILD_DIR/$blddir/i;
				$new_src_path =~ s/DEBUG_DIR/udeb/i;

				$new_src_path =~ s/epocroot/EPOCROOT/;
				$new_src_path =~ s/zresource/ZRESOURCE/;
				$new_src_path =~ s/zprivate/ZPRIVATE/;
				$new_src_path =~ s/zsystem/ZSYSTEM/;

				
				my $FileFound = 0;
				
				if($binRef->{IsExecutable})
				{
					$new_src_path = $exec_src_path . $new_src_path;
					if(!-f $new_src_path)
					{
						foreach my $newAbiDir (@binarySelectionArray)
						{
							$new_src_path =~ s/$abidir/$newAbiDir/i;
							if(-f $new_src_path)
							{
								$FileFound = 1;
								last;
							}
							$abidir = $newAbiDir;
						}

						if( !$FileFound )
						{
							$FileFound = fallback($abidir, \$new_src_path);
  							if( !$FileFound )
							{
								print "Missing file $binRef->{source} \n";
								$new_src_path = $binRef->{source};
							}

						}
					}
#					compress options
					if(exists $binRef->{compress} and ($binRef->{compress} eq "uncompress") )
					{
						$line = "fileuncompress=";
					}
					elsif($binRef->{compress} eq "compress")
					{
						$line = "filecompress=";
					}
					elsif( exists $binRef->{dll})
					{
						$line = "dll=";
					}
#					Checks the plugin type
					elsif( exists $binRef->{type} and $binRef->{type} eq "plugin")
					{
						if (exists $binRef->{plugin_name})
						{
							$isEcomPlugin=1;
							$line = "__$binRef->{plugin_name}_PLUGIN(ABI_DIR\\BUILD_DIR,ECOM_BIN_DIR,DATAZ_,ECOM_RSC_DIR,$binRef->{id},$binRef->{id})\n";
						}
					}
					else
					{
						$isEcomPlugin=0;
						$line = "file=";
					}

					if (!$isEcomPlugin)
					{
						$line .= $new_src_path . " ";
						$line .= $binRef->{destination};
					}


#					stack,heap,fixed,priority,uid,dll,dlldatatop
					if( exists $binRef->{stack})
					{
						$line .= " stack " . $binRef->{stack};
					}
					if( exists $binRef->{heapmin})
					{
						$line .= " heapmin " . $binRef->{heapmin};
					}
					if( exists $binRef->{heapmax})
					{
						$line .= " heapmax " . $binRef->{heapmax};
					}
					if( exists $binRef->{fixed})
					{
						$line .= " fixed";
					}
					if( exists $binRef->{priority})
					{
						$line .= " priority " . $binRef->{priority};
					}
					if( exists $binRef->{uid1})
					{
						$line .= " uid1 " . $binRef->{uid1};
					}
					if( exists $binRef->{uid2})
					{
						$line .= " uid2 " . $binRef->{uid2};
					}
					if( exists $binRef->{uid3})
					{
						$line .= " uid3 " . $binRef->{uid3};
					}
					if( exists $binRef->{dlldatatop})
					{
						$line .= " dlldatatop ". $binRef->{dlldatatop}; 
					}
					if( exists $binRef->{customisable} and $binRef->{customisable} eq "true")
					{
						$line .= " patched ";
					}
				}
				else
				{
					my $type = $binRef->{type};
					if($type =~ /normal/i)
					{
						$line = "data=";
					}
					if($type =~ /aif/i)
					{
						$line = "aif=";
					}
					elsif($type =~ /compressedbitmap/i)
					{
						$line = "compressed-bitmap=";
					}
					elsif($type =~ /autobitmap/i)
					{
						$line = "auto-bitmap=";
					}
					elsif($type =~ /bitmap/i)
					{
						$line = "bitmap=";
					}

					if(exists $binRef->{multilinguify})
					{
						my $extension;
						my $srcNameWithoutExt;
						my $dstNameWithoutExt;

						if($new_src_path =~ /(.*)\.(.*)/)
						{
							$srcNameWithoutExt = $1;
							$extension = $2;
						}
						if($binRef->{destination} =~ /(.*)\.(.*)/)
						{
							$dstNameWithoutExt = $1;
						}

						$line .= "MULTI_LINGUIFY(";
						$line .= $extension . " ";
						$line .= $srcNameWithoutExt . " ";
						$line .= $dstNameWithoutExt;
						$line .= ") ";
					}
					else
					{
						$line .= $new_src_path . " ";
						$line .= $binRef->{destination};
					}
				}

				$line .= "\n";
				print OBYFH $line;
			}
			else
			{
				#Check if the binary is from ImageContent XML file.
				my $imagecontentbin = 0;
				foreach my $bin (@ImageContentBinaries) {
					my $source;
					if( $bin->{source} =~ /.*\\(\S+)/)
					{
						$source = $1;
					}
					if (grep /$binary/i, $source) {#Skip the binary that is already included in the OBY Header
						$imagecontentbin = 1;
						next;
					}
				}

				if ($imagecontentbin) {
					next;
				}
				my $obyInfo = &ImageContentHandler::GetObyBinaryInfo($binary);
				if(!defined $obyInfo)
				{
					$line = "file=" . $exec_src_path. $DefaultDirs{ABI_DIR}. "\\" . $DefaultDirs{BUILD_DIR}. "\\". $binary. " ";
					$line .= $DefaultDirs{DEST_DIR}. "\\". $binary;
					$line .= "\n";
					print OBYFH $line;
				}
			}
		}
		$line = "\n}\n";
		print OBYFH $line;
	}
	close OBYFH;
}

#Sets default target to ARMV5 directory if the requested binary is not found
sub fallback{
	
	my ($abidir, $abiFileRef) = @_;
	my $foundFile=0;
	foreach my $BpabiPlat (@BPABIPlats)
	{
		if ($$abiFileRef =~ /^(.*)\\$BpabiPlat\\(.*)$/)
		{
			$$abiFileRef =~ s/$abidir/ARMV5/i;
			if(-f $$abiFileRef)
			{
				$foundFile = 1;
				last;
			}
		}
	}
	return $foundFile;
}

# This subroutine generates the Rom configuration details like, 'bootbinary', 'romlinearbase', romalign,
#   'kerneldataaddress', 'kernelheapmin' etc.
sub GenObyHeader
{
	my ($fh) = @_;
	my $line;

#	version
	if( defined @{$ImageContent{version}{vals}})
	{
		my $ver = @{$ImageContent{version}{vals}}[0];
		if(defined $ver)
		{
			$line = "version=$ver\n";
			print $fh $line;
		}
	}

#	romchecksum
	if( defined @{$ImageContent{romchecksum}{vals}})
	{
		my $cksum = @{$ImageContent{romchecksum}{vals}}[0];
		if(defined $cksum)
		{
			$line = "romchecksum=$cksum\n";
			print $fh $line;
		}
	}

#	time
	if( defined @{$ImageContent{time}{vals}})
	{
		my $time = @{$ImageContent{time}{vals}}[0];
		if(defined $time)
		{
			$line = "time=ROMDATE $time\n";
			print $fh $line;
		}
	}


#	The Binary selection order
	if(scalar @binarySelectionArray )
	{
		my $abilist = join (',', @binarySelectionArray);
		$line = "\nBINARY_SELECTION_ORDER $abilist\n";
		print $fh $line;
	}

#	trace
	if( defined @{$ImageContent{options}{trace}{vals}})
	{
		my @traceFlags = @{$ImageContent{options}{trace}{vals}};
		if(scalar @traceFlags)
		{
			$line = "trace $traceFlags[0]\n";
			print $fh $line;
		}
	}

#	The bootbinary
	if( defined @{$ImageContent{options}{bootbinary}{vals}})
	{
		my $binary;
		my @bootbin = @{$ImageContent{options}{bootbinary}{vals}};
		if(scalar @bootbin)
		{
			$binary = $bootbin[0];
			$binary =~ s/abi_dir/ABI_DIR/;
 			$line = "bootbinary=$binary\n";
			print $fh $line;
		}
	}


#	dataaddress
	if( defined @{$ImageContent{options}{dataaddress}{vals}})
	{
		my @dataAddr = @{$ImageContent{options}{dataaddress}{vals}};
		if(scalar @dataAddr)
		{
			$line = "dataaddress=$dataAddr[0]\n";
			print $fh $line;
		}
	}

#	debugport
	if( defined @{$ImageContent{options}{debugport}{vals}})
	{
		my @dgbPort = @{$ImageContent{options}{debugport}{vals}};
		if(scalar @dgbPort)
		{
			$line = "debugport=$dgbPort[0]\n";
			print $fh $line;
		}
	}

#	defaultstackreserve
	if( defined @{$ImageContent{options}{defaultstackreserve}{vals}})
	{
		my @defStackRes = @{$ImageContent{options}{defaultstackreserve}{vals}};
		if(scalar @defStackRes)
		{
			$line = "defaultstackreserve=$defStackRes[0]\n";
			print $fh $line;
		}
	}

#	wrapper
	if( defined @{$ImageContent{options}{wrapper}{vals}})
	{
		my %tbl = @{$ImageContent{options}{wrapper}{vals}}[0];
		if(exists $tbl{epoc})
		{
			$line = "epocwrapper\n";
			print $fh $line;
		}
		elsif(exists $tbl{coff})
		{
			$line = "coffwrapper\n";
			print $fh $line;
		}
		elsif(exists $tbl{none})
		{
			$line = "nowrapper\n";
			print $fh $line;
		}
	}

#	kernel options
	my $val;
	if( defined @{$ImageContent{options}{kernel}{name}{vals}})
	{
		$val = @{$ImageContent{options}{kernel}{name}{vals}}[0];
		$line = "kernelromname=$val\n";
		print $fh $line;
	}
	if( defined @{$ImageContent{options}{kernel}{dataaddress}{vals}})
	{
		$val = @{$ImageContent{options}{kernel}{dataaddress}{vals}}[0];
		$line = "kerneldataaddress=$val\n";
		print $fh $line;
	}
	if( defined @{$ImageContent{options}{kernel}{trace}{vals}})
	{
		$val = @{$ImageContent{options}{kernel}{trace}{vals}}[0];
		$line = "kerneltrace $val\n";
		print $fh $line;
	}
	if( defined @{$ImageContent{options}{kernel}{heapmin}{vals}})
	{
		$val = @{$ImageContent{options}{kernel}{heapmin}{vals}}[0];
		$line = "kernelheapmin=$val\n";
		print $fh $line;
	}
	if( defined @{$ImageContent{options}{kernel}{heapmax}{vals}})
	{
		$val = @{$ImageContent{options}{kernel}{heapmax}{vals}}[0];
		$line = "kernelheapmax=$val\n";
		print $fh $line;
	}
#	romlinearbase
	if( defined @{$ImageContent{options}{romlinearbase}{vals}})
	{
		my @romLinBase = @{$ImageContent{options}{romlinearbase}{vals}};
		if(scalar @romLinBase)
		{
			$line = "romlinearbase=$romLinBase[0]\n";
			print $fh $line;
		}
	}

#   romalign
	if( defined @{$ImageContent{options}{romalign}{vals}})
	{
		my @romAlign = @{$ImageContent{options}{romalign}{vals}};
		if(scalar @romAlign )
		{
			$line = "romalign=$romAlign[0]\n";
			print $fh $line;
		}
	}




#	autosize keyword with the block size
	if( defined @{$ImageContent{options}{autosize}{vals}})
	{
		my @autoSz = @{$ImageContent{options}{autosize}{vals}};
		if(scalar @autoSz )
		{
			$line = "autosize=$autoSz[0]\n";
			print $fh $line;
		}
	}

#	coreimage keyword with the coreimage name.
	if( defined @{$ImageContent{options}{coreimage}{vals}})
	{
		my @coreImg = @{$ImageContent{options}{coreimage}{vals}};
		if(scalar @coreImg)
		{
			$line = "coreimage=$coreImg[0]\n";
			print $fh $line;
		}
	}



	foreach my $imgBin (@ImageContentBinaries)
	{
		$line = $imgBin->{keyword};
		my $srcPath = $imgBin->{source};
		$srcPath =~ s/abi_dir/ABI_DIR/;
		$srcPath =~ s/kernel_dir/KERNEL_DIR/;
		$srcPath =~ s/debug_dir/DEBUG_DIR/;
		$srcPath =~ s/build_dir/BUILD_DIR/;
		if(! ($imgBin->{keyword} =~ /secondary/i) )
		{
#			VARID mentioned for primary, device, extension and variant keywords.
			$line .= "[VARID]" ;
		}
		$line .= "=" . $srcPath . "\t\t" .  $imgBin->{destination};
		for my $key (keys %$imgBin)
		{
			if( ($key =~ /keyword/i) ||
				($key =~ /source/i) ||
				($key =~ /destination/i))
			{
#				These keys are already taken care.
				next;
			}

#			Write the rest of the keywords if any, (e.g., 'fixed' or HEAPMAX(0x40000) ) to the oby line.
			$line .= " ".($key);
			if( defined $imgBin->{$key})
			{
				$line .= "(". $imgBin->{$key}. ") ";
			}
		}
		print $fh "$line\n";
	}
}

sub GetObyFiles
{
	return \@ObyFileList;
}

sub GetBinarySelectionOrder
{
	return \@binarySelectionArray;
}

sub GetFeatures()
{
	my %FeatureMap = ();
	my @FeatList;
	my $featRef;
	my $uid;
	foreach my $feat (@Includes)
	{
		if($feat->{name})
		{
			$uid = &featureparser::getFeatureUID($feat->{name});
			if(!defined $uid)
			{
				print "Error: Feature $feat->{name} not found in feature list XML\n";
				next;
			}
			$feat->{uid} = $uid;
		}
		else
		{
			$uid = $feat->{uid};
			if(!&featureparser::getFeatureInfo($uid))
			{
				print "Error: Feature Uid $uid not found in feature list XML\n";
				next;
			}
		}

		$featRef = $FeatureMap{$uid};
		if( $featRef->{include} == 1 )
		{
#			Already added to the final feature list
		}
		else
		{
			$FeatureMap{$uid} = $feat;
			push @FeatList, $feat;
		}
	}

	foreach my $feat (@Excludes)
	{
		if($feat->{name})
		{
			$uid = &featureparser::getFeatureUID($feat->{name});
			if(!defined $uid)
			{
				print "Error: Feature $feat->{name} not found in feature list XML\n";
				next;
			}
			$feat->{uid} = $uid;
		}
		else
		{
			$uid = $feat->{uid};
			if(!&featureparser::getFeatureInfo($uid))
			{
				print "Error: Feature Uid $uid not found in feature list XML\n";
				next;
			}
		}

		$featRef = $FeatureMap{$uid};
		if( $featRef->{include} == 1 )
		{
			print "Error:The feature Uid $uid was added into the include as well as exclude list\n";
			next;
		}
		elsif($featRef->{exclude} == 1)
		{
#			Already added to the final feature list
			next;
		}
		else
		{
			$FeatureMap{$uid} = $feat;
			push @FeatList, $feat;
		}
	}
	return \@FeatList;
}

sub AddBinaryFromOby
{
		my $aBinary = lc shift;
	my $aFullPath = lc shift;

	my $bin = \%{$obyFileInfo{$aBinary}};
	$bin->{IsFoundInOby}  = 1;
	$bin->{fullpath} = $aFullPath;
}

sub GetObyBinaryInfo
{
	my $aBinary = lc shift;

	my $aBinaryInfoHash = \%{$obyFileInfo{$aBinary}};

	if( $aBinaryInfoHash->{IsFoundInOby} == 1)
	{
		return $aBinaryInfoHash;
	}
	return undef;
}

sub UpdateObyBinaryStaticDep
{
#	Go through the files added from Oby to see if any of their static
#	dependencies need to be resolved.

	foreach my $obyBin (keys %obyFileInfo)
	{
		if(!defined (&VisitedBinaryInfo($obyBin)) )
		{
			&ProcessStaticDep($obyFileInfo{$obyBin}{fullpath});
		}
	} 
}

sub SaveImageContentBinaries
{
	my ($binaryListRef, $aKeyword) = @_;
	
	foreach my $node (@$binaryListRef)
	{
		my %binInfo = ();

#		The keywords being primary, secondary, extension, variant and device
		$binInfo{keyword} = $aKeyword;

		my @children = &genericparser::getChildElements($node);

		foreach my $child (@children)
		{
			my $name = &genericparser::getElementName($child);
			my $val = &genericparser::getElementValue($child);
			$binInfo{$name} = $val;
		}
		push @ImageContentBinaries, \%binInfo;
	}
}

my %VisitedBinaries = ();
my @RomIncludeList;

sub ProcessCDFList {

	my ($CDFListRef) = @_;

	foreach my $cdf (@$CDFListRef)
	{
		&LoadFromCDF($cdf);
	}

}

my @padding ;
sub LoadFromCDF
{
	my $cdf;
	my $binFile;

	my @BinList;
	($cdf, $binFile) = @_;

#Load the XML and get its contents
	cdfparser::LoadCDF($cdf);

#Get all binaries from the mdf
	(@BinList) = &cdfparser::GetBinaries($cdf);

	my $DynBinListRef;
	my $aBinary;
	my $aFile;

	my $VisitedBinaryInfoHash;
	my $indent = join('', @padding);
	my $binInfo;
	foreach $aBinary (@BinList)
	{
		$VisitedBinaryInfoHash = &VisitedBinaryInfo($aBinary);
		if($VisitedBinaryInfoHash)
		{
			next;
		}
		else
		{
			$VisitedBinaryInfoHash = \%{$VisitedBinaries{$aBinary}};
		}

		&ImageContentHandler::AddBinary($aBinary);

		$VisitedBinaryInfoHash->{Marked} = 1;
		push @RomIncludeList, $aBinary;

#		Include the dynamic dependencies.
		($DynBinListRef) = cdfparser::GetDynamicDependencies($aBinary);
		foreach $aFile (@$DynBinListRef)
		{
			if(grep $aFile, @BinList)
			{
#				the dynamic dependency is found in the same cdf file which
#				is already loaded.
				next;
			}

			my $new_cdf = cdfparser::GetCDFFileName($aFile);
#			In case there is no cdf describing this binary, ignore it.
			if( defined $new_cdf )
			{
				push @padding, ".";
				LoadFromCDF($new_cdf, $aFile);
			}
		}
		$binInfo = cdfparser::GetBinaryInfo($aBinary);
		&ProcessStaticDep($binInfo->{source}, $aBinary);
	}
}

sub ProcessStaticDep
{
	my ($aBinary) = @_;

	my $aAbsFile;
#	Include the static dependencies.

	my $dir = "$ENV{EPOCROOT}epoc32\\release\\";
	my $abidir = &ImageContentHandler::GetBldRomOpts("ABI_DIR");
	my $blddir = &ImageContentHandler::GetBldRomOpts("BUILD_DIR"); 

	if($aBinary =~ /(.*)\\.*/)
	{
		$aBinary =~ s/ABI_DIR/$abidir/i;
		$aBinary =~ s/BUILD_DIR/$blddir/i;
		$aBinary =~ s/DEBUG_DIR/udeb/i;
	}
	else
	{
		$dir .= $abidir . "\\";
		$dir .= $blddir. "\\";
	}
	$aAbsFile = $dir. $aBinary;

	if(!-f $aAbsFile)
	{
#		While evaluating the static dependency, check if the file is found in the 
#		default abi directory. Otherwise, look into the binary selection order.
		my $binSelOrderRef = &ImageContentHandler::GetBinarySelectionOrder();
		my $foundFile = 0;
		foreach my $newAbiDir (@$binSelOrderRef)
		{
			$aAbsFile =~ s/$abidir/$newAbiDir/i;
			if(-f $aAbsFile)
			{
				$foundFile = 1;
				last;
			}
			$abidir = $newAbiDir;
		}
		if($foundFile == 0)
		{
#While evaluating the static dependency, check if the file is found in the 
#default abi directory. Otherwise, fallback to the default ARMV5 directory.
			$foundFile = fallback($abidir, \$aAbsFile);
			if($foundFile == 0)
			{
				return;
			}

		}
	}

#	Collect the static dependencies of this binary.
	my (@StatDepsList) = &Dep_Lister::StaticDeps($aAbsFile);

#	Remove the path portion from the file name if found to get the filename.
#	This is the key into the BinaryInfo map maintained by cdfparser.
	my $filename;

	if( $aBinary =~ /.*\\(\S+)/)
	{
		$filename = $1;
	}
	else
	{
		$filename = $aBinary;
	}

	my $binaryInfoRef = cdfparser::GetBinaryInfo($filename);

	if( defined $binaryInfoRef)
	{
#		Mark the binary it it is a valid E32 executable.
		if(defined @StatDepsList)
		{
			$binaryInfoRef->{IsExecutable} = 1;
		}
		else
		{
			$binaryInfoRef->{IsExecutable} = 0;
		}
	}

	my $VisitedBinaryInfoHash;
	foreach my $aFile (@StatDepsList)
	{
		my $new_cdf = cdfparser::GetCDFFileName($aFile);

		if(defined($new_cdf))
		{
			LoadFromCDF($new_cdf, $aFile);
		}
		else
		{
#			Include the static dependencies even if there is no mdf describing this binary

			$VisitedBinaryInfoHash = &VisitedBinaryInfo($aFile);
			if( !defined ($VisitedBinaryInfoHash) )
			{
				$VisitedBinaryInfoHash = \%{$VisitedBinaries{$aFile}};
				$VisitedBinaryInfoHash->{Marked} = 1;
				&ImageContentHandler::AddBinary($aFile);
				&ProcessStaticDep($aFile);
			}
			else
			{
			}
		}
	}
}

sub VisitedBinaryInfo
{
	my ($aBinary) = @_;
	my $VisitedBinaryInfoHash = \%{$VisitedBinaries{$aBinary}};
	if($VisitedBinaryInfoHash->{Marked} == 1)
	{
		return $VisitedBinaryInfoHash;
	}
	return undef;
}

1;
