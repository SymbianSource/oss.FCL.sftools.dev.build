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
#--------------------------------------------------------------------------------------------------
# Name    : XMLManip.pm
# Use     : Parse and write XML files.

#
# Synergy :
# Perl %name    : % (%full_filespec :  %)
# %derived_by   : %
# %date_created : %
#
# History :
#  v1.6.3 (10/07/2006)
#   - Fixed where closing tags were not correctly aligned with the opening tag.
#
#  v1.6.2 (21/06/2006)
#   - Modified 'ChildRegex' subroutine to allow specification of the child to return. Still returns an
#     array if no index is specified. This is so 'Child' and 'ChildRegex' have the same functionning.
#   - Fixed '__String2XML' where specifying an index equal to 0 returned an empty string.
#
#  v1.6.1 (29/03/2006)
#   - Fix issue with \n! (Finally...)
#
#  v1.6.0 (15/03/2006)
#   - Added subroutine to check for attribute existance to the XMLManip::Node package.
#
#  v1.5.3 (08/02/2006)
#   - Modified 'XMLManip::Node' constructor to be copy constructor if 'XMLManip::Node' instance is
#     passed as argument.
#   - Fixed subroutine 'Child' of XMLManip::Node package where specifying an index equal to
#     0 returned all childs.
#
#  v1.5.2 (01/02/2006)
#   - Modified 'Child' subroutine to allow specification of the child to return. Still returns an
#     array if no index is specified.
#   - Removed 'Exporter' code since it was useless.
#
#  v1.5.1 (26/01/2006)
#   - Removed chomping of content in '__UpdateContents' subroutine.
#   - Added CDATA wrappers around content.
#
#  v1.5.0 (24/01/2006)
#   - Modified 'Child' subroutine of the XMLManip::Node package to check complete equality
#     between passed type and child node type.
#   - Added 'ChildRegex' subroutine of the XMLManip::Node package to select child nodes according
#     to their type based on a regular expression.
#
#  v1.4.0 (06/01/2006)
#   - Added 'NbChilds' and 'NbChild' subroutines to the XMLManip::Node package.
#   - Added two locking constants 'LOCK' and 'NO_LOCK' to packages 'XMLManip' and 'XMLManip::Node'
#   - Minor modifications to improve code.
#
#  v1.3.0 (04/01/2006)
#   - Added 'RemoveNode' subroutine to the XMLManip::Node package.
#   - Added '==' overload to XMLManip::Node package.
#   - Added '__UpdateContents' to remove XML formatting spaces at start of each content line.
#
#  v1.2.0 (21/12/2005)
#   - Updated XMLManip::Node subroutines 'PushChild' and 'Attribute' to check if node is locked.
#   - Added 'LockAll' and 'UnlockAll' to the XMLManip::Node package.
#   - Updated 'ParseXMLFile' to take an optional extra argument corresponding to the lock state
#     of returned node tree.
#
#  v1.1.0 (19/12/2005)
#   - Added 'ChildTypes' subroutine to the XMLManip::Node package.
#   - ParseXMLFile now locks all nodes in the returned data structure.
#
#  v1.0.0 (08/12/2005)
#   - First version of the module.
#--------------------------------------------------------------------------------------------------

package XMLManip;

use strict;
use warnings;
use XML::Parser;
use HTML::Entities;
use ISIS::Assertion _DEBUG => 1;

use constant ISIS_VERSION     => '1.6.3';
use constant ISIS_LAST_UPDATE => '10/07/2006';

use constant LOCK             => 1;
use constant NO_LOCK          => 0;

my %ModuleData;

