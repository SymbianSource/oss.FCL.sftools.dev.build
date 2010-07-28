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
#  This will create a new root system definition file based on the provided template
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
my $defaultns = 'http://www.symbian.org/system-definition';	# needed if no DTD
my @searchpaths;
my @searchroots;
my %additional;
my %add;
my %newNs;
my $warning = "Error";
my $placeholders=0;
my $sysmodelname;

my @tdOrder =("hb","se", "lo","dc", "vc" , "pr", "dm", "de", "mm", "ma" , "ui",  "rt", "to" );

sub help
	{
	my $name= $0; $name=~s,^.*[\\/],,;
	print STDERR "usage: $name  [options...] template\n\nThis will create a new root system definition file based on the provided template by globbing for pkgdefs in the filesystem. Any found pkgdef files are added to the end of their layer or at the end of their tech domain section, if one is defined",
	"\nvalid options are:\n",
		"  -path [dir]\tspecifies the full system-model path to the file which is being processed. By default this is  \"/os/deviceplatformrelease/foundation_system/system_model/system_definition.xml\"\n",
		"\t\tThis is only needed when creating a stand-alone sysdef as the output",

		"  -output [file]\tspecifies the file to save the output to. If set, all hrefs will set to be relative to this location. If not specified all href will be absolute file URIs and this will write to stdout\n\n",

		"  -w [Note|Warning|Error]\tspecifies prefix text for any notifications. Defautls to Error\n\n",
		"  -root [dir]\tspecifies the root directory of the filesystem. All globbing will be done relative to this path\n\n",

		"  -glob [wildcard path]\tThe wildcard search to look for pkgdef files. eg  \"\\*\\*\package_definition.xml\". Can specify any number of these.\n",
		"  -placeholders [bool]\tif set, all packages not found in the template will be left in as empty placeholders\n";
		"  -name [text]\tthe name in <systemModel> to use for the generated root sysdef. If not present, this will use the name from the templat\n";
	exit(1);
	}

GetOptions
	(
	 'path=s' => \$path,
	 'name=s' => \$sysmodelname,
	'output=s' => \$output,
	'w=s' => \$warning,
	'root=s' => \@searchroots,
	'glob=s' => \@searchpaths,
	'placeholders=s' => \$placeholders
	);


 if($path eq '') {$path = '/os/deviceplatformrelease/foundation_system/system_model/system_definition.xml'}

if(!($warning =~/^(Note|Warning|Error)$/)) {$warning="Error"}

# path is the system model path of the processed sysdef file. This is only used when creating a stand-alone sysdef as the output
# output specifies the file this is saved in. If specified, all (relative) paths will be modified to be relative to it. If not, all paths will be absolute
# w is the warning level: Note, Warning or Error.
# root = -root g:\sf
# glob = -glob "\*\*\package_definition.xml"

#Example command lines:
#rootsysdef.pl -root F:\sftest\mcl\sf  -glob "\*\*\package_definition.xml"  -output  F:\sftest\mcl\build\system_definition.sf.xml   F:\sftest\mcl\sf\os\deviceplatformrelease\foundation_system\system_model\system_definition.xml
#rootsysdef.pl -root F:\sftest\mcl\sf  -glob "\*\*\*\*\package_definition.xml"  -output  F:\sftest\mcl\build\system_definition.mine.xml   F:\sftest\mcl\sf\os\deviceplatformrelease\foundation_system\system_model\system_definition.xml
if(!scalar @ARGV && !scalar @searchpaths) {&help()};


my %replacefile;
my $dir;
foreach(@searchpaths)
	{
	my $ndir = shift(@searchroots);
	if($ndir ne '') {$dir=$ndir}
	foreach my $file (glob "$dir$_")
		{
		my $map =substr($file,length($dir));
		$map=~tr/\\/\//;
		$additional{$map}=$file;
		$replacefile{&abspath($file)}=$map;
		$add{&abspath($file)}=1;
		}
	}

my $parser = new XML::DOM::Parser;
my $sysdef;
my %rootmap;
my  $sysdefdoc;
if(scalar @ARGV)
	{
	$sysdef = &abspath(shift);	# resolve the location of the root sysdef

	# rootmap is a mapping from the filesystem to the paths in the doc
	%rootmap = &rootMap($path,$sysdef);	

	$sysdefdoc = $parser->parsefile ($sysdef);
	}
else 
	{
	$sysdefdoc = $parser->parse('<SystemDefinition schema="3.0.1"><systemModel name="System Model"/></SystemDefinition>');
	}

my %nsmap;
my %urimap;

