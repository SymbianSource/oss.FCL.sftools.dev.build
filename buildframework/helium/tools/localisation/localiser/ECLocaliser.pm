#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
#------------------------------------------------------------------------------
# Name   : Localiser.pm
# Use    : Implementation of a new localisation process.

#
# Version History :
#
# v1.1.2 (30/01/2008) : Valliappan Ramanathan - ISIS
#  - Updated to build with EC build

#
# v1.1.1 (04/08/2006) :
#  - Update include management, now it uses cpp.
#
# v1.1.0 (12/05/2006) :
#  - Corrected include parsing, remove that fact that file must start with \
#  - Added locales_xx.iby creation
#
# v1.0.1 (12/05/2006) :
#  - Corrected __MakeRlt function
#
# v1.0 (19/04/2006) :
#  - First version of the script.
#------------------------------------------------------------------------------

## @ file
#

#------------------------------------------------------------------------------
# Package __OUT
#------------------------------------------------------------------------------
package __OUT;
use strict;

my $outputer = "__OUT";

sub SetLoggerPackage
{
	my ($p) = shift;
	return unless($p);
	$outputer = $p;
}

sub AUTOLOAD
{
	my ($method) = (our $AUTOLOAD);	
	if ( $outputer eq "__OUT" )
	{
		$method =~ s/^__OUT:://;
		if ($method =~ /print/i)
		{
			print ("@_");
		}
		elsif ($method =~ /die/i)
		{
			die (@_);
		}
		else
		{
			print (uc($method).": @_");
		}
	}
	elsif ( defined ($outputer) and defined($method) )
	{
		print "@_\n" if ($method =~ /die/i);		
		$method =~ s/^__OUT::/$outputer\::/;
		no strict 'refs';
		&$method( @_ );
	}
}

1;

## @class ZipUp
#
#
#
package ZipUp;
use strict;
use Archive::Zip;
use File::Copy;

sub new
{
	my ( $class, $filename ) = @_;
	return undef unless ($filename);
	
	my $self = {
		__filename => $filename,
	};
	
	return bless $self, $class;
}

sub AddFile
{
	my ( $self, $filename ) = (shift,shift);
	&__OUT::Print ("Adding '\\$filename'\n");	
	my $cmd = "zip ".$self->{ __filename }." $filename\n";
	&__OUT::Print (scalar(`$cmd`));
}

sub AddFilesFromList
{
	my ( $self, $listfilename ) = (shift,shift);
	if ( -e $listfilename )
	{
		&__OUT::Print ("Adding files using '$listfilename'\n");		
			my $cmd = "more $listfilename | zip -9 ".$self->{ __filename }." -@";
		&__OUT::Print ( $cmd."\n" );
		&__OUT::Print ( scalar( `$cmd` ) );
	}		
}
1;


## @class Finder
#
#
#
package Finder;

sub new
{
	my ( $class, $regexp, $rootdir ) = @_;

	my $self = {
		__rootdir => $rootdir,
		__regexp => $regexp,
	};
	
	return bless $self, $class;
}

sub Find
{
	my ($self, $dir, $list) = @_;

	my @fake;
	$list = \@fake unless (defined ($list));
	$dir = $self->{__rootdir} unless (defined($dir));
	
	opendir (DIR, $dir);
	my @l = readdir(DIR);
	closedir(DIR);
	
	foreach my $name (@l)
	{
		next if ($name =~ /^\.+$/);
		my $filename = "$dir/$name";
		
		if ( -d $filename )
		{
			$self->Find($filename, $list);
		}
		elsif ( $filename =~ /$self->{__regexp}/i )
		{			
			push @$list, $filename;
		}		
	}

	return $list;
}

1;


## @class Localiser
#
#
package Localiser;
use strict;
use File::Path;
#use ISIS::GenBuildTools;
use IPC::Open3;
use File::Spec;  
use File::Basename;

my $DEFAULT_LOC_PATH = "\\s60\\S60LocFiles";
use constant DEFAULT_XML_PATH => ".xml";
use constant DEFAULT_WHATXML_PATH => "_what.xml";
use constant DEFAULT_CHECKXML_PATH => "_check.xml";
use constant DEFAULT_TPATH => "\\zips";


use constant DEFAULT_MAKE_PATH => ".make";
use constant DEFAULT_WHATMAKE_PATH => "whatMakefile";
use constant DEFAULT_CHECKMAKE_PATH => "checkMakefile";

sub new
{
	my $class = shift;
	
	my $configfiles = shift;
	my $languagelist = shift;
	my $includepath = shift;
	my $bldfile = shift;
	my $tpath = shift || DEFAULT_TPATH;
	my @configuration;
	my %platform;# = ("armv5");
	my $self = {
		__configfiles => $configfiles,
		__includepath => $includepath,
		__languagelist => $languagelist,
		__configuration => \@configuration,
		__platform	=> \%platform,
		__tpath => $tpath,
		__bldfile => $bldfile
	};
	return bless $self, $class;	
}


sub DefaultLocPath
{
	my ($k) = @_;
	$DEFAULT_LOC_PATH = $k if (defined ($k));
	return $DEFAULT_LOC_PATH;
}

sub Keepgoing
{
	my ($self, $k) = @_;
	$self->{__keepgoing} = $k if (defined ($k));
	return $self->{__keepgoing};
}

sub SetLoggerPackage
{
	my ($self, $outputer) = @_;
	return unless($outputer);
	&__OUT::SetLoggerPackage($outputer);
}

sub Initialise()
{
	my $self = shift;
	my ($drive) = File::Spec->splitpath(File::Spec->rel2abs(File::Spec->curdir()));
	foreach my $filename ( @{ $self->{__configfiles} } )
	{
		# adding path of the input file into the include path list
		my $includepath = "";
		$includepath .= "-I ".File::Spec->rel2abs(dirname($filename));
		foreach my $path ( @{ $self->{__includepath} } )
		{
			$path = File::Spec->rel2abs($path);
			$path = "$drive$path" if ($path =~ /^\\/);			
			$includepath .= " -I $path";
		}

		# command line to execute
		my $cmd = "cpp -nostdinc -u $includepath ".File::Spec->rel2abs($filename);
		__OUT::Print( "$cmd\n");
	
		# parsing using cpp...
		my $childpid = open3(\*WTRFH, \*RDRFH, \*ERRFH, $cmd);
		close(WTRFH);

		while (<RDRFH>)
		{
				if ( /^\s*<option (\w+)>/ )
				{
					my $option = lc($1);
					$self->{ __platform }->{ $option } = $option; # if ($option =~ /^(armv5|winscw)$/i);
				}
				else
				{
					my $c = &__LocInfoData::CreateFromLine( $_ );
					push ( @{ $self->{__configuration} }, $c ) if ($c);
				}
		}
		close(RDRFH);	
	
		# Manage cpp errors
		my $err = "";
		while(<ERRFH>) { $err .= "$_\n";}
		if (not ($err eq "")){ __OUT::Error ("$err"); }

		# Closing cleanly....
		close(ERRFH);
		waitpid($childpid, 0);
	}

	
	# if not platform add default one: armv5
	unless (scalar (keys (%{$self->{ __platform }}) ))
	{
		__OUT::Warning("No platform specified, using default (ARMV5)");
		$self->{ __platform }->{ 'armv5' } = 'armv5';
	}
}

sub CheckConfig
{
	my $self = shift;
	my $result = 1;
	foreach my $c ( @{ $self->{__configuration} } )
	{
		$result &&= $c->CheckBldInf();
		$result &&= $c->CheckLocFiles();
	}	
	return $result;
}

sub PrepareLocalisation
{
	my $self = shift;
	my $filename = shift;

	my $zip = new ZipUp($filename);
		
	__OUT::Print ("Preparing each component\n");

	foreach my $c ( @{ $self->{__configuration} } )
	{
		$c->ZipUpLocFiles( $zip );
	}

	HandleEpoc32LocFiles( $self-> { __languagelist }, $zip );

	my $time1;
	my $time2;
	
	$time1 = time();
	foreach my $c ( @{ $self->{__configuration} } )
	{
		$c->GenerateStubLocFiles( $self-> { __languagelist } );
		$c->ChangeMMPsAndMKs( $self-> { __languagelist }, $zip );
		$c->TouchRSS();
	}
	$time2 = time();
	my $time = $time2 - $time1;
__OUT::Print ("time for loc file / mmp changes: $time\n");
	
}