#--------------------------------------------------------------------------------------------------
#
#   XMLManip::ParseXMLFile
#
#--------------------------------------------------------------------------------------------------
sub ParseXMLFile
{
  my ($file, $lock) = (shift, shift || NO_LOCK);
  my $parser = new XML::Parser(Style => 'Subs',
                               Pkg => 'SubHandlers',
                               Handlers => { Char => \&__Content },
                               ErrorContext => 2);
  
  $ModuleData{rootNode}    = new XMLManip::Node('root');
  $ModuleData{currentNode} = $ModuleData{rootNode};
  $ModuleData{lock}        = $lock;

  eval { $parser->parsefile($file); };
  
  if($@)
  {
    warn "XML Parsing Error : $@\nTree might not be complete\n";
  }
  
  __UpdateContents($ModuleData{currentNode}, '');
  $ModuleData{currentNode}->LockAll() if($ModuleData{lock} == LOCK);
  return $ModuleData{rootNode}->Childs()->[0];
}


sub ParseXMLFileHandle
{
  my ($file, $lock) = (shift, shift || NO_LOCK);
  my $parser = new XML::Parser(Style => 'Subs',
                               Pkg => 'SubHandlers',
                               Handlers => { Char => \&__Content },
                               ErrorContext => 2);
  
  $ModuleData{rootNode}    = new XMLManip::Node('root');
  $ModuleData{currentNode} = $ModuleData{rootNode};
  $ModuleData{lock}        = $lock;

  eval { $parser->parse($file); };
  
  if($@)
  {
    warn "XML Parsing Error : $@\nTree might not be complete\n";
  }
  
  __UpdateContents($ModuleData{currentNode}, '');
  $ModuleData{currentNode}->LockAll() if($ModuleData{lock} == LOCK);
  return $ModuleData{rootNode}->Childs()->[0];
}

sub __Content
{
	my ($self, $string) = (shift, shift);  
	$ModuleData{currentNode}{'XMLManip::Node::Content'} .= $string;
}

sub __UpdateContents
{
  my ($node, $indent) = (shift, shift);
  
  if(defined $node->Content())
  {
    my $content = $node->Content();
    $content =~ s/^$indent//gm;
    $node->Content($content);
  }
  
  foreach my $child (@{$node->Childs()}){ __UpdateContents($child, $indent.'  '); }
}

#--------------------------------------------------------------------------------------------------
#
#   XMLManip::WriteXMLFile
#
#--------------------------------------------------------------------------------------------------
sub WriteXMLFile
{
  my ($rootNode, $filename, $dst) = (shift, shift, undef);
  
  open($dst, '>'.$filename) or die "Unable to create file \'$filename\' : $!\n";
  print $dst "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n";
  WriteToOStream($dst, $rootNode);
  close($dst);
}

sub WriteToOStream
{
	my ($dst, $rootNode) = (shift, shift);
	
	$ModuleData{dst}    = $dst;
  $ModuleData{indent} = '';

  __WriteNode($rootNode);
}

