#
# Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# This package contains fuctions specific to data drive image generation
#


package datadriveimage;

require Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(
			createDirectory 
			deleteDirectory 
			checkInArray 
			setPath 
			locateStubsisfiles 
			copyFilesToFolders 
			checkForSisFile 
			copyNonSisFiles
			invokeInterpretsis
			invokeReadImage
			compareArrays
			dumpDatadriveObydata
			TraverseDir
			writeDataToFile
			generate_datadriveheader
			checkForWhiteSpace
			reportError
);

use strict;
use File::Path;		# Module to provide functions to remove or create directories in a convenient way.
use File::Copy;		# Module to provide functions to copy file(s) from source to destination.

use Pathutl;
use Cwd;			# Module to provide functions for determining the pathname of the current working directory.

# This fuction is used primiarly to check for whitespace in the location for "zdrive" / "datadrive" folder creation,
# specified by the user, if yes then it returns one, else zero
sub checkForWhiteSpace
{
	my ($dirLoc,$dirName) = @_;
	if( $dirLoc =~ m/ / )
	{
		print "* Warning: $dirLoc contains whitespace, hence $dirName will be created in default location \n";
		return 1;
	}
	else
	{
		return 0;
	}
}


# This function reports the appropriate meassage supplied to it
# and does a exit if and only if keepgoing option is disabled.
sub reportError
{
	my( $message,$keepgoingOpt ) = @_;
	# print the specified meassage.
	print STDERR "$message \n";
	# bail out, if keepgoing option is not set.
	exit(1) if (!$keepgoingOpt);
}

# generate header for final datadrive oby file.
sub generate_datadriveheader
{
	my ($idx,$datadriveimage) = @_;
	my $header;
	$header =  "dataimagename=$$datadriveimage[$idx]{name}.img\n";
	$header .= "dataimagefilesystem=$$datadriveimage[$idx]{fstype}\n";

	# check whether the size of the image has been mentioned
	if(defined($$datadriveimage[$idx]{size}))
	{
		$header .= "dataimagesize=$$datadriveimage[$idx]{size}\n\n";
	}
	return $header;
}

# Create the specified directory by making use of mkpath function 
# from File::Path module.
sub createDirectory
{
	my($dir) = @_;
	if( !-d $dir )
	{
		mkpath($dir);
		if (! -e $dir) 
		{
			print ("ERROR: Couldn't create $dir\n");
		}
	}
}

# check if the given file is a reg file or ctl file or a txt file
# if it is any of these files then return true else false.
# This check is need since these three files or not valid not valid e32 file 
# and hence needs to be placed as an data file inside the image.
sub checkRegCtlFiles
{
	my ($fileName) = @_;

	# check whether the file has "reg","ctl" or "txt" extension.
	if( $fileName =~/\.(reg|ctl|txt)$/i )
	{
		return 1;		
	}
	else
	{
		return 0;
	}
}

# delete the given directory by making use of rmtree function 
# from File::Path module.
sub deleteDirectory
{
	my($dir,$verboseOpt) = @_;
	# check whether the directory exists.
	if( -d $dir )
	{
		print("found $dir directory \n") if($verboseOpt);
		if(rmtree($dir))
		{
			print("$dir directory deleted \n") if($verboseOpt);
			return 0;
		}
		else
		{
			print("$dir directory could'nt be deleted \n") if($verboseOpt);
			return 1;
		}
	}
}

# check for processed data drive image index.
# if there is a match return one else return zero.
# this check is done in order to ensure data drive image index is not repeated.
sub checkInArray
{
	my($array, $value) = @_;
	foreach my $aLine(@$array)
	{
		if( $aLine eq $value )
		{
			return 0;
		}
	}
	return 1;
}

# set the path for the given directory.
sub setPath
{
	my($dirName) = @_;
	# get the working directory.
	my $curWorkingDir = getcwd;
	# substitute slash with double backward slash.
	$curWorkingDir =~ s/\//\\/g;
 	#if $curWorkingDir already has trailing '\', don't include it again 
 	if( $curWorkingDir =~ /\\$/)
 	{
 		return $curWorkingDir.$dirName;
 	}
 	else
 	{
 		return $curWorkingDir."\\".$dirName;
 	}
}