sub GenerateMakefiles
{
	my $self = shift;
	my $time1;
	my $time2;
	$time1 = time();
	__OUT::Print ("Generating Makefiles for EC\n");
	$self->__GenerateECMakefile();
	#$self->__GenerateWhatECMakefile();
	#$self->__GenerateCheckECMakefile();
	$time2 = time();
	my $time = $time2 - $time1;
__OUT::Print ("time for GenerateMakefiles: $time\n");
	
}

sub GenerateXMLFiles
{
	my $self = shift;
	__OUT::Print ("Generating XML for TBS\n");
	$self->__GenerateTBSXML();
	$self->__GenerateWhatTBSXML();
	$self->__GenerateCheckTBSXML();
}

sub __GenerateTBSXML
{
	my $self = shift;
	my $xmlfile = $self->{ __bldfile }."".DEFAULT_XML_PATH;
	open (XML, ">$xmlfile") or __OUT::Die ("Cannot open '$xmlfile':$!");
	print 	XML "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n";
	print 	XML "<Product Name=\"$xmlfile\">\n";
	print 	XML "\t<Commands>\n";
	my $id = 1;
	my $stage = 1;
		
	print XML "\t\t<SetEnv Order = \"1\" Name = \"EPOCROOT\" Value = \"\\\"/>\n";
	print XML "\t\t<SetEnv Order = \"2\" Name = \"PATH\" Value = \"\\epoc32\\gcc\\bin;\\epoc32\\tools;%PATH%\"/>\n";

	
	# bldmake bldfiles
	foreach my $c ( @{ $self->{__configuration} } )
	{
		#<Execute CommandLine="call bldmake bldfiles -k" Component="\s60\icons" Cwd="\s60\icons\group" ID="2" Stage="1" />
		print XML "		<Execute CommandLine=\"call bldmake bldfiles -k\" Component=\"".$c->GetPath()."\" Cwd=\"".$c->GetPath()."\\".$c->GetGroup()."\" ID=\"".$id++."\" Stage=\"$stage\" />\n";
	}
	$stage++;

	# abld makefile
	foreach my $p ( keys (%{ $self->{ __platform } }) )
	{
		foreach my $c ( @{ $self->{__configuration} } )
		{
			foreach my $mmp ( @{$c->GetMMPs()} )
			{
					print XML "		<Execute CommandLine=\"call abld makefile $p ".$mmp." -k\" Component=\"".$c->GetPath()."\" Cwd=\"".$c->GetPath()."\\".$c->GetGroup()."\" ID=\"".$id++."\" Stage=\"$stage\" />\n";
			}
		}
		# Next platform
		$stage++;
	}

	# abld resource
	foreach my $p ( keys (%{ $self->{ __platform } }) )
	{  			
		foreach my $c ( @{ $self->{__configuration} } )
		{
			foreach my $mmp ( @{ $c->GetMMPs() } )
			{ 		
				if ( $c->GetMMPType($mmp) eq 'mmp')
				{
						print XML "		<Execute CommandLine=\"call abld resource $p ".$mmp." -k\" Component=\"".$c->GetPath()."\" Cwd=\"".$c->GetPath()."\\".$c->GetGroup()."\" ID=\"".$id++."\" Stage=\"$stage\" />\n";
				}
			}
		}
		# Next platform
		$stage++;
	}
	
	#
	# Mk are treated by languages
	#
	foreach my $lang ( @{ $self-> { __languagelist } } )
	{  			
		foreach my $p ( keys (%{ $self->{ __platform } }) )
		{  			
			foreach my $c ( @{ $self->{__configuration} } )
			{
				foreach my $mmp ( @{ $c->GetMMPs() } )
				{
					if ( $c->GetMMPType($mmp) eq 'mk')
					{
							print XML "		<Execute CommandLine=\"set LANGUAGE=$lang &amp;&amp; call abld resource $p ".$mmp." -k\" Component=\"".$c->GetPath()."\" Cwd=\"".$c->GetPath()."\\".$c->GetGroup()."\" ID=\"".$id++."\" Stage=\"$stage\" />\n";
					}
				}
			}
			# Next platform...
			$stage++;
		}
	}
		

	
	print 	XML "	</Commands>\n";
	print 	XML "</Product>\n";	
	close(XML);
}

sub __GenerateWhatTBSXML
{
	my $self = shift;
		my $xmlfile = $self->{ __bldfile }."".DEFAULT_WHATXML_PATH;
	open (XML, ">$xmlfile") or __OUT::Die ("Cannot open '$xmlfile':$!");
	print 	XML "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n";
	print 	XML "<Product Name=\"$xmlfile\">\n";
	print 	XML "\t<Commands>\n";
	my $id = 1;
	my $stage = 1;
		
	print XML "\t\t<SetEnv Order = \"1\" Name = \"EPOCROOT\" Value = \"\\\"/>\n";
	print XML "\t\t<SetEnv Order = \"2\" Name = \"PATH\" Value = \"\\epoc32\\gcc\\bin;\\epoc32\\tools;%PATH%\"/>\n";
	
	# abld resource
	foreach my $c ( @{ $self->{__configuration} } )
	{
		foreach my $mmp ( @{$c->GetMMPs()} )
		{
			if ( $c->GetMMPType($mmp) eq 'mk')
			{
				foreach my $lang ( @{ $self-> { __languagelist } } )
				{  			
					foreach my $p ( keys (%{ $self->{ __platform } }) )
					{  			
						print XML "		<Execute CommandLine=\"set LANGUAGE=$lang &amp;&amp; call abld build $p ".$mmp." -w\" Component=\"".$c->GetPath()."\" Cwd=\"".$c->GetPath()."\\".$c->GetGroup()."\" ID=\"".$id++."\" Stage=\"$stage\" />\n";
					}
				}
			}
			else
			{
				foreach my $p ( keys (%{ $self->{ __platform } }) )
				{
					print XML "		<Execute CommandLine=\"call abld build $p ".$mmp." -w\" Component=\"".$c->GetPath()."\" Cwd=\"".$c->GetPath()."\\".$c->GetGroup()."\" ID=\"".$id++."\" Stage=\"$stage\" />\n";
				}
			}
		}
	}
	$stage++;
	print 	XML "	</Commands>\n";
	print 	XML "</Product>\n";	
	close(XML);
}

sub __GenerateCheckTBSXML
{
	my $self = shift;
	my $xmlfile = $self->{ __bldfile }."".DEFAULT_CHECKXML_PATH;
	open (XML, ">$xmlfile") or __OUT::Die ("Cannot open '$xmlfile':$!");
	print 	XML "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n";
	print 	XML "<Product Name=\"$xmlfile\">\n";
	print 	XML "\t<Commands>\n";
	my $id = 1;
	my $stage = 1;
		
	print XML "\t\t<SetEnv Order = \"1\" Name = \"EPOCROOT\" Value = \"\\\"/>\n";
	print XML "\t\t<SetEnv Order = \"2\" Name = \"PATH\" Value = \"\\epoc32\\gcc\\bin;\\epoc32\\tools;%PATH%\"/>\n";
	
	# abld resource
	foreach my $c ( @{ $self->{__configuration} } )
	{
		foreach my $mmp ( @{$c->GetMMPs()} )
		{
			if ( $c->GetMMPType($mmp) eq 'mk')
			{
				foreach my $lang ( @{ $self-> { __languagelist } } )
				{  			
					foreach my $p ( keys (%{ $self->{ __platform } }) )
					{  			
						print XML "		<Execute CommandLine=\"set LANGUAGE=$lang &amp;&amp; call abld build $p ".$mmp." -c\" Component=\"".$c->GetPath()."\" Cwd=\"".$c->GetPath()."\\".$c->GetGroup()."\" ID=\"".$id++."\" Stage=\"$stage\" />\n";
					}
				}
			}
			else
			{
				foreach my $p ( keys ( %{ $self->{ __platform } } ) )
				{
					print XML "		<Execute CommandLine=\"call abld build $p ".$mmp." -c\" Component=\"".$c->GetPath()."\" Cwd=\"".$c->GetPath()."\\".$c->GetGroup()."\" ID=\"".$id++."\" Stage=\"$stage\" />\n";
				}
			}
		}
	}
	$stage++;
	print 	XML "	</Commands>\n";
	print 	XML "</Product>\n";	
	close(XML);
}



