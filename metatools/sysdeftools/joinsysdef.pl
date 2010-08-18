# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
#!/usr/bin/perl

use strict;


use FindBin;		# for FindBin::Bin
use lib $FindBin::Bin;
use lib "$FindBin::Bin/lib";

use Cwd;
use Cwd 'abs_path';
use Getopt::Long;
use File::Basename;
use File::Spec;
use XML::DOM;

my $output;
my $path;
my @config;
my @includes;
my %defineParams;
my %defines;
my $defaultns = 'http://www.symbian.org/system-definition';	# needed if no DTD
my @excludeMetaList;
my @cannotExclude= ('link-mapping', 'config');
my %ID;	# list of all IDs

my @newarg;
foreach my $a (@ARGV)
	{ #extract all -I parameters from the parameter list 
	if($a=~s/^-I//)
		{
		push(@includes,$a);
		}
	else
		{
		push(@newarg,$a);
		}
	}
@ARGV=@newarg;

# need to add options for controlling which metas are filtered out and which are included inline
GetOptions
	(
	 'path=s' => \$path,
	'output=s' => \$output,
	'config=s' => \@config,
	'exclude-meta=s' => \@excludeMetaList
	);

# -path specifies the full system-model path to the file which is being processed. 
#	This must be an absolute path if you're processing a root sysdef.
#	If processing a pkgdef file, you can use "./package_definition.xml" to leave all links relative. Though I can't really see the use case for this.

# -output specifies the file to save the output to. If not specified this will write to stdout

# -config specifies the name of an .hrh file in which the configuration data is acquired from. If not set, no confguration will be done.

# -I[path] specifies the include paths to use when resolving #includes in the .hrh file. Same syntax as cpp command uses. Any number of these can be provided.


# if config is not set, no confguration will be done.
# If it is set, all configuration metadata will be processed and stripped from the output, even if the confguration data is empty

 if($path eq '') {$path = '/os/deviceplatformrelease/foundation_system/system_model/system_definition.xml'}

($#ARGV == -1 ) && &help();
my $sysdef = &abspath(shift);	# resolve the location of the root sysdef


my %excludeMeta;
foreach (@excludeMetaList) {$excludeMeta{$_}=1}	# make list a hash table
foreach (@cannotExclude)
	{
	$excludeMeta{$_} && print STDERR "Error: Cannot exclude meta rel=\"$_\"\n";
	$excludeMeta{$_}=0
	}	# cannot exclude any of these rel types


# rootmap is a mapping from the filesystem to the paths in the doc
my %rootmap = &rootMap($path,$sysdef);	
my %nsmap;
my %urimap;

foreach my $conf (@config) 
	{ # run cpp to get all #defines
	&getDefines($conf);
	}

my $parser = new XML::DOM::Parser;
my   $sysdefdoc = $parser->parsefile ($sysdef);


my $maxschema = $sysdefdoc->getDocumentElement()->getAttribute('schema');	# don't check value, just store it.


# find all the namespaces used in all trhe fragments and use that 
# to set the namespaces ni the root element of the created doc
#   should be able to optimise by only parsing each doc once and 
#	maybe skipping the contends of <meta>
my @nslist = &namespaces($sysdef,$sysdefdoc->getDocumentElement());


while(@nslist)
	{
	my $uri = shift(@nslist);
	my $prefix =shift(@nslist);
	if($prefix eq 'id namespace'){$prefix=''}
	if(defined $urimap{$uri}) {next} # already done this uri
	$urimap{$uri} = $prefix;
	if($nsmap{$prefix})
		{ # need a new prefix for this, guess from the URI (for readability)
		if($uri=~/http:\/\/(www\.)?([^.\/]+)\./) {$prefix = $2}
		my $i=0;
		while($nsmap{$prefix})
			{ # still no prefix, just make up 
			$prefix="ns$i";
			$i++;
			# next line not really necessary, but it's a good safety to stop infinite loops
			$i eq 1000 && die "cannot create namespace prefix for $uri";
			}
		}
	$nsmap{$prefix}=$uri;
	}

my $docroot =  $sysdefdoc->getDocumentElement;

my $ns = $docroot->getAttribute('id-namespace');
if(!$ns && $nsmap{''})
	{
	$docroot->setAttribute('id-namespace',$nsmap{''});
	}

$docroot->setAttribute('schema',$maxschema);	# output has the largest syntax version of all includes


while(my($pre,$uri) = each(%nsmap))
	{
	$pre ne '' || next ;
	$docroot->setAttribute("xmlns:$pre",$uri);
	}

&walk($sysdef,$docroot);	# process the XML


# print to file or stdout
if($output eq '') 
	{
	print $sysdefdoc->toString;
	}
else
	{
	$sysdefdoc->printToFile($output);
	}

 
sub abspath
	{ 	# normalize the path into an absolute one
	my  ($name,$path) = fileparse($_[0]);
	$path=~tr,\\,/,;
	if( -e $path)
		{
		return abs_path($path)."/$name";
		}
	my @dir = split('/',$_[0]);
	my @new;
	foreach my $d (@dir)
		{
		if($d eq '.') {next}
		if($d eq '..')
			{
			pop(@new);
			next;
			}
		push(@new,$d)
		}
	return join('/',@new);
	}

sub rootMap {
	my @pathdirs = split(/\//,$_[0]);
	my @rootdirs = split(/\//,$_[1]);

	while(lc($rootdirs[$#rootdirs])  eq lc($pathdirs[$#pathdirs])  )
		{
		pop(@rootdirs);
		pop(@pathdirs);
		}
	return (join('/',@rootdirs)  => join('/',@pathdirs) );
	}

sub rootMapMeta {
	# find all the explict path mapping from the link-mapping metadata
	my $node = shift;
	foreach my $child (@{$node->getChildNodes})
			{
			if ($child->getNodeType==1 && $child->getTagName eq 'map-prefix')
				{
				my $from = $child->getAttribute('link');
				my $to = $child->getAttribute('to');		# optional, but blank if not set
				$rootmap{$from} = $to;
				}
			}
	# once this is processed we have no more need for it. Remove from output
	$node->getParentNode->removeChild($node);
	}


sub walk
	{ 	# walk through the doc, resolving all links
	my $file = shift;
	my $node = shift;
	my $type = $node->getNodeType;
	if($type!=1) {return}
	my $tag = $node->getTagName;
	if($tag=~/^(layer|package|collection|component)$/ )
		{
		if($file eq $sysdef)
			{
			&fixIDs($node);	# normalise all IDs in the root doc. Child docs are handled elsewhere.
			}
		my $link= $node->getAttribute('href');
		if($link)
			{
			my $file = &resolvePath($file,$link); 
			if(-e $file)
				{
				&combineLink($node,$file);
				}
			else
				{
				print STDERR "Note: $file not found\n";
				$node->removeAttribute('href');
				}
			return;
			}
		else 
			{ # only check for duplicate IDs on the implementation
			my $id= $node->getAttribute('id');
			my $p = $node->getParentNode();
			my $ptext = $p->getTagName()." \"".$p->getAttribute('id')."\"";
			if(defined $ID{$id})
				{
				print STDERR "Error: duplicate ID: $tag \"$id\" in $ptext matches $ID{$id}\n";
				}
			else 
				{
				my $p = $node->getParentNode();
				$ID{$id}="$tag in $ptext";
				}
			}
		}
	elsif($tag=~/^(SystemDefinition|systemModel)$/ )
		{
		}
	elsif($tag eq 'unit')
		{
		foreach my $atr ('bldFile','mrp','base','proFile')
			{
			my $link= $node->getAttribute($atr);
			if($link && !($link=~/^\//))
				{
				$link= &abspath(File::Basename::dirname($file)."/$link");
				foreach my $a (keys %rootmap) {
					$link=~s,^$a,$rootmap{$a},ie;
				}
				# remove leading ./  which is used to indicate that paths should remain relative
				$link=~s,^\./([^/]),$1,; 
				$node->setAttribute($atr,$link);
				}
			}
		}
	elsif($tag eq 'meta')
		{
		my $rel= $node->getAttribute('rel') || 'Generic';
		if($excludeMeta{$rel})
			{
			$node->getParentNode->removeChild($node);
			return;
			}
		my $link= $node->getAttribute('href');
		$link=~s,^file://(/([a-z]:/))?,$2,; # convert file URI to absolute path
		if ($link ne '' ) 
			{ 
			if($link=~/^[\/]+:/)
				{
				print STDERR "Note: Remote URL $link not embedded\n";
				next; # do not alter children
				}
			if(! ($link=~/^\//))
				{
				$link= &abspath(File::Basename::dirname($file)."/$link");
				}
			if(! -e $link) 
				{
				print STDERR "Warning: Local metadata file not found: $link\n";
				next; # do not alter children
				}
			# if we're here we can just embed the file
			# no processing logic is done! It's just embedded blindly
			my $item;
			eval {
				my  $metadoc = $parser->parsefile ($link);
				$item = $metadoc->getDocumentElement;
			};
			if(!$item)
				{
				print STDERR "Error: Could not process metadata file: $link\n";
				next; # do not alter children
				}
			$node->removeAttribute('href');
			&blindCopyInto($node,$item);
			}
		if($node->getAttribute('rel') eq 'link-mapping')
			{# need to process this now
			&rootMapMeta($node);
			}
		return;
		}
	else {return}
	my $checkversion=0;
	foreach my $item (@{$node->getChildNodes})
		{
		#print $item->getNodeType,"\n";
		&walk($file,$item);
		$checkversion = $checkversion  || ($tag eq 'component' &&  $item->getNodeType==1 && $item->getAttribute('version') ne '');
		}

	if($checkversion && scalar(@config))
		{ # need to check the conf metadata on the units in this component
		&doCmpConfig($node);
		}
	foreach my $item (@{$node->getChildNodes})
		{
		if ($item->getNodeType==1 && $item->getTagName eq 'meta')
			{
			&processMeta($item);
			}
		}
	}


sub combineLink
	{
	# combine data from linked sysdef fragment w/ equivalent element in parent document
	my $node = shift;
	my $file = shift;
	my $getfromfile = &localfile($file);
	$getfromfile eq '' && return;  # already raised warning, no need to repeat
	my  $doc = $parser->parsefile ($getfromfile);
	my $item =&firstElement($doc->getDocumentElement);
	$item || die "badly formatted $file";	
	&fixIDs($item);
	my %up = &atts($node);
	my %down = &atts($item);
	$up{'id'} eq $down{'id'}  || die "$up{id} differs from $down{id}";
	$node->removeAttribute('href');
	foreach my $v (keys %up) {delete $down{$v}}
	foreach my $v (keys %down)
		{
		$node->setAttribute($v,$down{$v})
		}
	foreach my $child (@{$item->getChildNodes})
		{
		&copyInto($node,$child);
		}
	&walk($file,$node);
	}


sub blindCopyInto
	{
	# make a deep copy the node (2nd arg) into the element (1st arg)
	my $parent=shift;
	my $item = shift;
	my $doc = $parent->getOwnerDocument;
	my $type = $item->getNodeType;
	my $new;
	if($type==1) 
		{
		$new = $doc->createElement($item->getTagName);
		my %down = &atts($item);
		while(my($a,$b) = each(%down))
			{
			$new->setAttribute($a,$b);
			}
		foreach my $child (@{$item->getChildNodes})
			{
			&blindCopyInto($new,$child);
			}
		}
	elsif($type==3) 
		{
		$new = $doc->createTextNode ($item->getData);
		}
	elsif($type==8) 
		{
		$new = $doc->createComment  ($item->getData);
		}
	if($new)
		{
		$parent->appendChild($new);
		}
	}

sub copyInto
	{
	# make a deep copy the node (2nd arg) into the element (1st arg)
	my $parent=shift;
	my $item = shift;
	my $doc = $parent->getOwnerDocument;
	my $type = $item->getNodeType;
	my $new;
	if($type==1) 
		{
		&fixIDs($item);
		$new = $doc->createElement($item->getTagName);
		my %down = &atts($item);
		foreach my $ordered ('id','name','bldFile','mrp','level','levels','introduced','deprecated','filter')
			{
			if($down{$ordered})
				{
				$new->setAttribute($ordered,$down{$ordered});
				delete $down{$ordered}
				}
			}
		while(my($a,$b) = each(%down))
			{
			$new->setAttribute($a,$b);
			}
		foreach my $child (@{$item->getChildNodes})
			{
			&copyInto($new,$child);
			}
		}
	elsif($type==3) 
		{
		$new = $doc->createTextNode ($item->getData);
		}
	elsif($type==8) 
		{
		$new = $doc->createComment  ($item->getData);
		}
	if($new)
		{
		$parent->appendChild($new);
		}
	}

sub getNs
	{
	# find the namespace URI that applies to the specified prefix.
	my $node = shift;
	my $pre = shift;
	my $uri = $node->getAttribute("xmlns:$pre");
	if($uri) {return $uri}
	my $parent = $node->getParentNode;
	if($parent && $parent->getNodeType==1)
		{
		return getNs($parent,$pre);
		}
	}


sub fixIDs
	{
	# translate the ID to use the root doc's namespaces 
	my $node = shift;
	foreach my $id ('id','before')
		{
		&fixID($node,$id);
		}
}

sub fixID
	{
	# translate the ID to use the root doc's namespaces 
	my $node = shift;
	my $attr = shift || 'id';
	my $id = $node->getAttribute($attr);
	if($id eq '') {return}
	my $ns;
	if($id=~s/^(.*)://)
		{ # it's got a ns, find out what it is
		my $pre = $1;
		$ns=&getNs($node,$pre);
		}
	else
		{
		$ns = $node->getOwnerDocument->getDocumentElement->getAttribute("id-namespace") ||
			$defaultns;
		}
	$ns = $urimap{$ns};
	$id = ($ns eq '') ? $id : "$ns:$id";
	return $node->setAttribute($attr,$id);
}

sub firstElement {
	# return the first element in this node
	my $node = shift;
	foreach my $item (@{$node->getChildNodes}) {
		if($item->getNodeType==1) {return $item}
	}
}


sub atts {
	# return a hash of all attribtues defined for this element
	my $node = shift;
	my %at = $node->getAttributes;
	my %list;
	foreach my $a (keys %{$node->getAttributes}) 
		{
		if($a ne '')
			{
			$list{$a} = $node->getAttribute ($a);
			}
		}
	return %list;
}


sub ns 
	{
	# return a hash of ns prefix and uri -- the xmlns: part is stripped off
	my $node = shift;
	my %list;
	foreach my $a (keys %{$node->getAttributes}) 
		{
		my $pre = $a;
		if($pre=~s/^xmlns://)
			{
			$list{$pre} = $node->getAttribute ($a);
			}
		}
	return %list;
	}


sub resolvePath
	{
	# return full path to 2nd arg relative to first (path or absolute URI)
	my $base = shift;
	my $path = shift;
	if($path=~m,^/,) {return $path } # path is absolute, but has no drive. Let OS deal with it.
	if($path=~s,^file:///([a-zA-Z]:/),$1,) {return $path } # file URI with drive letter
	if($path=~m,^file://,) {return $path } # file URI with no drive letter (unit-style). Just pass on as is with leading / and let OS deal with it
	if($path=~m,^[a-z0-9][a-z0-9]+:,i) {return $path } # absolute URI -- no idea how to handle, so just return
	return &abspath(File::Basename::dirname($base)."/$path");
	}


sub resolveURI
	{
	# return full path to 2nd arg relative to first (path or absolute URI)
	my $base = shift;
	my $path = shift;
	if($path=~m,[a-z0-9][a-z0-9]+:,i) {return $path } # absolute URI -- just return
	if($path=~m,^/,) {return $path } # path is absolute, but has no drive. Let OS deal with it.
	return &abspath(File::Basename::dirname($base)."/$path");
	}

sub localfile
	{
	my $file = shift;
	if($file=~s,file:///([a-zA-Z]:/),$1,) {return $file } # file URI with drive letter
	if($file=~m,file://,) {return $file } # file URI with no drive letter (unit-style). Just pass on as is with leading / and let OS deal with it
	if($file=~m,^([a-z0-9][a-z0-9]+):,i)
		{
		print STDERR "ERROR: $1 scheme not supported\n";
		return;  # return empty string if not supported.
		} 
	return $file
	}

sub namespaces
	{
	# return a list of namespace URI / prefix pairs, in the order they're defined
	# these need to be used to define namespaces in the root element
	my $file = shift;
	my $node = shift;
	my $type = $node->getNodeType;
	if($type!=1) {return}
	my $tag = $node->getTagName;
	my @res;
	my %nslist = &ns($node);
	while(my($pre,$uri)=each(%nslist))
		{ # push all namespaces defined here onto the list
		push(@res,$uri,$pre);
		}
	if($tag=~/^(layer|package|collection|component)$/ )
		{ # these have the potential of linking, so check for that
		my $link= $node->getAttribute('href');
		if($link)
			{
			$link=&resolvePath($file,$link);
			if(-e $link)
				{
				my  $doc;
				eval {
					$doc = $parser->parsefile ($link);
				};
				if($doc)
					{
					&checkSyntaxVersion($doc->getDocumentElement->getAttribute('schema'));	# ensure we track we highest syntax number
					my @docns = &namespaces($link,$doc->getDocumentElement);
					undef $doc;
					return (@res,@docns);
					#ignore any children nodes if this is a link
					}
				print STDERR "Error: Malformed XML. Could not process $link\n";
				}
			# print STDERR "Note: $link not found\n";  -- no need to warm now. Do so later when trying to join
			}
		}
	elsif($tag eq 'SystemDefinition' )
		{
		my $default = $node->getAttribute('id-namespace');
		if($default)
			{# mangle with a space so it's clear it's not a qname
			push(@res,$default,'id namespace');
			}
		}
	foreach my $item (@{$node->getChildNodes})
		{
		push(@res,&namespaces($file,$item));
		}
	return @res;
	}

sub processMeta
	{ # acts upon any known <meta> and strips it from the output if it's used
	my $metanode = shift;

	my $rel = $metanode->getAttribute('rel') || 'Generic';
	if($rel eq 'config' && scalar(@config))
		{ # only process if there is something to configure
		&doconfig($metanode);
		}
	else 
		{
		# do nothing. Not supported yet
		}
	}

sub doCmpConfig
	{ # configure in or out the units in a component
	my $cmp = shift;	# the component node
	my @unversioned;	# list of all units with no version attribute (if more than one, they should all have filters defined)
	my %versioned;		# hash table of all units with a specified version, it's a fatal error to hav the same verison twice in one component
	foreach my $item (@{$cmp->getChildNodes})
		{ # populate %versioned and @unversioned to save processsing later
		if($item->getNodeType==1 && $item->getTagName eq 'unit')
			{
			my $ver = $item->getAttribute('version');
			if($ver eq '') {push(@unversioned,$item)}
			else
				{
				defined $versioned{$ver}  && die "Cannot have more than one unit with version $ver in the same component ".$cmp->getAttribute('id');
				$versioned{$ver}=$item;
				}
			}
		}
	my @picks = &getMetaConfigPick($cmp); # the list, in order, of all <pick> elements that affect this component
	foreach my $pick (@picks)
		{
		my $ver = $pick->getAttribute('version');
		if(!$versioned{$ver})
			{
			print STDERR "ERROR: Reference to invalid unit version $ver in component ",$cmp->getAttribute('id'),". Ignoring.\n";
			return;
			}
		if(&definedMatches($pick))
			{ # remove all other units;
			delete $versioned{$ver}; # to avoid removing in loop
			foreach my $unit (@unversioned, values(%versioned))
				{
				$cmp->removeChild($unit);
				print STDERR "Note: unit ",$unit->getAttribute('version')," in component " ,$cmp->getAttribute('id')," configured out\n";
				}
			last; # done. No more processing after first match
			}
		else
			{ # remove this unit and continue
			$cmp->removeChild($versioned{$ver});
			print STDERR "Note: unit $ver in component " ,$cmp->getAttribute('id')," configured out\n";
			delete $versioned{$ver}; # gone, don't process anymore;
			}
		}
	if (scalar(@unversioned, values(%versioned)) > 1)
		{
		print STDERR "Warning: component ",$cmp->getAttribute('id')," has more than one unit after configuration\n";
		}
	}

	
sub getMetaConfigPick
	{	# return an array of all <pick> elements that affect the specified element
	my $node = shift;
	my @pick;
	while($node->getParentNode->getNodeType==1)
		{
		foreach my $item (@{$node->getChildNodes})
			{
			my @picks;
			if($item->getNodeType==1 &&  $item->getAttribute('rel') eq 'config') 
				{ # it's conf metadata
				foreach my $p (@{$item->getChildNodes})
					{
					if($p->getNodeType==1 &&  $p->getTagName eq 'pick') {push(@picks,$p)}
					}
				}
			@pick=(@picks,@pick); # prepend this to the start;
			}
		$node=$node->getParentNode;
		}
	return @pick;
	}

sub definedMatches
	{ # process all <defined> and <not-defined> the specified element and return true or false if the combination matches
	my $node  = shift;
	my $match = 1;
	foreach my $def (@{$node->getChildNodes})
		{
		if($def->getNodeType == 1) 
			{
			my $tag = $def->getTagName;
			if($tag eq 'defined' or $tag eq 'not-defined')
				{
				my $var = $def->getAttribute('condition') || die "Must have condition set on all $tag elements";
				$defineParams{$var} && die "Cannot use a macro with parameters as a feature flag: $var(".$defineParams{$var}->[0].")"; 
				$match = $match &&  (($tag eq 'defined') ? defined($defines{$var}) : ! defined($defines{$var}));
				}
			}
		}
		return $match;
	}

sub doconfig
	{ # confgure in or out a system model item that owns the specified <meta>, remove the <meta> when done.
	my $meta  = shift;
	my $keep = definedMatches($meta);
	my $parent = $meta->getParentNode;
	if(!$keep)
		{
		print STDERR "Note: ",$parent->getTagName," " ,$parent->getAttribute('id')," configured out\n";
		$parent->getParentNode->removeChild($parent);
		return; # it's removed, so there's nothing else we can possibly do
		}

	$parent->removeChild($meta);
	}

sub getDefines
	{ # populate the list of #defines from a specified .hrh file.
	my $file = shift;
	my $inc;
	foreach my $i (@includes)
		{
		$inc.=" -I$i";
		}
	open(CPP,"cpp -dD$inc \"$file\"|");
	while(<CPP>)
		{
		if(!/\S/){next} # skip blank lines
		if(/^# [0-9]+ /) {next} # don't care about these
		s/\s+$//;
		if(s/^#define\s+(\S+)\((.*?)\)\s+//)
			{ #parametered define
			push(@{$defineParams{$1}},@2,$_);
			}
		elsif(s/^#define\s+(\S+)//)
			{ # normal define
			my $def = $1;
			s/^\s+//;
			$defines{$1}=$_;
			}
		else {die "cannot process $_";}
		}
	close CPP;
	$? && die "Call to cpp produced an error";
	}

sub  checkSyntaxVersion
	{ # check if supplied version number is greater than $maxschema
	my $schema = shift;
	my @max=split(/\./,$maxschema);
	my @cur=split(/\./,$schema);
	while(@max) 
		{
		($max[0] > $cur[0])  && return;		# max is bigger, do nothing
		if($cur[0] > $max[0])
			{
			$maxschema=$schema;
			return;
			}
		shift @max;
		shift @cur;
		}
	# they are equal - do nothing
	}

sub help
	{
	my $name= $0; $name=~s,^.*[\\/],,;
my $text;
format STDERR =
 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  $text,
     ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~~
    $text
.
print STDERR "usage: $name  [options...] sysdef\n  valid options are:\n\n";
	foreach (
		"-path\tspecifies the full system-model path to the file which is being processed. By default this is  \"/os/deviceplatformrelease/foundation_system/system_model/system_definition.xml\"",
			"   This must be an absolute path if you're processing a root sysdef.",
			"   If processing a pkgdef file, you can use \"./package_definition.xml\" to leave all links relative.",

		"-output\tspecifies the file to save the output to. If not specified this will write to stdout",

		"-config\tspecifies the name of an .hrh file in which the configuration data is acquired from. If not set, no confguration will be done.",
			"   If it is set, all configuration metadata will be processed and stripped from the output, even if the confguration data is empty",
		"-I[path]\tspecifies the include paths to use when resolving #includes in the .hrh file. This uses the same syntax as cpp command uses: a captial \"I\" followed by the path with no space in between. Any number of these can be provided.",
		"-exclude-meta [rel]\tspecifies the 'rel' value of <meta> elements to exclude from the output. Any number of these can be provided. The following meta rel values affect the processing of the system definition and cannot be excluded: ".join(', ',@cannotExclude)
		) {
		$text = $_;
		write STDERR;
		print STDERR "\n";
	}

	exit(1);
	}


	