# create directory and copy respective file on to that directory.
# is there is a problem while copying files from source to destination
# then bail out if and only if keep going option is disabled.
sub copyFilesToFolders
{
	my ($source,$dest,$dir,$verboseOpt) = @_;
	$source =~ s/\"//g; # remove double quotes from the string. 
	my $destFileName = "";	# name of the destination file.
	$dest =~ s/\"//g;	# remove double quotes from the string. 
	my $destDirectory = $dest;
	# strip the last substring to get destination file 
	if ($dest=~/.*\\(\S+)/) 
	{
		$destFileName = $1;
	}
	else
	{
		$destFileName = $dest;
	}
	#get the destination directory along with full path
	#when "[" and "]" appear in the file name we need add "\" before "[" or "]"
	#like this: [filename].exe translate to \[filename\].exe 
	if($destFileName =~ /\[|\]/)
	{
		my $tempFileName = $destFileName;
		$tempFileName =~ s/(\[|\])/\\$1/g;
		$destDirectory =~ s/$tempFileName//;
	}
	else
	{	
		$destDirectory =~ s/$destFileName//;
	}
	my $destfile = $dir."\\".$dest;
	my $createdir = $dir."\\".$destDirectory ;

	# create the specified directory.
	&createDirectory($createdir);
	if (!copy($source,$destfile))
	{
		warn "warning : $source file could not found \n";
		return 0;
	}
	else
	{
		print "$source copied to $destfile\n" if($verboseOpt);
		return $destfile;
	}
}

# Make a check for sisfile keyword by reading the specified iby/oby file,
# if sisfile keyword is found then push the respective image on to the respective array 
# and return true.
sub checkForSisFile 
{
	my($obyfile,$sisFileArray,$sisFilePrestent) = @_;
	# open the oby file in read only mode. 
	open (DATA, "< $obyfile") or die("* Can't open $obyfile\n");
	while  (my $line =<DATA>)
	{
		if($line =~ /^\s*sisfile\s*=\s*(\S+)/i )
		{
			# found a sis file.
			$$sisFilePrestent = 1;
			# push sis file on to stack.
			push(@$sisFileArray,$1);
			next;
		}
	}
	close(DATA);
	return $$sisFilePrestent;
}

# Make a check for zdriveimagename keyword by reading the specified iby/oby file,
# if zdriveimagename keyword is found then push the respective image on to the respective array 
# and return true.
sub checkForZDriveImageKeyword 
{
	#$ZDriveImageFilePresent
	my($obyfile,$ZDriveImageKeywordArray,$ImageFilePresent) = @_;
	# open the oby file in read only mode. 
	open (DATA, "< $obyfile") or die("* Can't open $obyfile\n");
	while  (my $line =<DATA>)
	{
		if($line =~ /^\s*zdriveimagename\s*=\s*(\S+)/i )
		{
			# found a Z Drive Image file.
			$$ImageFilePresent = 1;
			# push sis file on to stack.
			push(@$ZDriveImageKeywordArray,$1);
			next;
		}
	}
	close(DATA);
	return $$ImageFilePresent;
}

# copy all non-sis file(s) on to prototype data drive folder 
# which are mentioned under input data drive iby/oby file.
sub copyNonSisFiles
{
	my($dir,$obyfile,$nonsisFileArray,$renameArray,$aliasArray,$hideArray,$verboseOpt,$keepgoingOpt) = @_;
	open (OBEY ,$obyfile) or die($obyfile."\n");
	while(my $line =<OBEY>) 
	{
		if( $line =~ /^(file|data)\s*=\s*(\S+)\s+(\S+)/i )
		{
			my $keyWord=$1;
			my $source=$2;
			my $dest=$3;

			if( $source !~ /(\S+):(\S+)/ )
			{ 
				$source = Path_Drive().$2;
			}
			my $var = &copyFilesToFolders( $source,$dest,$dir,$verboseOpt);
			if($var)
			{
				$var = $keyWord."=".$var;
				$line =~ s/^(\S+)=(\S+)/$var/;
				push(@$nonsisFileArray,$line);
			}
			else
			{
				exit(1)if(!$keepgoingOpt);
			}
		}
		elsif($line =~ /^rename\s+(\S+)\s+(\S+)/i)
		{
			my $oldFile = $dir.$1;	# existing-file
			my $newFile = $dir.$2;	# destination-file
			print"found rename keyword\nrenaming $oldFile to $newFile\n" if ($verboseOpt);
			if ( rename($oldFile, $newFile) )
			{
				# push the line on to the stack.
				push(@$renameArray,$1."\t".$2."\n");
			}
			else
			{
				&datadriveimage::reportError("* Warning : can't rename $oldFile to $newFile: $!",$keepgoingOpt);
			}
		}
		elsif($line =~ /^alias\s+(\S+)\s+(\S+)/i)
		{
			my $exFile = $dir.$1;	# existing-file
			my $destFile = $dir.$2;	# destination-file
			print"found alias keyword\n" if ($verboseOpt);
			if(!copy($exFile,$destFile))
			{
				&datadriveimage::reportError("* warning : couldnt create alias of $1 to $2 ",$keepgoingOpt);
			}
			else
			{
				# push the line on to the stack.
				push(@$aliasArray,$1."\t".$2."\n");
			}
		}
		elsif($line =~ /^hide\s+(\S+)/i)
		{
			print"found hide keyword\n" if ($verboseOpt);
			print "$1 is marked as hidden, hence will not be part of the image\n" if($verboseOpt);
			if( unlink($dir.$1) )
			{
				# push the line on to the stack.
				push(@$hideArray,$1);
			}
			else 
			{ 
				&datadriveimage::reportError("* Warning : Can't delete $1: $! ",$keepgoingOpt);
			}
		}
	}
	close(OBEY);
}