sub HandleEpoc32LocFiles
{
	my ($langlist, $zip) = (shift, shift);

	open (LST,">>\\cleanupfiles.lst");
	foreach my $locfile (@{GetEpoc32LocFiles()})
	{
		$zip->AddFile($locfile);
		print LST $locfile."\n";
		__OUT::Print ("=== updating '$locfile' ===\n");
		my ($path, $group, @mmps, @locfiles, @tlocfiles);
		push(@locfiles, $locfile);
		my $lid = new __LocInfoData($path, $group, \@mmps, \@locfiles, \@tlocfiles);
		$lid = __LocInfoData::CreateFromLine(",,\"\",\"$locfile\"");
		$lid->GenerateStubLocFile($locfile, $langlist);
	}
	close(LST);
}

sub GetEpoc32LocFiles
{
	my @array;
	my (@locs) = `dir /s/b \\epoc32\\include\\*.loc`;
	foreach my $loc (@locs)
	{
		if ($loc =~ /^[A-Z]:(.*)\\(.*?)$/i)
		{
			print "Found $loc ($1, $2).\n";
			push(@array, $1."\\".$2);
		}
	}
	return \@array;
}

sub __GenerateECMakefile
{
	my $self = shift;
	my $makefile =$self->{ __bldfile }."".DEFAULT_MAKE_PATH;
	open (XML, ">$makefile") or __OUT::Die ("Cannot open '$makefile':$!");
	print XML "".$self->{ __bldfile }.":bldmake_bldfiles_all \\\n";
	print XML "\t abld_makefile_all \\\n";
	print XML "\t abld_resource_all \n\n";

	print XML "".$self->{ __bldfile }."_what: what_all\n\n";
	print XML "".$self->{ __bldfile }."_check: check_all\n\n";
	
	#print 	XML "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n";
	#print 	XML "<Product Name=\"$xmlfile\">\n";
	#print 	XML "\t<Commands>\n";
	my $id = 1;
	my $stage = 1;
	my %componentHash;
	my $component="";
	#print XML "\t\t<SetEnv Order = \"1\" Name = \"EPOCROOT\" Value = \"\\\"/>\n";
	#print XML "\t\t<SetEnv Order = \"2\" Name = \"PATH\" Value = \"\\epoc32\\gcc\\bin;\\epoc32\\tools;%PATH%\"/>\n";

	
	# bldmake bldfiles
	#my $concatStages = "bldmake_bldfiles_all:";
	#my $componontID = 1;

	my $makeUnitList = "bldmake-UNITS:=";
	

	foreach my $c ( @{ $self->{__configuration} } )
	{
		$component = $c->GetPath()."\\".$c->GetGroup();
		if ( ! exists($componentHash{$component})){
			$componentHash{$component} = $component;
			#$concatStages .= "\t\\\n";
				#<Execute CommandLine="call bldmake bldfiles -k" Component="\s60\icons" Cwd="\s60\icons\group" ID="2" Stage="1" />
				#print XML "bldmake_bldfiles-$componontID:\n";
				$makeUnitList .="\t\\\n\t".$c->GetPath()."\\".$c->GetGroup();
				#print XML "		<Execute CommandLine=\"call bldmake bldfiles -k\" Component=\"".$c->GetPath()."\" Cwd=\"".$c->GetPath()."\\".$c->GetGroup()."\" ID=\"".$id++."\" Stage=\"$stage\" />\n";
			#$concatStages .= "\t bldmake_bldfiles-$componontID";
			#$componontID++;
		}
	}
	$makeUnitList .="\n\n";
	print XML	$makeUnitList;
	print XML "bldmake_bldfiles_all: \$(addsuffix -bldmake_bldfiles-k,\$(bldmake-UNITS))\n\n";
	print XML "%-bldmake_bldfiles-k:\n";
	print XML "\t\@echo ===-------------------------------------------------\n";
	print XML "\t\@echo === bldmake \$*\n";
	print XML "\tcd \$* && bldmake bldfiles -k\n";
	print XML "\t\@echo ===-------------------------------------------------\n";

	#$stage++;
	print XML "\n\n";
	#print XML "".$concatStages."\n\n";

	#$concatStages = "abld_makefile_all: ";
	#$componontID = 1;

	$makeUnitList = "abld-UNITS:= \$(abld-mmp-UNITS) \$(abld-mk-UNITS)";

	my $abldMMPUnitList = "abld-mmp-UNITS:=";
	my $abldMKUnitList = "abld-mk-UNITS:=";
	my $isAbldUnitAdded = 0;
	# abld makefile
	my $mmptype;
	foreach my $p ( keys (%{ $self->{ __platform } }) )
	{
		foreach my $c ( @{ $self->{__configuration} } )
		{
			foreach my $mmp ( @{$c->GetMMPs()} )
			{
				#$concatStages .= "\t\\\n";
				#print XML "abld_makefile-$componontID: bldmake_bldfiles_all \n";
				#print XML "\t\@echo ===-------------------------------------------------\n";
				#print XML "\t\@echo === abld_makefile\n";
				#print XML "\t\@echo === ".$c->GetPath()."\\".$c->GetGroup()."\n";
				#print XML "\t\@echo ===-------------------------------------------------\n";
				#print XML "\t cd ".$c->GetPath()."\\".$c->GetGroup()." && abld makefile $p ".$mmp." -k \n\n";
				$mmptype = $c->GetMMPType($mmp);
				print "mmptype:...$mmptype\n";
				print "getgroup:...".$c->GetGroup()."\n";
				print "getpath:...".$c->GetPath()."\n";
				print "mmp:...".$mmp."\n";
				print "length of getgroup string:....".(length($c->GetGroup()))."\n";
				my $strlength = length($c->GetGroup());
				if($isAbldUnitAdded == 0){
					if($mmptype eq 'mmp'){
						if($strlength != 0){
								$abldMMPUnitList .="\t\\\n\t".$c->GetPath()."\\".$c->GetGroup()."\\".$mmp;
							}else {
								$abldMMPUnitList .="\t\\\n\t".$c->GetPath()."\\".$mmp;
							}
					}else {
						if($strlength != 0){
								$abldMKUnitList .="\t\\\n\t".$c->GetPath()."\\".$c->GetGroup()."\\".$mmp;
							}else {
								$abldMKUnitList .="\t\\\n\t".$c->GetPath()."\\".$mmp;
							}
					}
				}
				#print XML "		<Execute CommandLine=\"call abld makefile $p ".$mmp." -k\" Component=\"".$c->GetPath()."\" Cwd=\"".$c->GetPath()."\\".$c->GetGroup()."\" ID=\"".$id++."\" Stage=\"$stage\" />\n";
				#$concatStages .= "\t abld_makefile-$componontID";
				#$componontID++;
			}
		}
		$isAbldUnitAdded = 1;
		# Next platform
		$stage++;
	}
	$makeUnitList .="\n\n";
	$abldMMPUnitList .="\n\n";
	$abldMKUnitList .="\n\n";
	print XML	$abldMMPUnitList;
	print XML	$abldMKUnitList;
	print XML	 $makeUnitList;
	
	my $abldDepRule = "abld_makefile_all: ";
	
	foreach my $p ( keys (%{ $self->{ __platform } }) )
	{
		print XML "abld_makefile_$p: \$(addsuffix -abld_makefile_$p-k,\$(abld-UNITS))\n\n";
		print XML "%-abld_makefile_$p-k:bldmake_bldfiles_all\n";
		print XML "\t\@echo ===-------------------------------------------------\n";
		print XML "\t\@echo === abld makefile \$*\n";
		print XML "\tcd \$(*D) && abld makefile $p \$(*F) -k\n";
		print XML "\t\@echo ===-------------------------------------------------\n\n";
		$abldDepRule.="\t\\\n\tabld_makefile_$p";
	}
	$abldDepRule.="\n\n";
	print XML $abldDepRule;

	print XML "\n\n";
	
	#print XML "".$concatStages."\n\n";
	#$concatStages = "abld_resource_all:";
	#$componontID = 1;

	$abldDepRule = "abld_resource_mmp: ";
	# abld resource
	foreach my $p ( keys (%{ $self->{ __platform } }) )
	{
		print XML "abld_resource_mmp_$p: \$(addsuffix -abld_resource_mmp_$p-k,\$(abld-mmp-UNITS))\n\n";
		print XML "%-abld_resource_mmp_$p-k:abld_makefile_all\n";
		print XML "\t\@echo ===-------------------------------------------------\n";
		print XML "\t\@echo === abld resource $p \$*\n";
		print XML "\tcd \$(*D) && abld resource $p \$(*F) -k\n";
		print XML "\t\@echo ===-------------------------------------------------\n\n";
		$abldDepRule.="\t\\\n\tabld_resource_mmp_$p";
	}
	$abldDepRule.="\n\n";
	print XML $abldDepRule;

	print XML "\n\n";
	
	$abldDepRule = "abld_resource_mk: ";
	foreach my $lang ( @{ $self-> { __languagelist } } )
	{  			
		foreach my $p ( keys (%{ $self->{ __platform } }) )
		{
			print XML "abld_resource_mk_".$p."_".$lang.": \$(addsuffix -abld_resource_mk_".$p."_".$lang."-k,\$(abld-mk-UNITS))\n\n";
			print XML "%-abld_resource_mk_".$p."_".$lang."-k:abld_resource_mmp\n";
			print XML "\t\@echo ===-------------------------------------------------\n";
			print XML "\t\@echo === abld resource $p \$*\n";
			print XML "\tSET LANGUAGE=".$lang." &&  cd \$(*D) && abld resource $p \$(*F) -k\n";
			print XML "\t\@echo ===-------------------------------------------------\n\n";
			$abldDepRule.="\t\\\n\tabld_resource_mk_".$p."_".$lang;
		}
	}
	$abldDepRule.="\n\n";
	print XML $abldDepRule;
	print XML "\n\n";

	print XML "abld_resource_all: abld_resource_mmp abld_resource_mk\n\n";

	$abldDepRule = "abld_what_mmp: ";
	foreach my $p ( keys (%{ $self->{ __platform } }) )
	{
		print XML "abld_what_mmp_$p: \$(addsuffix -abld_what_mmp_$p,\$(abld-mmp-UNITS))\n\n";
		print XML "%-abld_what_mmp_$p:\n";
		print XML "\t\@echo ===-------------------------------------------------\n";
		print XML "\t\@echo === abld what $p \$*\n";
		print XML "\tcd \$(*D) && abld build $p \$(*F) -w\n";
		print XML "\t\@echo ===-------------------------------------------------\n\n";
		$abldDepRule.="\t\\\n\tabld_what_mmp_$p";
	}
	$abldDepRule.="\n\n";
	print XML $abldDepRule;

		$abldDepRule = "abld_what_mk: ";
	foreach my $lang ( @{ $self-> { __languagelist } } )
	{  			
		foreach my $p ( keys (%{ $self->{ __platform } }) )
		{
			print XML "abld_what_mk_".$p."_".$lang.": \$(addsuffix -abld_what_mk_".$p."_".$lang.",\$(abld-mk-UNITS))\n\n";
			print XML "%-abld_what_mk_".$p."_".$lang." : abld_what_mmp\n";
			print XML "\t\@echo ===-------------------------------------------------\n";
			print XML "\t\@echo === abld what $p \$*\n";
			print XML "\tSET LANGUAGE=".$lang." && cd \$(*D) && abld build $p \$(*F) -w\n";
			print XML "\t\@echo ===-------------------------------------------------\n\n";
			$abldDepRule.="\t\\\n\tabld_what_mk_".$p."_".$lang;
		}
	}
	$abldDepRule.="\n\n";
	print XML $abldDepRule;

	print XML "what_all: abld_what_mmp abld_what_mk\n\n";

	$abldDepRule = "abld_check_mmp: ";
	foreach my $p ( keys (%{ $self->{ __platform } }) )
	{
		print XML "abld_check_mmp_$p: \$(addsuffix -abld_check_mmp_$p,\$(abld-mmp-UNITS))\n\n";
		print XML "%-abld_check_mmp_$p:\n";
		print XML "\t\@echo ===-------------------------------------------------\n";
		print XML "\t\@echo === abld check $p \$*\n";
		print XML "\tcd \$(*D) && abld build $p \$(*F) -c\n";
		print XML "\t\@echo ===-------------------------------------------------\n\n";
		$abldDepRule.="\t\\\n\tabld_check_mmp_$p";
	}
	$abldDepRule.="\n\n";
	print XML $abldDepRule;

	$abldDepRule = "abld_check_mk: ";
	foreach my $lang ( @{ $self-> { __languagelist } } )
	{  			
		foreach my $p ( keys (%{ $self->{ __platform } }) )
		{
			print XML "abld_check_mk_".$p."_".$lang.": \$(addsuffix -abld_check_mk_".$p."_".$lang.",\$(abld-mk-UNITS))\n\n";
			print XML "%-abld_check_mk_".$p."_".$lang." : abld_check_mmp\n";
			print XML "\t\@echo ===-------------------------------------------------\n";
			print XML "\t\@echo === abld check $p \$*\n";
			print XML "\tSET LANGUAGE=".$lang." && cd \$(*D) && abld build $p \$(*F) -c\n";
			print XML "\t\@echo ===-------------------------------------------------\n\n";
			$abldDepRule.="\t\\\n\tabld_check_mk_".$p."_".$lang;
		}
	}
	$abldDepRule.="\n\n";
	print XML $abldDepRule;

	print XML "check_all: abld_check_mmp abld_check_mk\n\n";
	close(XML);
}