sub __WriteNode
{
  my ($node, $dst, $indent, $closed) = (shift, $ModuleData{dst}, $ModuleData{indent}, 0);
  
  if(defined $node->Comment() and my @lines = map{ __String2XML($_)."\n" } split("\n", $node->Comment()))
  {
  	$lines[$#lines] =~ s/\n$//;
  	print $dst $indent, "<!-- ";
  	if(scalar @lines > 1)
  	{
  		@lines = map { $indent.'  '.$_ } @lines;
  		print $dst "\n", @lines, "\n", $indent;
  	}
  	else
  	{
  		print $dst @lines;
  	}
  	print $dst " -->\n";
 	}
  
  print $dst $indent, '<'.$node->Type();

  foreach (sort keys %{$node->Attributes()})
  {
    print $dst ' ', $_, "=\"", __String2XML($node->Attribute($_)), "\"";
  }
  
  if( defined $node->Content() )  
  {
  	my @lines =  __String2XML($node->Content());
  	unless( $closed )
  	{
  		print $dst ">" ;
  		$closed = 1;
  	}
  	
  	if(scalar @lines > 1)
  	{
  		@lines = map { $indent.'  '.$_ } @lines;
  		print $dst @lines, "\n", $indent;
  	}
  	else
  	{
  		print $dst @lines;
  	}  	
  }
  
  if(scalar @{$node->Childs()})
  {
  	unless( $closed )
  	{
  		print $dst ">\n" ;
  		$closed = 1;
  	}
    foreach (@{$node->Childs()})
    {
      $ModuleData{indent} = $indent.'  ';
      __WriteNode($_);
      $ModuleData{indent} = $indent;
    }
  }
 	if ($closed)
 	{
 		print $dst $indent, '</', $node->Type(), ">\n" ;
  }
  else
  {
  	print $dst " />\n";
  }
}

sub __String2XML
{
  my $str = shift;
  return '' unless(defined $str);
  $str =~ s/\e/e/g;
  $str = HTML::Entities::encode_entities($str);
  # Part1
	$str =~ s/&nbsp;/\&\#160;/g;
	$str =~ s/&iexcl;/\&\#161;/g;
	$str =~ s/&curren;/\&\#164;/g;
	$str =~ s/&cent;/\&\#162;/g;
	$str =~ s/&pound;/\&\#163;/g;
	$str =~ s/&yen;/\&\#165;/g;
	$str =~ s/&brvbar;/\&\#166;/g;
	$str =~ s/&sect;/\&\#167;/g;
	$str =~ s/&uml;/\&\#168;/g;
	$str =~ s/&copy;/\&\#169;/g;
	$str =~ s/&ordf;/\&\#170;/g;
	$str =~ s/&laquo;/\&\#171;/g;
	$str =~ s/&not;/\&\#172;/g;
	$str =~ s/&shy;/\&\#173;/g;
	$str =~ s/&reg;/\&\#174;/g;
	$str =~ s/&trade;/\&\#8482;/g;
	$str =~ s/&macr;/\&\#175;/g;
	$str =~ s/&deg;/\&\#176;/g;
	$str =~ s/&plusmn;/\&\#177;/g;
	$str =~ s/&sup2;/\&\#178;/g;
	$str =~ s/&sup3;/\&\#179;/g;
	$str =~ s/&acute;/\&\#180;/g;
	$str =~ s/&micro;/\&\#181;/g;
	$str =~ s/&para;/\&\#182;/g;
	$str =~ s/&middot;/\&\#183;/g;
	$str =~ s/&cedil;/\&\#184;/g;
	$str =~ s/&sup1;/\&\#185;/g;
	$str =~ s/&ordm;/\&\#186;/g;
	$str =~ s/&raquo;/\&\#187;/g;
	$str =~ s/&frac14;/\&\#188;/g;
	$str =~ s/&frac12;/\&\#189;/g;
	$str =~ s/&frac34;/\&\#190;/g;
	$str =~ s/&iquest;/\&\#191;/g;
	$str =~ s/&times;/\&\#215;/g;
	$str =~ s/&divide;/\&\#247;/g;
  # Part 2
	$str =~ s/&Agrave;/\&\#192;/g;
	$str =~ s/&Aacute;/\&\#193;/g;
	$str =~ s/&Acirc;/\&\#194;/g;
	$str =~ s/&Atilde;/\&\#195;/g;
	$str =~ s/&Auml;/\&\#196;/g;
	$str =~ s/&Aring;/\&\#197;/g;
	$str =~ s/&AElig;/\&\#198;/g;
	$str =~ s/&Ccedil;/\&\#199;/g;
	$str =~ s/&Egrave;/\&\#200;/g;
	$str =~ s/&Eacute;/\&\#201;/g;
	$str =~ s/&Ecirc;/\&\#202;/g;
	$str =~ s/&Euml;/\&\#203;/g;
	$str =~ s/&Igrave;/\&\#204;/g;
	$str =~ s/&Iacute;/\&\#205;/g;
	$str =~ s/&Icirc;/\&\#206;/g;
	$str =~ s/&Iuml;/\&\#207;/g;
	$str =~ s/&ETH;/\&\#208;/g;
	$str =~ s/&Ntilde;/\&\#209;/g;
	$str =~ s/&Ograve;/\&\#210;/g;
	$str =~ s/&Oacute;/\&\#211;/g;
	$str =~ s/&Ocirc;/\&\#212;/g;
	$str =~ s/&Otilde;/\&\#213;/g;
	$str =~ s/&Ouml;/\&\#214;/g;
	$str =~ s/&Oslash;/\&\#216;/g;
	$str =~ s/&Ugrave;/\&\#217;/g;
	$str =~ s/&Uacute;/\&\#218;/g;
	$str =~ s/&Ucirc;/\&\#219;/g;
	$str =~ s/&Uuml;/\&\#220;/g;
	$str =~ s/&Yacute;/\&\#221;/g;
	$str =~ s/&THORN;/\&\#222;/g;
	$str =~ s/&szlig;/\&\#223;/g;
	$str =~ s/&agrave;/\&\#224;/g;
	$str =~ s/&aacute;/\&\#225;/g;
	$str =~ s/&acirc;/\&\#226;/g;
	$str =~ s/&atilde;/\&\#227;/g;
	$str =~ s/&auml;/\&\#228;/g;
	$str =~ s/&aring;/\&\#229;/g;
	$str =~ s/&aelig;/\&\#230;/g;
	$str =~ s/&ccedil;/\&\#231;/g;
	$str =~ s/&egrave;/\&\#232;/g;
	$str =~ s/&eacute;/\&\#233;/g;
	$str =~ s/&ecirc;/\&\#234;/g;
	$str =~ s/&euml;/\&\#235;/g;
	$str =~ s/&igrave;/\&\#236;/g;
	$str =~ s/&iacute;/\&\#237;/g;
	$str =~ s/&icirc;/\&\#238;/g;
	$str =~ s/&iuml;/\&\#239;/g;
	$str =~ s/&eth;/\&\#240;/g;
	$str =~ s/&ntilde;/\&\#241;/g;
	$str =~ s/&ograve;/\&\#242;/g;
	$str =~ s/&oacute;/\&\#243;/g;
	$str =~ s/&ocirc;/\&\#244;/g;
	$str =~ s/&otilde;/\&\#245;/g;
	$str =~ s/&ouml;/\&\#246;/g;
	$str =~ s/&oslash;/\&\#248;/g;
	$str =~ s/&ugrave;/\&\#249;/g;
	$str =~ s/&uacute;/\&\#250;/g;
	$str =~ s/&ucirc;/\&\#251;/g;
	$str =~ s/&uuml;/\&\#252;/g;
	$str =~ s/&yacute;/\&\#253;/g;
	$str =~ s/&thorn;/\&\#254;/g;
	$str =~ s/&yuml;/\&\#255;/g;

  return $str;
}

#--------------------------------------------------------------------------------------------------
#
#   XMLManip::PrintToShell
#
#--------------------------------------------------------------------------------------------------
sub PrintToShell
{
  my ($node, $indent) = (shift, shift || '');
  
  __ASSERT($node);
  
  print $indent, $node, "\n";
  
  foreach my $child(@{$node->Childs()})
  { PrintToShell($child, $indent.'  '); } 
}

1;

#--------------------------------------------------------------------------------------------------
#
#   SubHandlers package for ParseXMLFile.
#
#--------------------------------------------------------------------------------------------------
package SubHandlers;

sub AUTOLOAD
{
  my ($method, $xpat, $elmt, %attr) = (our $AUTOLOAD, shift, shift, @_);

  if($method !~ /^.*_$/)
  { # opening tag.
    my $node = new XMLManip::Node($elmt, \%attr);
    
    if(exists $ModuleData{currentNode})
    {
      $ModuleData{currentNode}->PushChild($node);
      push @{$ModuleData{parentNodes}}, $ModuleData{currentNode};
    }

    $ModuleData{currentNode} = $node;
  }
  else
  { # closing tag
    $ModuleData{currentNode} = pop @{$ModuleData{parentNodes}};
  }
}

1;

#--------------------------------------------------------------------------------------------------
#
#   XML Node
#
#--------------------------------------------------------------------------------------------------

package XMLManip::Node;

use strict;
use warnings;

use constant LOCK    => XMLManip::LOCK;
use constant NO_LOCK => XMLManip::NO_LOCK;

#--------------------------------------------------------------------------------------------------
# Overloaded methods.
#--------------------------------------------------------------------------------------------------
use overload q("")  => \&__AsString,
             q(0+)  => \&__AsNumber,
             q(==)  => \&__AreEqual;

sub __AsString
{
  my ($self) = (shift);
  $self->{'XMLManip::Node::Type'}.'('.
    scalar (keys %{$self->{'XMLManip::Node::Attributes'}}).','.
    scalar (@{$self->{'XMLManip::Node::Childs'}}).')';
}

sub __AsNumber
{
  my ($self, $nb) = (shift, 1);
  foreach my $child (@{$self->{'XMLManip::Node::Childs'}})
  {
    $nb += $child->__AsNumber();
  }
  
  return $nb;
}

sub __AreEqual
{
  my ($lhs, $rhs) = (shift, shift);
  return 1 if(overload::StrVal($lhs) eq overload::StrVal($rhs));
  return 0;
}

#--------------------------------------------------------------------------------------------------
# Constructor.
#--------------------------------------------------------------------------------------------------
sub new
{
  my ($class, $arg, $attrs) = (shift, shift || 'node', shift || {});
	
	if(ref $arg eq 'XMLManip::Node')
	{
	  my @childs;
	  
	  if(exists $$attrs{childs})
	  {
  	  if($$attrs{childs} == 'copy')
  	  {
  	    foreach my $child (@{$arg->Childs()})
  	    { push @childs, new XMLManip::Node($child, { childs => 'copy' }); } 
  	  }
  	  elsif($$attrs{childs} == 'refs')
  	  {
  	    push @childs, @{$arg->Childs()};
  	  }
  	}
	  
  	return bless { 'XMLManip::Node::Type'       => $arg->Type(),
                   'XMLManip::Node::Attributes' => $arg->Attributes(),
                   'XMLManip::Node::Content'    => $arg->Content(),
                   'XMLManip::Node::Comment'    => $arg->Comment(),
                   'XMLManip::Node::Childs'     => \@childs,
                   _lock                        => $arg->{_lock},
                 }, $class;
	}

  bless { 'XMLManip::Node::Type'       => $arg,
          'XMLManip::Node::Attributes' => $attrs,
          'XMLManip::Node::Content'    => undef,
          'XMLManip::Node::Comment'    => undef,
          'XMLManip::Node::Childs'     => [],
          _lock                        => 0,
        }, $class;
}

#--------------------------------------------------------------------------------------------------
# Other methods.
#--------------------------------------------------------------------------------------------------
sub PushChild
{
  my ($self, $node) = (shift, shift);
  
  if(ref $node eq 'XMLManip::Node')
  {
    if($self->{_lock}) { warn "trying to push child node \'$node\' while node is locked.\n"; }
    else               { push @{$self->{'XMLManip::Node::Childs'}}, $node; }
  }
  else { warn "trying to push non 'XMLManip::Node' element (type is \'", ref $node || 'undefined', "\').\n"; }
}

sub RemoveChild
{
  my ($self, $node, $i) = (shift, shift, 0);
  
  if($self->{_lock})
  {
    warn "trying to remove child while node is locked.\n";
  }
  elsif(ref $node eq 'XMLManip::Node')
  {
    foreach my $child (@{$self->{'XMLManip::Node::Childs'}})
    {
      if($child == $node) { splice @{$self->{'XMLManip::Node::Childs'}}, $i, 1; }
      else { ++$i; }
    }
  }
  else
  {
    foreach my $child (@{$self->Child($node)})
    {
      RemoveChild($child);
    }
  }
}

sub Attribute
{
  my ($self, $attr) = (shift, shift);

  if(@_)
  {
    if($self->{_lock}) { warn "trying to modify value of attribute \'$attr\' while node is locked.\n"; }
    else               { $self->{'XMLManip::Node::Attributes'}{$attr} = shift; }
  }

  return $self->{'XMLManip::Node::Attributes'}{$attr};
}

sub HasAttribute
{
	my ($self, $attr) = (shift, shift);
	
	return exists $self->{'XMLManip::Node::Attributes'}{$attr};
}

sub ChildRegex
{
  my ($self, $type, $idx, @result) = (shift, shift || '.*', shift);

  @result = grep{ $_->{'XMLManip::Node::Type'} =~ /$type/ } @{$self->{'XMLManip::Node::Childs'}};

  return \@result unless(defined $idx);
  return $result[$idx];
}

sub Child
{
  my ($self, $type, $idx, @result) = (shift, shift || '.*', shift);

  @result = grep{ $_->{'XMLManip::Node::Type'} eq $type } @{$self->{'XMLManip::Node::Childs'}};
  
  return \@result unless(defined $idx);
  return $result[$idx];
}

sub ChildAt
{
	my ($self, $idx) = (shift, shift);
	__ASSERT($idx >= 0 && $idx <= $#{$self->{'XMLManip::Node::Childs'}});
  return ${$self->{'XMLManip::Node::Childs'}}[$idx];
}

sub ChildTypes
{
	my ($self) = (shift);
	
	my %types;
	foreach my $child (@{$self->{'XMLManip::Node::Childs'}})
	{ $types{$child->Type()} = 1; }
	
	return sort keys %types;
}

sub NbChild
{
  my ($self, $type, $nb) = (shift, shift || '.*', 0);
  return scalar grep{ $_->{'XMLManip::Node::Type'} =~ /^$type$/ } @{$self->{'XMLManip::Node::Childs'}};
}

sub NbChilds
{
  my ($self) = (shift);
  return scalar @{$self->{'XMLManip::Node::Childs'}};
}

sub NbAttributes
{
  my ($self) = (shift);
  return scalar keys %{$self->{'XMLManip::Node::Attributes'}};
}

sub Lock     { $_[0]->{_lock} = LOCK; }
sub Unlock   { $_[0]->{_lock} = NO_LOCK; }
sub IsLocked { return $_[0]->{_lock}; }

sub LockAll
{
  my ($self) = (shift);
  
  $self->{_lock} = LOCK;
  foreach my $child (@{$self->{'XMLManip::Node::Childs'}})
  { $child->LockAll(); } 
}

sub UnlockAll
{
  my ($self) = (shift);
  
  $self->{_lock} = NO_LOCK;
  foreach my $child (@{$self->{'XMLManip::Node::Childs'}})
  { $child->UnlockAll(); }
}

sub AUTOLOAD
{
  my ($self, $method) = (shift, our $AUTOLOAD);
  return if($method =~ /::DESTROY$/ or not exists $self->{$method});
  
  if(@_)
  {
    if($self->{_lock}) { warn "trying to modify value of $method while node is locked.\n"; }
    else               { $self->{$method} = shift; }
  }

  return $self->{$method};
}

1;

__END__

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

ISIS::XMLManip - A perl module for generating data structures from XML files.

=head1 SYNOPSIS

	use ISIS::XMLManip;
	
	# Reading an XML.
	my $rootNode = &ParseXMLFile('myfile.xml');
	
	print "Node type : \'", $rootNode->Type(), "\'\n";
	
	print "Node attributes :\n";
	foreach (sort keys %{$rootNode->Attributes()})
	{
	 print "  $_ => ", $rootNode->Attribute($_), "\n";
	}
	
	if(defined $rootNode->Content())
	{
	 print "Node content :\n", $rootNode->Content(), "\n";
	}

	print "Node childs :\n";
	foreach (@{$rootNode->Childs()})
	{
	 print "  ", $_->Type(), "\n";
	}
 
 # Writing an XML.
 my $newNode = new XMLManip::Node('test', { time => scalar(localtime), type => 'new' });
 $newNode->Content("This is a test node added to the root");
 $newNode->Attribute('size', '23');
 
 $rootNode->PushChild($newNode);
 
 &WriteXMLFile($rootNode, 'output.xml');

=head1 DESCRIPTION

This module generates a data structure from an XML file just as XML::Simple does
but preserving child node order and differenciating attributes from childs. It
is built on top of L<XML::Parser> that uses James Clark's expat library.

The module exposes only two subroutine 'ParseXMLFile' who takes a file name as
argument and returns a reference to a Node (the root node of the XML document) and
'WriteXMLFile' that takes a 'Node' instance and a file name to write to.
The nodes are encapsulated in a 'Node' package with the following interface :

=head1 XMLManip::Node INTERFACE

=head2 XMLManip::Node( [TYPE, [ATTRS]] | [NODE] )

The constructor takes a type as a string and a reference to a hash table containing its
attributes or takes a node reference as parameters. As a copy constructor, it will
duplicate the node and, based on the second argument passed, will determine if it must
copy also the child nodes recursively, copy just the references to the child nodes, or
not copy any child information.

=head2 Type( ) :

Returns the tag of the node (ex : operation in '<operation>').

=head2 Content( ) :

Returns the node's content if available. Will return undef if the node did not
contain any char data.

=head2 Comment( ) :

Returns the node's comment if available. Will return undef if the node did not
contain any char data. Comment will be printed to the xml file just before the
node it corresponds to.

=head2 Attribute( NAME, [VALUE] ) :

Returns the value of the corresponding attribute, and sets the attribute's value
if a second argument is specified.

=head2 Attributes( ) :

Returns a reference to a hash table containing all the node's attributes. Each key
is an attribute name and will return the corresponding attribute value.

=head2 Child( [TYPE, [INDEX]] ) :

Returns an array containing all nodes who's type matches the regular expression
passed by argument. If no type is passed, the Child function has the same effect
as 'Childs'. If an index is specified, 'Child' will return the Nth child of that
type or undef if it does not exist.

=head2 Childs( ) :

Returns an array of 1 or more childs, or undef otherwise. The nodes in this array
appear in the same order of the xml file.

=head2 ChildTypes(  ) :

Returns an array containing the list of all existing child types for the node.

=head2 PushChild( <NODE> ) :

Adds a child node. The node must be of type 'XMLManip::Node' or a warning will be issued.

=head2 RemoveChild( <NODE|TYPE> ) :

Removes a child or a type of childs from the current node. If a node is passed, the
corresponding node will be removed. If a type is passed, all childs of that type will
be removed.

=head2 NbChild( [TYPE] ) :

Returns the number of childs with type TYPE. If no type is specified, 'NbChild' has the
same effet and return value as 'NbChilds'.

=head2 NbChilds(  ) :

Returns the number of child nodes for the given node.

=head2 NbAttributes(  ) :

Returns the number of attributes for the give node.

=head1 LOCKING SAFETY

The 'Node' package interface allows its user to fully modify a node's content. The
three following member functions of the 'Node' package allow to control node editing.
But default, a node is unlocked.

=head2 Lock( ) :

Lock the current node to prohibit modification of its data.

=head2 LockAll(  ) :

Locks the node it is called on and all its childs.

=head2 Unlock( ) :

Unlock the current node to allow modification of its data.

=head2 UnlockAll(  ) :

Unlocks the node it is called on and all its childs.

=head2 IsLocked( ) :

Return the current editing status of the node.

=head1 SCALAR AND NUMERICAL CONTEXT

A 'Node' instance will return the total number of child nodes plus one (self count) in
a scalar context. In a string context, the printout will follow the pattern :

'type(nb_attributes, nb_childs)'

=head1 NODE COMPARAISON

The 'Node' package has an overloaded '==' operator to allow comparaison at a memory level.
Two nodes are equal if they are at the same localtion in memory.

=head1 AUTHOR



=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