# invoke the INTERPRETSIS tool with appropriate parameters.
sub invokeInterpretsis
{
	my($sisFileArray,$dataDrivePath,$verboseOpt,$zDrivePath,$parafile,$keepgoingOpt,$interpretsisOptList) = @_;
	my $sisfile = ""; 
	# default system drive letter is specified since interpretsis doesnt allow overloading of options unless default 
	# options are specified.
	my $basicOption = "-d C: ";	# default system drive letter
	my $command = "interpretsis ";
	my $vOption = "-w info" if ($verboseOpt);

	# do a check if the path has a white space.
	if( $dataDrivePath =~ m/ /)
	{
		$dataDrivePath = '"'.$dataDrivePath.'"';
	}

	# find out size of the array
	my $sisarraysize = scalar(@$sisFileArray);
	for( my $i=0; $i<$sisarraysize; $i++ )
	{
		if($sisfile ne "")
		{
			$sisfile = pop(@$sisFileArray).",".$sisfile;
		}
		else
		{
			$sisfile = pop(@$sisFileArray);
		}
	}

	# check whether the directory exists or not 
	if( -d $zDrivePath )
	{ 
		# do a check if the path has a white space.
		if( $zDrivePath =~ m/ /)
		{
			$zDrivePath = '"'.$zDrivePath.'"';
		}
		$basicOption .= "-z $zDrivePath "; 
	}

	$basicOption .= "-c $dataDrivePath -s $sisfile $vOption";

	# if parameter file is specified then invoke the INTERPRETSIS
	# with the specified parameter file with "-p" option.
	if( defined($parafile) )
	{ 
		# do a check if the path has a white space.
		if( $parafile =~ m/ /)
		{
			$parafile = '"'.$parafile.'"';
		}
		$command .= "-p $parafile "; 
	}
	# else invoke the INTERPRETSIS with default parameter file with "-p" option. 
	else
	{
		# Truncate and open the parameter file for writing..
		open( OPTDATA, "> parameterfile.txt" )  or die "can't open parameterfile.txt";
		print OPTDATA $basicOption."\n";
		close( OPTDATA );
		$command .= "-p parameterfile.txt ";
	}

	if( $interpretsisOptList )
	{
		# find out size of the array
		my $arraysize = scalar( @$interpretsisOptList );
		for( my $i = 0; $i < $arraysize; $i++ )
		{
			$command .= $$interpretsisOptList[$i]." ";
		}
	}

	print "* Executing $command\n" if ( $verboseOpt );
	system ( $command );

	if ($? != 0)
	{
		&datadriveimage::reportError("* ERROR: INTERPRETSIS failed",$keepgoingOpt);
	}
}

# invoke the READIMAGE tool with appropriate parameters.
sub invokeReadImage
{
	my($imageName,$loc,$verboseOpt,$logFile,$keepgoingOpt) = @_;
	my $command = "readimage ";
	# check if log file has been supplied.
	if(defined($logFile))
	{
		if( $logFile =~ m/ /)
		{
			$logFile = '"'.$logFile.'"';
		}
		$command .= "-l $logFile ";
	}
	
	# do a check if the path has a white space.
	if( $loc =~ m/ /)
	{
		$loc = '"'.$loc.'"';
	}
	$command .= "-z ".$loc." ".$imageName;
	print "* Executing $command\n" if ($verboseOpt);
	system ($command);
	if ($? != 0)
	{
		&datadriveimage::reportError("* ERROR: READIMAGE failed to read the image",$keepgoingOpt);
		return 0;
	}
	return 1;
}