sub __GenerateWhatECMakefile
{
	my $self = shift;
	my $makefile =$self->{ __bldfile }."_".DEFAULT_WHATMAKE_PATH;
	open (XML, ">$makefile") or __OUT::Die ("Cannot open '$makefile':$!");
	#print 	XML "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n";
	#print 	XML "<Product Name=\"$xmlfile\">\n";
	#print 	XML "\t<Commands>\n";
	my $id = 1;
	my $stage = 1;

	print XML "all: abld_resource_all \\\n";
	print XML "\t abld_mk_all \n\n";


	my $concatStages = "abld_resource_all:";
	my $componontID = 1;
	
		
	#print XML "\t\t<SetEnv Order = \"1\" Name = \"EPOCROOT\" Value = \"\\\"/>\n";
	#print XML "\t\t<SetEnv Order = \"2\" Name = \"PATH\" Value = \"\\epoc32\\gcc\\bin;\\epoc32\\tools;%PATH%\"/>\n";

	# abld resource
	foreach my $p ( keys (%{ $self->{ __platform } }) )
	{  			
		foreach my $c ( @{ $self->{__configuration} } )
		{
			foreach my $mmp ( @{ $c->GetMMPs() } )
			{ 		
				if ( $c->GetMMPType($mmp) eq 'mmp')
				{
				$concatStages .= "\t\\\n";
				print XML "abld_resource-$componontID: \n";
				print XML "\t cd ".$c->GetPath()."\\".$c->GetGroup()." && abld build $p ".$mmp." -w     \n\n";
				$concatStages .= "\t abld_resource-$componontID";
				$componontID++;
				}
			}
		}
		# Next platform
		$stage++;
	}
		print XML "\n\n";
		print XML "".$concatStages."\n\n";
	

	$concatStages = "abld_mk_all: ";
	$componontID = 1;

	#
	# Mk are treated by languages
	#
	foreach my $lang ( @{ $self-> { __languagelist } } )
	{  			
		foreach my $p ( keys (%{ $self->{ __platform } }) )
		{  			
			foreach my $c ( @{ $self->{__configuration} } )
			{
				foreach my $mmp ( @{ $c->GetMMPs() } )
				{
					if ( $c->GetMMPType($mmp) eq 'mk')
					{
						$concatStages .= "\t\\\n";
						if($componontID eq 1){
							print XML "abld_mk-$componontID: abld_resource_all \n";
						}else {
							print XML "abld_mk-$componontID: abld_mk-".($componontID-1)." \n";
						}
						print XML "\t SET LANGUAGE=".$lang." && cd ".$c->GetPath()."\\".$c->GetGroup()." && abld build $p ".$mmp." -w\n\n";
						$concatStages .= "\t abld_mk-$componontID";
						$componontID++;
					}
				}
			}
			# Next platform...
			$stage++;
		}
	}
	print XML "\n";
	print XML "".$concatStages."\n\n";
	
	#print 	XML "	</Commands>\n";
	#print 	XML "</Product>\n";	
	close(XML);
}