my $mapmeta;
my $modpath;
if($output eq '')
	{ #figure out mapping path
	my @fspath = split(/[\\\/]/,$sysdef);
	my @smpath = split(/[\\\/]/,$path);
	while(lc($smpath[$#smpath]) eq lc($fspath[$#fspath] )) {
		pop(@smpath);
		pop(@fspath);
	}
	my $mappath = join('/',@fspath);
	my $topath = join('/',@smpath);
	$mappath=~s,^/?,file:///,;
	$mapmeta = $sysdefdoc->createElement('meta');
	$mapmeta->setAttribute('rel','link-mapping');
	my $node = $sysdefdoc->createElement('map-prefix');
	$node->setAttribute('link',$mappath);
	$topath ne '' && $node->setAttribute('to',$topath);
	$mapmeta->appendChild($node);
	}
else
	{
	$modpath = &relativeTo(&abspath($output), $sysdef);
	}


# find all the namespaces used in all the fragments and use that 
# to set the namespaces in the root element of the created doc
#   should be able to optimise by only parsing each doc once and 
#	maybe skipping the contends of <meta>
my @nslist = &namespaces($sysdef,$sysdefdoc->getDocumentElement());

my %replacing;
my %newContainer;
my %foundDescendants;

foreach(keys %add)
	{
	my   $fragment = $parser->parsefile ($_);
	my $fdoc = $fragment->getDocumentElement();
	my $topmost =&firstElement($fdoc);
	if(!$topmost) {
		print STDERR "$warning: $_ has no content. Skipping\n";
		next;
	}
	my $type = $topmost->getTagName;
	my $id = $topmost->getAttribute('id');
	my ($localid,$ns) = &idns($topmost,$id);	
	my @path = &guessIdInPath($localid,$_);
	if($type eq 'layer') {@path=@path[0]}
	elsif($type eq 'package')  {@path=@path[0..1]}
	elsif($type eq 'collection')  {@path=@path[0..2]}
	elsif($type eq 'component')  {@path=@path[0..3]}
	@path = reverse(@path);
	$add{$_}=join('/',@path)." $localid $ns";
	$replacing{$type}->{"$localid $ns"} = $_;
	# keys with a space are namespaced and fully identified, and contain the filename as the content.
	# keys with no space have unknown namespace and contain a hash of the content
	$newContainer{join('/',@path[0..$#path-1])}->{"$localid $ns"} = $_;
	for(my $i=-1;$i<$#path-1;$i++)
		{
		$foundDescendants{$path[$i+1]}=1;
		$newContainer{join('/',@path[0..$i])}->{$path[$i+1]}=1;
		}
	}


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
			$i eq 1000 && die "ERROR: cannot create namespace prefix for $uri";
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
while(my($pre,$uri) = each(%nsmap))
	{
	$pre ne '' || next ;
	$docroot->setAttribute("xmlns:$pre",$uri);
	}

&walk($sysdef,$docroot);

if($output eq '') 
	{
	print $sysdefdoc->toString;
	}
else
	{
	$sysdefdoc->printToFile($output);
	}

 
sub abspath
	{
	# normalize the path into an absolute one
	my  ($name,$path) = fileparse($_[0]);
	if($path eq '' && $name eq '') {return};
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


 
sub normpath
	{
	# normalize the path 
	my @norm;
	foreach my $dir(split(/[\\\/]/,shift)) {
		if($dir eq '.') {next}
		if($dir eq '..')
			{
			if($#norm == -1 || $norm[$#norm] eq '..')
				{ # keep  as is
				push(@norm,$dir);
				}
			elsif($#norm == 0 && $norm[0] eq '')
				{  # path begins with /, interpret /.. as just / -- ie toss out
				next
				}
			else
				{
				pop(@norm);
				}
			}
		else
			{
			push(@norm,$dir);
			}
	}

	return join('/',@norm)
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

sub replacedBy
	{ # can only check once. Destroys data
	my $node = shift;
	my $fullid= join(' ',&idns($node));
	my $type =  $node->getTagName;
	my $repl = $replacing{$type}->{$fullid};
	delete $replacing{$type}->{$fullid};
	return $repl;
	}

sub walk
	{
	#' walk through the doc, resolving all links
	my $file = shift;
	my $node = shift;
	my $type = $node->getNodeType;
	if($type!=1) {return}
	my $tag = $node->getTagName;
	if($tag=~/^(layer|package|collection|component)$/ )
		{
		if($file eq $sysdef)
			{
			&fixIDs($node);	# normalise all IDs in the root doc.
			}
		my $override = &replacedBy($node);
		my $link= $node->getAttribute('href');
		if($override eq '' )
			{
			my ($id,$ns)=&idns($node);
			if($foundDescendants{$id})
				{ # keep this node, it'll be populated by what we found
				if($link)
					{
					$node->removeAttribute('href');
					}
				}
			elsif($link || !$placeholders)
				{ # not going to be used, remove
				$node->getParentNode->removeChild($node) ; # not present, remove
				return;
				}
			}
		else
			{	
			my $href = $node->getAttribute('href');	
			my $ppath =  join('/',&parentPath($node->getParentNode));
			delete $newContainer{$ppath}->{join(' ',&idns($node))};		# remove this from list of things which need to be added
			if(&resolvePath($file,$href) ne $override)
				{ # file has changed, update
				print STDERR "$warning: Replacing $tag ",$node->getAttribute('id')," with $override\n";
				&setHref($node,$override);
				return;
				}
			}
		my @curpath = &parentPath($node);
		my $curitem = $curpath[$#curpath];
		my $curp = join('/',@curpath[0..$#curpath-1]);
		delete $newContainer{$curp}->{$curitem};

		if($link)
			{
			foreach my $child (@{$node->getChildNodes}) {$node->removeChild($child)} # can't have children
			&fixHref($node,$file);
			return;
			}
		}
	elsif($tag eq 'systemModel' && $mapmeta)
		{ # need absolute paths for all links
		$node->insertBefore ($mapmeta,$node->getFirstChild);
		$sysmodelname eq '' || $node->setAttribute('name',$sysmodelname);
		}
	elsif($tag=~/^(SystemDefinition|systemModel)$/ )
		{
		($sysmodelname ne '' && $tag eq 'systemModel') && $node->setAttribute('name',$sysmodelname);
		}
	elsif($tag eq 'unit')
		{
		foreach my $atr ('bldFile','mrp','base','proFile')
			{
			my $link= $node->getAttribute($atr);
			if($link && !($link=~/^\//))
				{
				if($mapmeta)
					{ # use absolute paths
					$link= &abspath(File::Basename::dirname($file)."/$link");
					foreach my $a (keys %rootmap)
						{
						$link=~s,^$a,$rootmap{$a},ie;
						}
					}
				else
					{ # modified relative path 
					$link = &normpath($modpath.$link);
					}
				$node->setAttribute($atr,$link);
				}
			}
		}
	elsif($tag eq 'meta')
		{
		&fixHref($node,$file);
		foreach my $child (@{$node->getChildNodes}) {$node->removeChild($child)} # can't have children
		&processMeta($node);
		next;
		}
	else {return}
	foreach my $item (@{$node->getChildNodes})
		{
		#print $item->getNodeType,"\n";
		&walk($file,$item);
		}
	if($tag=~/^(systemModel|layer|package|collection|component)$/ )
		{ # check for appending
		my $ppath =  join('/',&parentPath($node));
		if($newContainer{$ppath}) {
			foreach my $item (sort keys %{$newContainer{$ppath}})
				{
				&appendNewItem($node,$item,$newContainer{$ppath}->{$item});
				}
			}
		}
	}


sub getNs
	{
	# find the ns URI that applies to the specified prefix.
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

sub idns
	{ # return the namespace of an ID
	my $node = shift;
	my $id = shift;
	if($id eq '' ) {$id = $node->getAttribute('id'); }
	if($id=~s/^(.*)://)
		{ # it's got a ns, find out what it is
		my $pre = $1;
		return ($id,&getNs($node,$pre));
		}
		return ($id,$node->getOwnerDocument->getDocumentElement->getAttribute("id-namespace") ||	$defaultns);
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

sub  processMeta
	{
	my $metanode = shift;
	# do nothing. Not supported yet
	}

sub guessIdInPath
	{
	my $id = shift;
	my @path = reverse(split(/\//,$_[0]));
	while(@path)
		{
		my $dir = shift(@path);
		if($dir eq $id)
			{
			return ($id,@path);
			}
		}
	print STDERR "$warning: Non-standard ID $id in $_[0]\n";
	@path = reverse(split(/\//,$_[0]));
	if($path[0] eq 'package_definition.xml')
		{
		return @path[1..$#path];
		}
	}


sub parentPath
	{
	my $node=shift;
	my @path;
	while($node)
		{
		if(!$node) {return @path}
		my $id=$node->getAttribute('id');
		if($id eq '') {return @path}
		$id=~s/^.*://;
		@path = ($id,@path);
		$node = $node->getParentNode();
		}
	return @path;
	}

sub childTag
	{
	my $tag = shift;
	if($tag eq 'systemModel') {return 'layer'}
	if($tag eq 'layer') {return 'package'}
	if($tag eq 'package') {return 'collection'}
	if($tag eq 'collection') {return 'component'}
	die "ERROR: no child for $tag";
	}

sub appendNewItem
	{
	my $node = shift;
	my $doc = $node->getOwnerDocument;
	my $id = shift;
	if($id eq '') {return}
	my $fullid=$id;
	my $contents = shift;
	my $tag = &childTag($node->getTagName());
	my $new = $doc->createElement($tag);
	if($id=~/^(.*) (.*)/)
		{
		$id=$1;
		$ns = getNamespacePrefix($node,$2);
		if($ns ne '') {$id="$ns:$id"}
		}
	else
		{
		$contents = '';
		}
	$new->setAttribute('id',$id);		# default namespace
	$node->appendChild($new);
	my $ppath =  join('/',&parentPath($new));
	if($contents eq '')
		{ # look for additions
		print STDERR "$warning: Adding new $tag: $id\n";
		if($newContainer{$ppath}) {
			foreach my $item (sort keys %{$newContainer{$ppath}})
				{
				&appendNewItem($new,$item,$newContainer{$ppath}->{$item});
				}
			}
		}
	else
		{ # this one item is defined in the specified file
		if($tag eq 'package') 
			{ #include some package data in root
			my $fragment = $parser->parsefile ($contents);
			my $fdoc = $fragment->getDocumentElement();
			my $topmost =&firstElement($fdoc);
			my %at = &atts($topmost);
			foreach my $arg ('tech-domain','level','span')
				{
				if($at{$arg}) {	$new->setAttribute($arg,$at{$arg})}
				}
			if($at{'tech-domain'}) {&positionByTechDomain($new)}
			}
		&setHref($new,$contents);
		print STDERR "$warning: Adding found $tag $id from $contents\n";
		delete $replacing{$tag}->{$fullid};
		}
	# newline after each new tag so output's not ugly
	if($new->getNextSibling)
		{
		$node->insertBefore($doc->createTextNode ("\n"),$new->getNextSibling);
		}
	else
		{
		$node->appendChild($doc->createTextNode ("\n"));
		}
	delete $newContainer{$ppath};
	}


sub getNamespacePrefix
	{
	my $node = shift;
	my $ns = shift;
	my $root = $node->getOwnerDocument->getDocumentElement;
	my $idns = $root->getAttribute("id-namespace");
	if($idns && $idns eq $ns) {return}
	if(!$idns && $defaultns eq $ns) {return}
	foreach my $a (keys %{$root->getAttributes}) 
		{
		my $pre = $a;
		if($pre=~s/^xmlns://)
			{
			if($root->getAttribute ($a) eq $ns)  {return $pre}
			}
		}
	die "ERROR: no namespace prefix defined for $ns";
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


sub fixHref {
	my $node = shift;
	my $base = shift;
	my $link= $node->getAttribute('href');
	if($link=~/^(ftp|http)s:\/\//) {return} # remote link, do nothing
	my $path = &resolvePath($base,$link);
	if(!-e $path) 
		{ # no such file, delete
		my $tag  =$node->getTagName;
		my $id = $node->getAttribute('id');
		print STDERR "$warning: $tag $id not found at $link\n";	
		$node->getParentNode->removeChild($node);
		return;
		}
	foreach my $child (@{$node->getChildNodes}) {$node->removeChild($child)} # can't have children
	if($output eq '')
		{
		$path=~s,^/?,file:///,;
		$node->setAttribute('href',$path);	# replace with absolute URI
		return;
		}
	$node->setAttribute('href',&normpath($modpath.$link));	# make relative path to output file
	}


sub setHref {
	my $node = shift;
	my $file = shift;
	if($output eq '') 
		{
		$path = &abspath($file);
		$path=~s,^/?,file:///,;
		$node->setAttribute('href',$path);	# replace with absolute URI
		}
	else 
		{
		$node->setAttribute('href',&relativeTo(&abspath($output),$file,'file'));
		}
	while(my $child =  $node->getFirstChild ) {$node->removeChild($child)}
}


sub relativeTo {
	if($_[0] eq '') {return &abspath($_[1])}
	my @outfile = split(/[\\\/]/,lc(shift));
	my @infile  = split(/[\\\/]/,lc(shift));
	my $asdir = shift ne 'file';
	while($outfile[0] eq $infile[0])
		{
		shift(@outfile);
		shift(@infile);
		}
	$modpath = '../' x (scalar(@outfile) - 1);
	if($asdir) {
		if(scalar @infile > 1)  {$modpath .=  join('/',@infile[0..$#infile - 1]).'/'}
	} else   {$modpath .=  join('/',@infile)}
	return $modpath;
}

sub positionByTechDomain 
	{
	my $node=shift;
	my $td = $node->getAttribute('tech-domain');
	my %before;
	foreach my $t (@tdOrder)
		{
		$before{$t}=1;
		if($t eq $td) {last}
		}
	my $prev = $node->getPreviousSibling;
	foreach my $child (reverse @{$node->getParentNode->getChildNodes})
		{
		if($child->getNodeType==1 && $child->getTagName eq 'package' && $child!=$node)
			{
			if($before{$child->getAttribute('tech-domain')})
				{
				my $next = $child->getNextSibling;
				while($next &&  $next->getNodeType!=1) {$next = $next->getNextSibling}
				if($next) {
					$node->getParentNode->insertBefore ($node,$next);
				}
				last;
				}
			}
		}
	}