# Each line from the OBY file is read and if any of the line contains "rename"/ "alias" keyword
# then that corresponding line source and line destination is obtained and is passed to this function as one of the parameters.
# This fuction compares given array with non-sis file(s) array, when an given line destination matches with the destination of an
# element in the rename array/alias array(array holding list of file(s) that are renamed / made alias) then,
# that respective element is removed from the rename array and a further check is made to see whether the given
# line source matches with the destination of an element in the rename array/alias array.If a match is found then
# a keyword check is done,if the keyword is "rename" then corresponding element's source and destination file is replaced
# with given line destination file and if the keyword is "alias" then a new element will be added to non sis file array
# with line destination file as the source and destination file.
sub compareArrays
{
	my ( $firstarray,$nonsisArray,$linesource,$linedest,$linekeyword ) = @_;
	# count of array element(s).
	my $firstArrayCount = 0;
	# source file.
	my $linesourceFile;
	# destination file.
	my $linedestFile;
	# get source file.

	# strip first occurrence of back slash
	$linesource =~ s/\\//; 

	# get source file.
	if ($linesource =~ /.*\\(\S+)/ ) 
	{
		$linesourceFile = $1;
	}
	# get destination file.
	if ($linedest =~ /.*\\(\S+)/ )
	{
		$linedestFile = $1;
	}
	# iterate trough all
	foreach my $firstarrayEntry (@$firstarray) 
	{
		if( $firstarrayEntry =~ /(\S+)\s+(\S+)/ )
		{
			my $firstarrayEntrydest = $2;

			if( $linedest eq $firstarrayEntrydest )
			{
				# remove the specified element from the array.
				splice(@$firstarray,$firstArrayCount,1);
				# initialize the nonsisFileListCount to zero.
				my $nonsisFileListCount = 0;
				foreach my $nonsisEntry ( @$nonsisArray )
				{
					if( $nonsisEntry =~ /^(\S+)=(\S+)\s+(\S+)/ )
					{
						my $nonsisEntryDest = $3;
						# remove double quotes.
						$nonsisEntryDest =~ s/\"//g;
						my $nonsisEntryDestFile;
						if ($nonsisEntryDest =~ /.*\\(\S+)/ ) 
						{ 
							$nonsisEntryDestFile = $1;
						}
						if( $nonsisEntryDest eq $linesource )
						{
							if($linekeyword eq "rename")
							{
								# remove the specified element from the array.
								splice(@$nonsisArray,$nonsisFileListCount,1);
								$nonsisEntry =~ s/$nonsisEntryDestFile/$linedestFile/g;
								push(@$nonsisArray,$nonsisEntry);
							}
							elsif($linekeyword eq "alias")
							{
								my $newLine = $nonsisEntry;
								$newLine =~ s/$nonsisEntryDestFile/$linedestFile/g;
								push(@$nonsisArray,$newLine);
							}
						}
					 }
					$nonsisFileListCount++;
				 }#end of loop foreach my $newLine ( @nonsisArray )
			}
			$firstArrayCount++;
		}#end of loop foreach my $newLine ( @firstarray) 
	}
}