sub __GenerateCheckECMakefile
{
	my $self = shift;
	my $makefile =$self->{ __bldfile }."_".DEFAULT_CHECKMAKE_PATH;
	open (XML, ">$makefile") or __OUT::Die ("Cannot open '$makefile':$!");
	#print 	XML "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n";
	#print 	XML "<Product Name=\"$xmlfile\">\n";
	#print 	XML "\t<Commands>\n";
	my $id = 1;
	my $stage = 1;
		
	print XML "all: abld_resource_all \\\n";
	print XML "\t abld_mk_all \n\n";


	my $concatStages = "abld_resource_all:";
	my $componontID = 1;
	
		
	#print XML "\t\t<SetEnv Order = \"1\" Name = \"EPOCROOT\" Value = \"\\\"/>\n";
	#print XML "\t\t<SetEnv Order = \"2\" Name = \"PATH\" Value = \"\\epoc32\\gcc\\bin;\\epoc32\\tools;%PATH%\"/>\n";

	# abld resource
	foreach my $p ( keys (%{ $self->{ __platform } }) )
	{  			
		foreach my $c ( @{ $self->{__configuration} } )
		{
			foreach my $mmp ( @{ $c->GetMMPs() } )
			{ 		
				if ( $c->GetMMPType($mmp) eq 'mmp')
				{
				$concatStages .= "\t\\\n";
				print XML "abld_resource-$componontID: \n";
				print XML "\t\@echo ===-------------------------------------------------\n";
				print XML "\t\@echo === abld_resource-$componontID\n";
				print XML "\t\@echo === ".$c->GetPath()."\\".$c->GetGroup()."\n";
				print XML "\t\@echo ===-------------------------------------------------\n";
				print XML "\t cd ".$c->GetPath()."\\".$c->GetGroup()." && abld build $p ".$mmp." -c     \n\n";
				$concatStages .= "\t abld_resource-$componontID";
				$componontID++;
				}
			}
		}
		# Next platform
		$stage++;
	}
		print XML "\n\n";
		print XML "".$concatStages."\n\n";
	

	$concatStages = "abld_mk_all: ";
	$componontID = 1;

	#
	# Mk are treated by languages
	#
	foreach my $lang ( @{ $self-> { __languagelist } } )
	{  			
		foreach my $p ( keys (%{ $self->{ __platform } }) )
		{  			
			foreach my $c ( @{ $self->{__configuration} } )
			{
				foreach my $mmp ( @{ $c->GetMMPs() } )
				{
					if ( $c->GetMMPType($mmp) eq 'mk')
					{
						$concatStages .= "\t\\\n";
						if($componontID eq 1){
							print XML "abld_mk-$componontID: abld_resource_all \n";
						}else {
							print XML "abld_mk-$componontID: abld_mk-".($componontID-1)." \n";
						}
						print XML "\t\@echo ===-------------------------------------------------\n";
						print XML "\t\@echo === abld_mk-$componontID\n";
						print XML "\t\@echo === ".$c->GetPath()."\\".$c->GetGroup()."\n";
						print XML "\t\@echo ===-------------------------------------------------\n";
						print XML "\t SET LANGUAGE=".$lang." && cd ".$c->GetPath()."\\".$c->GetGroup()." && abld build $p ".$mmp." -c\n\n";
						$concatStages .= "\t abld_mk-$componontID";
						$componontID++;
					}
				}
			}
			# Next platform...
			$stage++;
		}
	}
	print XML "\n";
	print XML "".$concatStages."\n\n";
	close(XML);
}

sub DeleteOriginalLocFiles{
my $line;
	if( -e "\\cleanupfiles.lst"){
		open (LST,"<\\cleanupfiles.lst");
		while ($line = <LST>)
		{
			chomp($line);
				if( -e "$line.isis.orig"){
					unlink ( "$line.isis.orig" ) or __OUT::Warning(" Failed to delete stubbed loc file $line.isis.orig --- \n");
				}else {
					if( -e "$line.orig"){
						unlink ( "$line.orig" ) or __OUT::Warning(" Failed to delete stubbed mk file $line.orig --- \n");
					}
				}
				if( -e "$line.isis.trace"){
					unlink ( "$line.isis.trace" ) or __OUT::Warning(" Failed to delete stubbed loc file $line.isis.trace --- \n");
				}
				
		}
		close(LST);
		unlink( "\\cleanupfiles.lst" ) or __OUT::Warning(" Failed to delete cleanupfiles.lst \n");
	}
}

sub SaveGeneratedResources
{
	my $tpath = shift;
	my $bldfile = shift;
	my $time1;
	my $time2;
	
	$time1 = time();
	__SaveGeneratedResource($tpath, $bldfile);
	$time2 = time();
	__OUT::Print ("Total Time SaveGeneratedResources:" .($time2-$time1)."\n");
}
sub __SaveGeneratedResource
{
	my $tpath = shift;
	my $bldfile = shift;
	my %hlist;
	
	#
	# Saving localised resources
	#
	__OUT::Print ("<b>Zipping generated resources</b>\n");
	__OUT::Print ("<b>bldfile ---- $bldfile"."_what_compile.log"."</b>\n");
	open (LOG, "$bldfile"."_what_compile.log") or __OUT::Die ("Cannot open"."$bldfile"."_what_compile.log:$!");		
	foreach my $line ( <LOG> )
	{
		chomp ($line);
		if ( $line =~ /^\\/ and $line =~ /\.r(\d+)$/i)
		{
			push @{ $hlist{$1} }, $line;
		}
	}
	close (LOG);

	#my $tpath = $self->{__tpath};
	mkpath ( "$tpath\\LocPackages" ) unless ( -e "$tpath\\LocPackages" );
	foreach my $lid ( sort keys %hlist )	
	{
		__OUT::Print ("<b>Zipping resources of language $lid</b>\n");	

		unlink ("\\resourcelist_${lid}.lst") if ( -e "\\resourcelist_${lid}.lst" );
		open (LST,">\\resourcelist_${lid}.lst");
		foreach ( sort @{ $hlist{$lid} } )
		{
			print LST "$_\n";
		}
		close (LST);
		my $zip = new ZipUp( "$tpath\\LocPackages\\package_${lid}.zip" );
		$zip->AddFilesFromList ( "\\resourcelist_${lid}.lst" );
	}
}

sub Cleanup
{
	my $self = shift;
	my @ll = ("sc");
	foreach my $c ( @{ $self->{__configuration} } )
	{
		#$c->RestoreOrigLocFiles();
		#$c->ChangeMMPsAndMKs( \@ll );
	}	
}
1;


## @class LocaliseTBS
# This is an internal class. It is a modelisation of the locinfo data line.
#
#
package LocaliseTBS;
use strict;
use File::Path;
use ISIS::GenBuildTools;
use IPC::Open3;
use File::Spec;  
use File::Basename;

use constant DEFAULT_XML_PATH => ".xml";
use constant DEFAULT_WHATXML_PATH => "_what.xml";
use constant DEFAULT_CHECKXML_PATH => "_check.xml";
use constant DEFAULT_TPATH => "\\zips";

sub Localise
{
	my $time1 = time();
	my $bldfile = shift;
	__OUT::Print ("Localisation starting - ".localtime()."\n");
	__OUT::Print ("Localisation  $bldfile -\n");
	GenBuildTools::BuildTBS( "$bldfile".DEFAULT_XML_PATH );
	GenBuildTools::BuildTBS( "$bldfile".DEFAULT_WHATXML_PATH );	
	GenBuildTools::BuildTBS( "$bldfile".DEFAULT_CHECKXML_PATH );	
	__OUT::Print ("Localisation ending - ".localtime()."\n");
	my $time2 = time();
	__OUT::Print ("Total Time:" .($time2-$time1)."\n");
}

1;



## @class __LocInfoData
# This is an internal class. It is a modelisation of the locinfo data line.
#
#
package __LocInfoData;
use strict;
use File::Copy;

sub CreateFromLine
{
	my ( $line ) = shift;
	
	# managing comments and empty lines
	return undef if ( $line =~ /^\s*((#|\/\/).*)*$/ );
	my @atoms = split( /,/, $line );

	if (scalar(@atoms)==3 or scalar(@atoms)==4 or scalar(@atoms)==5)
	{
			my @locfiles;
			my @mmps;
			#path,path_to_bld_inf,"list of mmp",["path/to.loc"[,"/path/to/delivery"]]
			if ($atoms[2] =~ s/\"([^\"]*)\"/$1/)
			{
				@mmps = split(/\s+/, $atoms[2]);
			}
			else
			{
				__OUT::Die("Malformed3 input file at line: '$line'\n");
			}
			if (scalar(@atoms)>3)
			{
				if ($atoms[3] =~ s/\"([^\"]*)\"/$1/)
				{
					@locfiles = split(/\s+/, $atoms[3])
				}
				else
				{
					__OUT::Die("Malformed4 input file at line: '$line'\n");
				}

			}
				
			if (scalar(@atoms)==5)
			{
				if ($atoms[4] =~ s/\"([^\"]*)\"/$1/)
				{
					my @tlocfiles = split(/\s+/, $atoms[4]);
					push @tlocfiles, &Localiser::DefaultLocPath();
					return new __LocInfoData($atoms[0], $atoms[1], \@mmps, \@locfiles, \@tlocfiles);
				}
				else
				{
					__OUT::Die("Malformed5 input file at line: '$line'\n");
				}
			}
			elsif (scalar(@atoms)==4)
			{
				my @tlocfiles;
				push @tlocfiles, &Localiser::DefaultLocPath();
				return new __LocInfoData($atoms[0], $atoms[1], \@mmps, \@locfiles, \@tlocfiles);
			}
			elsif (scalar(@atoms)==3)
			{
				my @tlocfiles;
				push @tlocfiles, &Localiser::DefaultLocPath();
				return new __LocInfoData($atoms[0], $atoms[1], \@mmps, \@locfiles, \@tlocfiles);
			}
		}
	return undef;
}

sub new
{
	my $class = shift;
	my ($path, $group, $mmps, $locfiles, $tlocfiles) = @_;
	my $self = {
			__path => $path,
			__group => $group,
			__mmps => $mmps,
			__mmpstype => undef,
			__locfiles => $locfiles,			
			__tlocfiles => $tlocfiles			
	};	
	return bless $self, $class; 
}


sub GetPath
{
	my $self = shift;
	return $self->{__path};
}

sub GetGroup
{
	my $self = shift;
	return $self->{__group};
}

sub GetMMPs
{
	my $self = shift;
	return $self->{__mmps};
}

sub GetMMPType
{
	my ($self, $mmp) = (shift, shift);
	return $self->{__mmpstype}->{$mmp}->{type};
}

sub GetLocFiles
{
	my $self = shift;
	return $self->{__locfiles};
}

sub GetTranslatedLocFiles
{
	my $self = shift;
	return $self->{__tlocfiles};
}

sub CheckBldInf
{
	my $self = shift;
	my $bldinf = $self->GetPath()."/".$self->GetGroup()."/bld.inf";
	unless ( -e $bldinf )
	{
		__OUT::Error ("Cannot find bld.inf in '$bldinf' directory\n");
		
		return 0;
	}
	return 1;
}

sub CheckLocFiles
{
	my $self = shift;
	my $result = 1;
	
	foreach ( @{ $self->{__locfiles} } )
	{
		my $loc = $self->GetPath()."/$_";
				
		unless ( -e $loc )
		{
			__OUT::Error ("Cannot find '$loc'\n");
    }
	}
	return $result;
}

sub ZipUpLocFiles
{
	my ( $self, $zip ) = (shift, shift);
	foreach ( @{ $self->{__locfiles} } )
	{
		my $loc = $self->GetPath()."/$_";
		$zip->AddFile( $loc );
	}	
}


sub GenerateStubLocFiles
{
	my ($self, $langlist) = (shift, shift);

	open (LST,">>\\cleanupfiles.lst");
	
	foreach ( @{ $self->{__locfiles} } )
	{
		my $loc = $self->GetPath()."/$_";

		print LST $loc."\n";

		$self->GenerateStubLocFile( $loc, $langlist );
	}	
	close (LST);
}

sub RestoreOrigLocFiles
{
	my ($self, $langlist) = (shift, shift);
	foreach ( @{ $self->{__locfiles} } )
	{
		
		
		my $loc = $self->GetPath()."/$_";
		
		if ( -e "$loc.isis.orig" )
		{
			unlink ( $loc ) or __OUT::Warning(" Failed to delete stubbed loc file $loc \n");
			copy ( "$loc.isis.orig", $loc) or __OUT::Warning(" Failed to restore loc file from $loc.isis.orig to $loc \n");
			unlink ( "$loc.isis.orig" ) or __OUT::Warning(" Failed to delete original backup loc file $loc \n");
		}
		
		if ( -e "$loc.isis.trace" )
		{
			unlink ( "$loc.isis.trace" ) or __OUT::Warning(" Failed to delete $loc.isis.trace \n");
			unlink ( "$loc" ) or __OUT::Warning(" Failed to delete original backup loc file $loc \n");
		}
		
		
	}	
}

sub GenerateStubLocFile
{
	my ($self, $locfile, $langlist) = (shift, shift, shift);
	
	my $sav = $locfile.".isis.orig";	
	my $trace = $locfile.".isis.trace";
	
	__OUT::Print (" Backuping $locfile as $sav \n");
	
	if ( -e "$trace" )
	{
		unlink ( $trace ) or __OUT::Warning(" Failed to delete $trace \n");
	}
	
	if ( -e "$sav" )
	{
		unlink ( $sav ) or __OUT::Warning(" Failed to delete stubbed loc file $sav \n");	
	}
	copy ($locfile, $sav) or __OUT::Error ("Cannot sav '$locfile'");
	
	unless ( -e "$locfile" )
	{
		open (TRACE, ">$trace") or __OUT::Error ("Cannot create trace file '$trace':$!");	
		print TRACE "// File generated by Localiser.pm for tracing missing loc file - DO NOT EDIT!\n\n";	
		close (TRACE);
	}
	
	__OUT::Print ("=== Stubbing '$locfile' ===\n");
	
	open (LOC, ">$locfile") or __OUT::Die ("Cannot open/create '$locfile':$!");
	print LOC "// File generated by Localiser.pm - DO NOT EDIT!\n\n";
	
	my $first = 1;
	my $name = $locfile;
	$name =~ /(\w+\.loc)$/;$name=$1;
	foreach my $lid ( @$langlist )
	{
			if ($first)
			{
				$first = 0;
				print LOC "#if defined(LANGUAGE_$lid)\n";				
			}
			else
			{
				print LOC "#elif defined(LANGUAGE_$lid)\n";				
			}
			my $f = $self->FindLocFor($name, $lid);
			if ($f)
			{
				print LOC "\t#include \"".&__MakeRlt($locfile, $f)."\"\n";
			}
			else
			{
				__OUT::Warning ("no translation to $lid for $locfile\n");
				print LOC "\t#warning no translation to $lid for $locfile\n";				
				if ( -e "$sav" )
				{
					$sav =~ /(\w+\.loc.isis.orig)$/;
					print LOC "\t#include \"$1\"\n";
				}
			}
	}
	if ( -e "$sav" )
	{
		print LOC "#else\n";
		print LOC "// fallback to EE by default\n";
		$sav =~ /(\w+\.loc.isis.orig)$/;
		print LOC "#include \"$1\"\n";
	}
	print LOC "#endif\n";
	print LOC "// END OF FILE\n";
	close (LOC);
}

sub __MakeRlt
{
	my ($spath, $dpath) = @_;
	#print "__MakeRlt($spath, $dpath)\n";
	# only backslahes
	$spath =~ s/\//\\/g;
	$dpath =~ s/\//\\/g;
	$spath =~ s/^.:\\/\\/;
	$dpath =~ s/^.:\\/\\/;
	# remove filename
	$spath =~ s/(\\|\/)\w+\.loc$/$1/;
	# remove transform abs to rel path
	$spath =~ s/\\[^\\]+/..\\/g;
	
	# clean up
	# no trailing, no double \\
	$dpath =~ s/^\\+//;
	$spath =~ s/\\+$//;
	$dpath =~ s/\\\\/\\/g;
	$spath =~ s/\\\\/\\/g;
	return $spath."\\".$dpath;
}

sub FindLocFor
{
	my ($self, $locfile, $lid) = (shift, shift, shift);
	
	my $target = $locfile;
	$target =~ s/\.loc$/_$lid.loc/i;

	foreach my $dir ( @{ $self->GetTranslatedLocFiles() } )
	{
		opendir(DIR, "$dir/$lid");
		my @files = readdir(DIR);
		close (DIR);
		
		foreach my $f ( @files )
		{
			if ( $f =~ /^$target$/i )
			{
				return "$dir/$lid/$target";
			}
		}
	}
	return undef;
}


sub TouchRSS
{
	my $self = shift;
	my $component = $self->GetPath();
	$component =~ s/\//\\/g;	
	foreach ( `dir /s/b $component\\*.rss 2>&1` )
	{
		chomp($_);
		`attrib -r $_ 2>&1`;
		`etouch $_ 2>&1`;
	}
}

sub ChangeMMPsAndMKs
{
		my ($self, $langlist,$zip) = @_;
		my $finder = new Finder( "\\.(mmp|mk)\$", $self->GetPath() );
		my $dmmps = $finder->Find();
		
		foreach my $mmp ( @{ $self->{__mmps} } )
		{
				__OUT::Print ("=== $mmp changing Language to [".join(' ',@$langlist)."]\n");
				my $dir = $self->GetPath()."/".$self->GetGroup();
				
				$self->{__mmpstype}->{$mmp}->{type} = 'notfound';
				foreach my $f ( @$dmmps )
				{
					my $uf = $f;
					$uf =~ s/\.(mmp|mk)$//i;
					if ( $uf =~ m/$mmp$/i )
					{
						__OUT::Print ("  + Found '$mmp' match => '$f'\n");
						$self->{__mmpstype}->{$mmp}->{path} = $f;
						if ( $f =~ /^.*\.mmp$/i )
						{
							$zip->AddFile($f);
							$self->{__mmpstype}->{$mmp}->{type} = 'mmp';
							$self->__AlterLanguage( $langlist, "$f" );
						}
						elsif ( $f =~ /^.*\.mk$/i )
						{
							$zip->AddFile($f);
							$self->{__mmpstype}->{$mmp}->{type} = 'mk';
							$self->__PatchMakefile( $langlist, "$f" ) if ( $f =~ /^.*\.mk$/i );
						}
						__OUT::Print ("  - Path: ".$self->{__mmpstype}->{$mmp}->{path}."\n");
						__OUT::Print ("  - Type: ".$self->{__mmpstype}->{$mmp}->{type}."\n");
					}
				}
				if ( $self->{__mmpstype}->{$mmp}->{type} eq 'notfound' )
				{
					__OUT::Error("Cannot find an mmp or mk file for this configuration definition: '$mmp'\n");     			
				}
		}
}

sub __PatchMakefile
{
	my ( $self, $langlist, $mkfilepath  ) = @_;
	print " - $mkfilepath\n";
	
	# Restoring if required.
	if( -e $mkfilepath.'.orig' )
	{
		print "  restoring orig file";
		unlink($mkfilepath);
		move ( $mkfilepath.'.orig', $mkfilepath );				
		return 1 if (((scalar(@$langlist))==1) and (@{$langlist}[0] =~ /\s*sc\s*/));
	}
	
	# saving orig file to .orig
	copy ($mkfilepath, $mkfilepath.'.orig') unless ( -e $mkfilepath.'.orig' );
	
	if ( open (MK, "$mkfilepath.orig") )
	{
		return 0 unless ( open (MKO, ">$mkfilepath") );
		print MKO "# DO NOT EDIT FILE PATCHED BY ISIS LOCALISER\n";
		foreach my $line ( <MK> )
		{
			if ($line =~ /^\s*LANGUAGE\s*=/i)
			{				
				print MKO "#ISISLOCALISERFIX $line";
			}
			elsif ( $line =~ /epocrc\.bat/i )
			{
				chomp($line);
				print MKO "$line -DLANGUAGE_\$(LANGUAGE)\n";
			}
			else
			{
				print MKO $line;
			}
		}
		close(MK);
		close (MKO);
		open (LST,">>\\cleanupfiles.lst");
		print LST "$mkfilepath\n";
		close(LST);
		return 1;
	}
	return 0;
}


sub __AlterLanguage
{
	my ($self, $langlist, $file) = @_;
	my ($type,$subst,$open_comment,$rss);
	if ($file =~ /\.mmp$/i) {
		$type="mmp";
	}
	elsif ($file =~ /\.mmpi$/i){
		$type="mmp";
	}
	else {
		print STDERR "Unknown file $file\n";
		return;
	}
	print " - $file\n";
	open(IN, $file);
	my @lines=<IN>;
	close (IN);
	
	foreach (@lines){
			if (m!^\s*/\*!){
					$open_comment=1;
					if (m!\*/!) {
							$open_comment=0;
					}
					next;
			}
			if (m!\*/!) {
					$open_comment=0;
					next;
			}
			next if ($open_comment);
			next if (m!^\s*//!);
			if ((/^\s*lang\s+\w+\s*/i) and ($type eq "mmp"))
			{
					$_ = "LANG\t".join(' ', @$langlist)."\n";
					$subst=1;
			}
			if (/\.rss/i)
			{
					$rss=1;
			}
	}
	if ($subst) {
			__OUT::Print (scalar(`attrib -r $file`));
			open (OUT,">$file") or __OUT::Die ("Cannot open $file for overwriting");
			print OUT @lines;
			close OUT;
	}
	elsif ($rss)
	{
			__OUT::Warning ("$file has no LANGUAGE or LANG definition in MMP,MK file\n");
	}
		
}

1;

## @package HelpManagement
#
#
package HelpManagement;
use strict;
use File::Copy;

sub Copy
{
	my ($languages, $path, $tpath) = @_;
	$tpath = $tpath || Localiser::DEFAULT_TPATH;
	
	my @help_destination_path=qw(\epoc32\data\z\resource\Help\ \epoc32\winscw\c\resource\Help\ );
	my $locfiledir="\\S60\\S60Helps\\Data"; # Default path to locfiles (can be changed by $locfile_path option)

	foreach my $lid (@$languages)
	{  	
		if (opendir (DIR,  $path."/$lid" ))
		{
			
			my $zip = new ZipUp( File::Spec->catfile($tpath,"LocPackages","package_${lid}.zip" ) );

			foreach my $file ( readdir(DIR))
			{  			
				if ($file =~ /(\w+\.h)lp$/i)
				{
					my $realname=lc($1).$lid;
					foreach my $dpath (@help_destination_path)
					{
						__OUT::Print ("Exporting '$path/$lid/$file' to '$dpath\\$realname'\n");
						copy ("$path/$lid/$file", "$dpath\\$realname");
						$zip->AddFile( "$dpath\\$realname" );
					}
				}
			}
			closedir(DIR);
		}
	}
}

1;

package DTDHandler;
use strict;
use File::Copy;
use File::Path;
use File::Find;     # for finding
use File::Basename; # for fileparse

my (@dtdfiles,@GeneratedFiles);
#-----------------------------------------------------------------------------------------
# DTDHandler::find_dtdfiles()
#
# Finds the input DTD files in supplied directory. This is call back function
#
# Parameters:
#-----------------------------------------------------------------------------------------

sub find_dtdfiles 
{
		my $dtd_name = $File::Find::name;
		$dtd_name =~ s/\//\\/g;    #Change / marks to \
		my($n, $d, $ext) = fileparse($dtd_name, '\..*');
		if( $ext =~ /\.dtd/i)
		{
				push @dtdfiles, $dtd_name;
		}
}

sub HandleDTD
{
		my ($locFilesPath,$dtdTarget) = (shift,shift);
		$dtdTarget .= "package_dtd.zip";

		my $dtd_path = "\\epoc32\\winscw\\c\\Nokia\\Installs\\MyThemes\\";
		my %original_dtd;
		@dtdfiles = ();
		@GeneratedFiles = ();
		
		# get components that include DTD files
		opendir(SDIR, ${dtd_path}) or __OUT::Die("can not read ${dtd_path}\n");
		my @folders = grep !/^\.\.?$/ && -d (${dtd_path}.$_), readdir SDIR;
		closedir(SDIR);

		foreach my $dtd_folder(@folders) {
			-d "${dtd_path}${dtd_folder}\\loc" || mkpath ("${dtd_path}${dtd_folder}\\loc",0,0x755);
		}
		
		#search for in dtd input files in loc files directory
		find( \&find_dtdfiles, "$locFilesPath" );
		
		#copy all dtd files to dtd handler input directory
		foreach (@dtdfiles)
		{
			foreach my $dtd_folder (@folders) {
				if ($_ =~ m/$dtd_folder/i) {
					xcopy ($_,"${dtd_path}${dtd_folder}\\loc");
				}
			}
		}

		__OUT::Print("==== DTD generation  ====\n");
		#create Dtd files
		foreach my $dtd_folder (@folders) {
			__OUT::Print(`\\epoc32\\RELEASE\\WINSCW\\UREL\\XnThemeInstallerCons.exe c:\\Nokia\\installs\\MyThemes\\${dtd_folder}\\loc\\ 2&>1`);
			rmtree( "\\epoc32\\WINSCW\\C\\private\\10207254\\themes\\sources" );
			# this kind of xcopy call MUST be replaced by a Perl command
			__OUT::Print(`call xcopy \\epoc32\\WINSCW\\C\\private\\10207254\\themes\\* \\epoc32\\data\\z\\private\\10207254\\themes\\ \/E \/I \/Y \/R`);
			__OUT::Print(`call xcopy \\epoc32\\WINSCW\\C\\private\\10207254\\themes\\* \\epoc32\\release\\winscw\\udeb\\z\\private\\10207254\\themes\\ \/E \/I \/Y \/R`);
			__OUT::Print(`call xcopy \\epoc32\\WINSCW\\C\\private\\10207254\\themes\\* \\epoc32\\release\\winscw\\urel\\z\\private\\10207254\\themes\\ \/E \/I \/Y \/R`); 
		}
		
		__OUT::Print("==== DTD Language packaging  ====\n");
	
		system ("zip -r -q ${dtdTarget} \\epoc32\\data\\z\\private\\10207254\\themes\\* \\epoc32\\release\\winscw\\udeb\\z\\private\\10207254\\themes\\* \\epoc32\\release\\winscw\\urel\\z\\private\\10207254\\themes\\*");

		__OUT::Print("==== Done DTD  ====\n");
}

#-----------------------------------------------------------------------------------------
# DTDHandler::CopyDTDFiles($lid, $s60locpath)
#
# Copy the DTD files
#
# Parameters:
#-----------------------------------------------------------------------------------------
sub CopyDTDFiles
{
		my ($language,$locFilesPath) =  (shift, shift);
		my @list = ();
		@dtdfiles = ();

		#search for in dtd input files in loc files directory
		find( \&find_dtdfiles, "$locFilesPath" );


		my $file_found_flag = 0;
		foreach my $file (@dtdfiles)
		{
				my($n, $d, $ext) = fileparse($file, '\..*');
				
				# find if file name without extention ends with language id.
				if ($n =~ /\_$language$/i)
				{
						$file_found_flag = 1;
						
						#remove language id from the file name
						$n =~ s/\_$language$//i;
						
						#copy dtd file to \epoc32\data\Z\private\101F4CD2\Content\<language> directory
						my $dist = "\\epoc32\\data\\Z\\private\\101F4CD2\\Content\\$language\\$n$ext";
						
						__OUT::Print("Copy '$file' to '$dist'\n");
						xcopy($file,$dist);
						push (@list,$dist); 
						
						#copy dtd file to \epoc32\release\winscw\udeb\Z\private\101F4CD2\Content\<language> directory
						$dist =~ s/data/RELEASE\\WINSCW\\UDEB/i;
						__OUT::Print("Copy '$file' to '$dist'\n");
						xcopy($file,$dist);
						push (@list,$dist); 
						
						#copy dtd file to \epoc32\release\winscw\urel\Z\private\101F4CD2\Content\<language> directory
						$dist =~ s/UDEB/UREL/i;
						__OUT::Print("Copy '$file' to '$dist'\n");
						xcopy($file,$dist);
						push (@list,$dist); 
				}
		}
		
		__OUT::Print("Error: Dtd files for $language not found!!!") if (! $file_found_flag);
		
		return @list;
}

#-----------------------------------------------------------------------------------------
# DTDHandler::xcopy()
#
# copies file from source path to destination path. 
#
# Parameters:
#       Source file with path
#       Destination file with path
#-----------------------------------------------------------------------------------------

sub xcopy
{
		my $source = shift;
		my $dist = shift;
		
		# if distination file exist then clear read flag
		if (-f $dist)
		{
				chmod ($dist , 0755);
		}
		else
		{
				my($n, $d, $ext) = fileparse($dist, '\..*');
				# check weather distination directory exist or not. If directory doesn't exist then create it.
				-d $d || mkpath($d, 0, 0x755);
		}
		
		# copy source to distination
		copy($source,$dist);
}

1;

## @package Locales
#
#
package Locales;
use File::Spec;

sub CreatesLocales
{
	my ($languages, $product, $flags, $ddir) = @_;
	
	$ddir = $ddir || Localiser::DEFAULT_TPATH;
	
	foreach my $lid (@$languages)
	{
		my $zip = new ZipUp( File::Spec->catfile($ddir,"LocPackages","package_${lid}.zip") );
		$zip->AddFile( __GenerateLocalesIBY((defined($product))?"${product}_":'', $lid, $flags) );
	}
}

use IPC::Open3;  
sub __GenerateLocalesIBY($$$)
{
	my ($prefix, $langcode, $flags) = @_;
	return if ($langcode =~ /sc/);
	return if ($langcode !~ /\d+/);
	
	my $output = File::Spec->catfile("/epoc32/rom/include","${prefix}locales_$langcode.iby");
	
	__OUT::Print ("Generating $output...\n");
	
	open (OUT, ">$output");
	print OUT "#ifndef __LOCALES_".$langcode."_IBY__\n";
	print OUT "#define __LOCALES_".$langcode."_IBY__\n";
	
	
	my $arg = "-I ..\\include\\oem -I .\\include -I.\\Variant ";
	foreach (@$flags) { $arg .= " -D$_ "; }
	

	# use open3 to manage the error stream
	chdir ("\\epoc32\\rom");
	local (*WTRFH, *RDRFH, *ERRFH);
	my $cmd = "cpp -nostdinc -u $arg  include\\locales_sc.iby -include .\\include\\header.iby";	
	__OUT::Print ("Calling $cmd\n");
	my $childpid = open3(\*WTRFH, \*RDRFH, \*ERRFH, $cmd);
	close(WTRFH);
	while(<RDRFH>)
	{
		if  (/^\s*data\s*=\s*MULTI_LINGUIFY/)
		{
			/MULTI_LINGUIFY\s*\(\s*(\S+)\s+(\S+)\s+(\S+)\s*\)/;
			my $ext = $1;
			my $w1 = $2;
			my $w2 = $3;
			if ( $ext=~ /^RSC$/i )
			{
				$ext =~ s/RSC/r$langcode/i;
				print OUT "data=$w1.$ext $w2.$ext\n";
			}
			else
			{
				__OUT::Warning ("Cannot extract '$_'");
			}
		}
		elsif (/\.rsc/i)
		{
			s/\.rsc/\.r$langcode/ogi;
			print OUT $_;
		}
		elsif (/\.dbz/i)
		{
			s/\.dbz/\.d$langcode/ogi;
			print OUT $_;
		}
		elsif (/\.hlp/i)
		{
			s/\.hlp/\.h$langcode/ogi;
			print OUT $_;
		}
		elsif ( /\\elocl\.dll/i )
		{			
			s/elocl\.dll/elocl\.$langcode/ogi;
			s/elocl\.loc/elocl\.$langcode/ogi;
			print OUT $_;
		}
		#rename Content\01 to Content\xx (where xx is language id). This is for handlng DTD files
		elsif (/Content\\01/)
		{
			s/Content\\01/Content\\$langcode/ogi;
			print OUT $_;
		}
		#rename .o0001 to .0xx (where xx is language id). This is for handlng DTD files
		elsif (/\.o0001/i)
		{
			my $line = $_;
			my $lang = $langcode;
			#round up language id to 4 digis
			while (length($lang) < 4)
			{
				$lang = "0".$lang;
			}

			$line =~ s/\.o0001/\.o$lang/ogi;
			print OUT $line;
		}
		elsif ( /^\s*(data|file)=/ )
		{
			__OUT::Warning ("This should not be included in resource.iby '$_'\nThis file should be included using an 'applicationnameVariant.iby' file.\n");
		}
	}
	print OUT "#endif\n";
	close(OUT);
	# Closing cleanly....
	close(RDRFH);	
	
	# Manage cpp errors
	my $err = "";
	while(<ERRFH>) { $err .= "$_\n";}
	if (not ($err eq "")){ __OUT::Error ("$err"); }

	# Closing cleanly....
	close(ERRFH);
	waitpid($childpid, 0);

	chdir("\\");
	return $output;
}

1;
# End of File