# Traverse the entire directory and log the folder contents on to a file.
sub dumpDatadriveObydata
{
	#assign a temporary name and extension to the new oby file.
	my $newobyfile = "temp.$$";
	my ($datadir,$oldobyfile,$size,$nonsisFileArray,$renameArray,$aliasArray,
		$hideArray,$sisobyArray,$datadriveArray,$keepgoingOpt,$verboseOpt) = @_;
	# get the working directory.
	my $curWorkingDir = getcwd;
	# traverse the updated data drive directory structure.
	&TraverseDir($datadir,"",$sisobyArray,$datadir);
	# change the directrory to the Working directory.
	chdir($curWorkingDir);
	# copy non-sis file(s) on to prototype data drive folder.
	copyNonSisFiles($datadir,$oldobyfile,$nonsisFileArray,$renameArray,$aliasArray,$hideArray,$verboseOpt,$keepgoingOpt);
	#open the oby file in read-only mode. 
	open (OLDDATA, "< $oldobyfile") or die("* Can't open $oldobyfile\n");
	# Truncate and open the new oby file for writing..
	open(NEWDATA, "> $newobyfile")  or die "can't open $newobyfile";
	while  (my $line =<OLDDATA>)
	{
		if( $line =~ /^hide\s+(\S+)/i)
		{
			my $lineToSearch = $1; 
			my $hideListCount = 0;
			foreach my $newLine ( @$hideArray ) 
			{
				if( $newLine eq $lineToSearch )
				{
					splice(@$hideArray,$hideListCount,1);
					my $nonsisFileListCount = 0;
					foreach my $newLine ( @$nonsisFileArray )
					{
						if( $newLine =~ /^(\S+)=(\S+)\s+(\S+)/ )
						{
							my $newLineKeyword = $1;
							my $newLinesource = $2;
							my $newLinedest = $3;
							$newLinedest =~ s/\"//g;
							$newLinedest = "\\".$newLinedest;
							if( $newLinedest eq $lineToSearch )
							{
								# remove the specified element from the array.
								splice(@$nonsisFileArray,$nonsisFileListCount,1);
							}
						}
						# increment the non sis file list count.
						$nonsisFileListCount++;
					}
				}
				# increment the  hide file list count.
				$hideListCount++;
			}
		}
		elsif( $line =~ /^rename\s+(\S+)\s+(\S+)/i) 
		{ 
			my $linesource = $1 ;
			my $linedest = $2;
			my $linekeyword = "rename";
			&compareArrays($renameArray,$nonsisFileArray,$linesource,$linedest,$linekeyword);
		}
		elsif( $line =~ /^alias\s+(\S+)\s+(\S+)/i )
		{
			my $linesource = $1 ;
			my $linedest = $2;
			my $linekeyword = "alias";
			&compareArrays($aliasArray,$nonsisFileArray,$linesource,$linedest,$linekeyword);
		}
		elsif(	$line =~ /^(file|data)\s*=\s*/i || $line =~ /^\s*(zdriveimagename|sisfile)\s*=\s*/i )
		{
			# skip to next line. 
			next;
		}
		else
		{ 
			# push it on to the array.
			unshift(@$datadriveArray,$line); 
		}
		next;
	}
	# close the old oby files.
	close(OLDDATA)or die "can't close $oldobyfile";
	#write the array contents on to the file
	print"* Updating $oldobyfile - final OBY file\n";
	&writeDataToFile( $datadriveArray );
	&writeDataToFile( $sisobyArray );
	&writeDataToFile( $nonsisFileArray );
	# close the new oby file.
	close(NEWDATA)or die "can't close $newobyfile";
	#rename the file.
	rename( $newobyfile, $oldobyfile )or die "can't rename $newobyfile to $oldobyfile: $!";
}


# Traverse the entire given directory 
# push all the folder contents on to an array.
sub  TraverseDir
{
	my($dir,$folderList,$sisFileContent,$rootdir) = @_;
	#check the specified directory
	chdir($dir) || die "Cannot chdir to $dir\n";
	local(*DIR);
	opendir(DIR, ".");#open current directory.
	my $sourcedir;
	my $destdir;
	while (my $entry=readdir(DIR)) 
	{
		#skip, parent directory and current directory.
		next if ($entry eq "." || $entry eq "..");
		#check if it is a file 
		if( -f $entry )
		{
			my $sourcedir = $rootdir."\\".$folderList.$entry;
			my $destdir	= "$folderList".$entry;
			my $sisSource;
			my $sisdestination;
			if(&checkRegCtlFiles($entry))
			{
				# check for any whitespace
				if($sourcedir =~ m/ /)
				{
					# if yes, then append double quotes
					$sisSource = "data="."\"".$sourcedir."\"";
				}
				else
				{
					# else dont append any double quotes for destination
					$sisSource = "data=".$sourcedir;
				}
				# push the line on to the array.
				push(@$sisFileContent,$sisSource."\t".'"'.$destdir.'"');
			}
			else
			{
				# check for any white space
				if($sourcedir =~ m/ /)
				{
					# if yes, then append double quotes
					$sisSource = "file="."\"".$sourcedir."\"";
				}
				else
				{
					# else dont append any double quotes for destination
					$sisSource = "file=".$sourcedir;
				}
				# push the line on to the array.
				push(@$sisFileContent,$sisSource."\t".'"'.$destdir.'"');
			}
		}
		#else it's a directory
		else
		{
			&TraverseDir($entry,$folderList.$entry."\\",$sisFileContent,$rootdir);
		}
	}
	closedir(DIR);
	chdir("..");
}

# write the data in to oby file by accessing appropriate array.
sub writeDataToFile
{
	my ($array) = @_; 
	#get the array size.
	my $arraySize = scalar(@$array);
	for(my $i=0; $i<$arraySize ; $i++ )
	{
		#pop out the element to the respective obey file.
		 print NEWDATA pop(@$array)."\n";
	}
}