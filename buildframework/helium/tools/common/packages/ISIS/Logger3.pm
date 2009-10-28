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
# Name   : Logger3.pm
# Use    : ISIS Logging module.

#
# Synergy :
# Perl %name    : % (%full_filespec :  %)
# %derived_by   : %
# %date_created : %
#
# History :
# v3.1.6 (23/05/2006)
#  - Updated footer message to always specify version of used logger3.
#  - Updated Header and Footer subroutines to avoid multiple <header> and <footer> nodes.
#  - Updated CloseXMLLog to create default header and footer if none specified.
#  - Moved creation of summary node in OpenXMLLog subroutine.
#
# v3.1.5 (06/04/2006)
#  - Reworte the way user defined CSS files are handled to make sure they are the last ones
#    included in the document body to allow overwriting of certain values.
#
# v3.1.4 (05/04/2006)
#  - Updated OUT2XML to store CSS and JS files in arrays and keep order.
#  - Updated XML2HTML to store CSS and JS files in arrays and keep order.
#
# v3.1.3 (28/03/2006)
#  - Implement custom outputer for header and footer,
#  - Implement PrintRawXHTML to write directly XHTML content (To be used carefully).
#  - Added AppendXmlNode
#
# v3.1.2 (20/03/2006)
#  - Updated Header and Footer subroutines to display titles in verbose mode.
#  - Minor changes to the script.
#
# v3.1.1 (17/03/2006)
#  - Updated the names of both OUT2XML and XML2HTML to be sub modules of Logger3.
#
# v3.1.0 (15/03/2006)
#  - Updated IconPrint subroutine to printout to shell its text if in verbose mode.
#  - Updated OpenEvent to allow makeup for node HTML look.
#  - Added PrintToShell subroutine to OUT2XML package with corresponding changes to XML2HTML.
#  - Added Separator subroutine to OUT2XML package with corresponding changes to XML2HTML.
#
# v3.0.0 (06/02/2006)
#  - Updated 'OUT2XML' and 'XML2HTML' to be instanciable packages and allow multiple logs at once.
#
# v2.2.0 (27/01/2006)
#  - Rewrote XML2HTML package :
#    - Corrected event printout.
#    - Added special message count.
#    - Added global special message count.
#    - Errors, Warnings, Remarks and Notes now have Ids.
#    - Any type of specific message is printed.
#
# v2.1.1 (13/01/2006)
#  - Updated Die subroutine to print line and file if specified.
#
# v2.1.0 (11/01/2006)
#  - Updated 'OUT2XML' package with following changes :
#    - General print messages handled by 'AUTOLOAD' now print all their arguments.
#      The same calls should be replaced by a extra call to 'Die'.
#    - 'PrintBold' is now depreciated and should be replaced by formatting tags.
#    - 'PrintItalic' is now depreciated and should be replaced by formatting tags.
#    - 'PrintUnderline' is now depreciated and should be replaced by formatting tags.
#    - 'OpenParagraph' and 'CloseParagraph' are now depreciated and should be removed.
#  - Updated 'XML2HTML' package with following changes :
#    - contigus 'print' nodes will be printed in one block.
#
# v2.0.0 (13/12/2005)
#  - Updated module to use ISIS::XMLManip.
#  - Added 'OpenParagraph' and 'CloseParagraph' subroutines to OUT2XML.
#  - Added 'LinkCSSFile' subroutine to OUT2XML.
#  - Added 'DiscardMessageType' subroutine to OUT2XML.
#
# v1.2.0 (07/11/2005)
#  - Fixed event id
#
# v1.1.0 (30/09/2005)
#  - Added C++ formatting routines.
#  - Added OUT2XML::IncludeCPP to include file in log.
#  - Added XML2HTML::cpp_include to parse corresponding XML tag.
#
# v1.0.0 (20/09/2005)
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------


#--------------------------------------------------------------------------------------------------
#
#  Logger3::OUT2XML package.
#
#--------------------------------------------------------------------------------------------------
package Logger3::OUT2XML;

use strict;
use warnings;
use ISIS::ErrorDefs;
use ISIS::XMLManip;
use ISIS::HttpServer;
use ISIS::Assertion _DEBUG => 1;

use constant ISIS_VERSION     => '3.1.6';
use constant ISIS_LAST_UPDATE => '23/05/2006';

#--------------------------------------------------------------------------------------------------
# Constructor
#--------------------------------------------------------------------------------------------------
sub new
{
  my ($class, $xml, $verbose, $interface) = (shift, shift || '', shift || 0, shift || HttpServer::GetAddress().'/isis_interface');
  my (@parents, @stylesheets, @javascripts);
  my $html = $xml;
  
  if($xml ne '')
  {
    $xml  .= '.xml'  unless($xml =~ /\.xml$/i);
    $html .= '.html' unless($html =~ s/\.xml$/\.html/);
  }
  
  bless { __html_name    => $html,       # html output file name.
          __xml_name     => $xml,        # xml temp log file name.
          __interface    => $interface,  # interface (css, javascript, images, ...).
          __verbose      => $verbose,    # output to shell.
        	__css_dep      => \@stylesheets, # CSS dependancies.
          __jsc_dep      => \@javascripts, # Javascript dependancies.

          __discards     => '',          # message types to discard.
          __associations => {},          # message types to css class associations.
          __step         => 0,           # unique id attributed to each node in the xml.
          __has_header   => 0,             # flag to check if a generic header is necessary.
          __has_footer   => 0,             # flag to check if a generic footer is necessary.
          __is_generated => 0,           # flag to check correct html output file generation.

          __root_node    => undef,       # xml temp log root node.
          __summary_node => undef,       # summary node.
          __current_node => undef,       # current node when creating xml tree.
          __parent_nodes => \@parents,   # stack containing parent nodes of current node.
        }, $class;
}

#--------------------------------------------------------------------------------------------------
# SetXMLLogName
#--------------------------------------------------------------------------------------------------
sub SetXMLLogName
{
  my ($self, $html) = (shift, shift);
  
  my $xml = $html;

  $xml  .= '.xml'  unless($xml =~ /\.xml$/i);
  $html .= '.html' unless($html =~ s/\.xml$/\.html/);

  $self->{__html_name} = $html;
  $self->{__xml_name}  = $xml;
  
  __ASSERT($self->{__html_name} ne $self->{__xml_name});
}

#--------------------------------------------------------------------------------------------------
# SetXMLLogVerbose
#--------------------------------------------------------------------------------------------------
sub SetXMLLogVerbose
{
  my ($self, $verbose) = (shift, shift);
  
  $self->{__verbose} = ($verbose =~ /(?:on|yes|1)/i) ? 1 : 0;
}

#--------------------------------------------------------------------------------------------------
# SetXMLLogInterface    
#--------------------------------------------------------------------------------------------------
sub SetXMLLogInterface
{
  my ($self, $interface) = (shift, shift);
  
  $interface =~ s/\\$//;
  $self->{__interface} = $interface;
}

#--------------------------------------------------------------------------------------------------
# LinkCSSFile
#--------------------------------------------------------------------------------------------------
sub LinkCSSFile
{
  my ($self, $file) = (shift, shift);
  
  foreach my $css (@{$self->{__css_dep}})
  { return if($css eq $file); }
  
  push @{$self->{__css_dep}}, $file;
}

#--------------------------------------------------------------------------------------------------
# LinkJavascriptFile
#--------------------------------------------------------------------------------------------------
sub LinkJSCFile
{
  my ($self, $file) = (shift, shift);
  
  foreach my $js (@{$self->{__jsc_dep}})
  { return if($js eq $file); }
  
  push @{$self->{__jsc_dep}}, $file;
}

#--------------------------------------------------------------------------------------------------
# DiscardMessageTypes
#--------------------------------------------------------------------------------------------------
sub DiscardMessgeTypes
{
  my ($self) = (shift);
  
  $self->{__discards} = join('|', @_);
}

#--------------------------------------------------------------------------------------------------
# AssociateMessageToClass
#--------------------------------------------------------------------------------------------------
sub AssociateMessageToClass
{
  my ($self, $type, $class) = (shift, shift, shift);
  
  $self->{__associations}->{lc($type)} = $class;
}

#--------------------------------------------------------------------------------------------------
# OpenXMLLog
#--------------------------------------------------------------------------------------------------
sub OpenXMLLog
{
  my ($self) = (shift);

  __ASSERT($self->{__xml_name}  =~ /\.xml/i);
  __ASSERT($self->{__html_name} =~ /\.html/i);

	# create root node.
	$self->{__root_node} = new XMLManip::Node('__log', { date => scalar(localtime),
	                                                     interface => $self->{__interface} });
	
	# create summary node.
	$self->{__summary_node} = new XMLManip::Node('__summary');
	$self->{__summary_node}->Comment(" +++ SUMMARY +++ ");
	
	$self->{__root_node}->Comment("  Name : ".$self->{__xml_name}."\n  Use  : Temporary XML log file - Generated by OUT2XML");
	$self->{__current_node} = $self->{__root_node};
}

#--------------------------------------------------------------------------------------------------
# CloseXMLLog
#--------------------------------------------------------------------------------------------------
sub CloseXMLLog
{
  my ($self) = (shift);
  
  $self->{__root_node}->PushChild($self->{__summary_node}) if($self->{__summary_node});
  
  $self->Header();
  $self->Footer();
  
	foreach my $name ( keys ( %{$self->{__customize_outputer}}) )
	{
		my $custom = new XMLManip::Node('__customoutputer');
		$custom->Attribute('type',$name);
		$custom->Attribute('module',$self->{__customize_outputer}{$name}{module});
		foreach (@{$self->{__customize_outputer}{$name}{config}})
		{
			$custom->PushChild($_);
		}
		$self->{__root_node}->PushChild($custom);
	}
	
  XMLManip::WriteXMLFile($self->{__root_node}, $self->{__xml_name});
  
  my $logger = Logger3::XML2HTML->new($self->{__xml_name}, $self->{__html_name}, $self->{__discards});
  
  foreach (keys %{$self->{__associations}})
  { $logger->AssociateMessageToClass($_, $self->{__associations}->{$_}); }
  
  foreach my $css (@{$self->{__css_dep}})
  { $logger->LinkCSSFile($css); }
  
  foreach my $js (@{$self->{__jsc_dep}})
  { $logger->LinkJSCFile($js); }
  
  $logger->Generate();
  $self->{__is_generated} = 1;
}

#--------------------------------------------------------------------------------------------------
# OpenSummary
#--------------------------------------------------------------------------------------------------
sub OpenSummary
{
  my ($self, $title) = (shift, shift);
  
	$self->{__summary_node}->Attribute('title', $title);
  $self->{__in_summary} = 1;
}

#--------------------------------------------------------------------------------------------------
# CloseSummary
#--------------------------------------------------------------------------------------------------
sub CloseSummary
{
  my ($self) = (shift);
  
	$self->{__in_summary} = 0;
}

#--------------------------------------------------------------------------------------------------
# SummaryElmt
#--------------------------------------------------------------------------------------------------
sub SummaryElmt
{
  my ($self, $tag, $val) = (shift, shift, shift);
  
  $tag =~ s/\n//g;
  $val =~ s/\n//g;
  
  if($self->{__verbose} && $self->{__in_summary})
  { print '  ', $tag, " : ", $val, "\n"; } # STDOUT

  $self->{__summary_node}->PushChild(new XMLManip::Node('__elmt', { tag => $tag, val => $val }));
}

#--------------------------------------------------------------------------------------------------
# SetCustomModule
#--------------------------------------------------------------------------------------------------
sub SetCustomModule($$$)
{
	my ($self, $name, $module, $customConfigNode) = (shift, shift, shift, shift);
	$self->{__customize_outputer} { $name }{module} = $module;
	$self->{__customize_outputer} { $name }{config} = $customConfigNode;
}

#--------------------------------------------------------------------------------------------------
# Header
#--------------------------------------------------------------------------------------------------
sub Header
{
  my ($self, $title, $subtitle) = (shift, shift, shift);
  
  return if($self->{__has_header} == 1);
  
  $title    = $self->{__html_name} unless(defined $title);
  $subtitle = 'Started on '.(localtime) unless(defined $subtitle);
  
  if($self->{__verbose})
  {
  	$self->PrintToShell("---------------------------------------------------------------------\n\n",
  	                    '          ', uc($title), "\n",
  	                    '          ', lc($subtitle), "\n\n",
  	                    "---------------------------------------------------------------------\n");
  }

  my $headerNode = new XMLManip::Node('__header', { title => $title, subtitle => $subtitle });
	$headerNode->Comment(" +++ HEADER +++ ");
	
  $self->{__root_node}->PushChild($headerNode);
  $self->{__has_header} = 1;
}

#--------------------------------------------------------------------------------------------------
# Footer
#--------------------------------------------------------------------------------------------------
sub Footer
{
  my ($self, $title, $subtitle) = (shift, shift, shift || '');
  
  return if($self->{__has_footer} == 1);
  
  $title     = 'Finished on '.(localtime) unless(defined $title);
  $subtitle .= ' - ' if($subtitle ne '');
  $subtitle .= 'Generated by Logger v'.ISIS_VERSION.' ('.ISIS_LAST_UPDATE.')';

  if($self->{__verbose})
  {
  	$self->PrintToShell("---------------------------------------------------------------------\n",
  	                    '  ', lc($title), "\n",
  	                    '  ', lc($subtitle), "\n");
  }
  
  my $footerNode = new XMLManip::Node('__footer', { title => $title, subtitle => $subtitle });
  $footerNode->Comment(" +++ FOOTER +++ ");

  $self->{__root_node}->PushChild($footerNode);
  $self->{__has_footer} = 1;
}

#--------------------------------------------------------------------------------------------------
# OpenMainContent
#--------------------------------------------------------------------------------------------------
sub OpenMainContent
{ 
  my ($self, $title) = (shift, shift);
  
  ++$self->{__step};

  my $contentNode = new XMLManip::Node('__maincontent', { title => $title, step => $self->{__step} });
	$contentNode->Comment(" +++ MAIN CONTENT +++ ");
	
	if($self->{__verbose})
  {
  	$self->PrintToShell("---------------------------------------------------------------------\n",
  	                    '  ', lc($title), "\n",
  	                    "---------------------------------------------------------------------\n");
  }

  push @{$self->{__parent_nodes}}, $self->{__current_node};
  $self->{__current_node}->PushChild($contentNode);
  $self->{__current_node} = $contentNode;
}

#--------------------------------------------------------------------------------------------------
# CloseMainContent
#--------------------------------------------------------------------------------------------------
sub CloseMainContent
{
  my ($self) = (shift);
  
  $self->{__current_node} = pop @{$self->{__parent_nodes}};
}

#--------------------------------------------------------------------------------------------------
# MainTitle
#--------------------------------------------------------------------------------------------------
sub MainTitle
{
	my ($self, $title) = (shift, shift);
	
	++$self->{__step};

	my $titleNode = new XMLManip::Node('__maintitle', { title => $title, step => $self->{__step} });
	$titleNode->Comment(" +++ ".uc($title)." +++ ");
	
	$self->{__current_node}->PushChild($titleNode);
}

#--------------------------------------------------------------------------------------------------
# Separator
#--------------------------------------------------------------------------------------------------
sub Separator
{
	my ($self, $style) = (shift, shift || 'separator');
	
	++$self->{__step};
	
	my $separatorNode = new XMLManip::Node('__separator', { style => $style, step => $self->{__step}});
	$self->{__current_node}->PushChild($separatorNode);
}

#--------------------------------------------------------------------------------------------------
# OpenEvent
#--------------------------------------------------------------------------------------------------
sub OpenEvent
{
	my ($self, $title, $makeup) = (shift, shift, shift || {});
  
  ++$self->{__step};
  
  my $eventNode = new XMLManip::Node('__event');
  $eventNode->Attribute('icon', $makeup->{icon}) if(exists $makeup->{icon});
  $eventNode->Attribute('anim', $makeup->{anim} || 'button');
  $eventNode->Attribute('title', $title);
  $eventNode->Attribute('time', scalar(localtime));
  $eventNode->Attribute('step', $self->{__step});

  if($self->{__verbose})
  {
    $self->PrintToShell("----------------------------------------------------------------------------\n",
                        " + ", $title, "\n");
  }

  push @{$self->{__parent_nodes}}, $self->{__current_node};
  $self->{__current_node}->PushChild($eventNode);
  $self->{__current_node} = $eventNode;
}

#--------------------------------------------------------------------------------------------------
# CloseEvent
#--------------------------------------------------------------------------------------------------
sub CloseEvent
{
  my ($self) = (shift);
  
  $self->{__current_node} = pop @{$self->{__parent_nodes}};
}


sub PrintRawXHTML
{
	my ($self,  $text) = (shift, join('', @_));
  
  ++$self->{__step};
  $self->PrintToShell($text);
  
  my $node = new XMLManip::Node('__print');
  $node->Attribute('time', scalar(localtime));
  $node->Attribute('step', $self->{__step});
  $node->Content($text);

  $self->{__current_node}->PushChild($node);	
}

#--------------------------------------------------------------------------------------------------
# AUTOLOAD (For text output : Print, Error, Warning, Remark, Note).
#--------------------------------------------------------------------------------------------------
sub AUTOLOAD
{
  my ($self, $method, $text) = (shift, our $AUTOLOAD, join('', @_));
  my ($type) = ($method =~ /OUT2XML::(.+?)$/);
  
  return unless (defined($text) or ($type !~ /^$self->{__discards}$/i));
  
  ++$self->{__step};
  
  $self->PrintToShell($text);
  
  $type = '__'.$type if($type =~ /^print$/i);
  $text =~ s/\n/<br\/>/g;

  my $node = new XMLManip::Node(lc($type));
  $node->Attribute('time', scalar(localtime));
  $node->Attribute('step', $self->{__step});
  $node->Content($text);

  $self->{__current_node}->PushChild($node);
}

#--------------------------------------------------------------------------------------------------
# Depreciated Print Subroutines - Should be replaced with formatting tags in regular 'Print'.
#--------------------------------------------------------------------------------------------------
sub PrintBold
{ # For backwards compatibility
  warn "subroutine \'PrintBold\' is depreciated: please update your script and add formatting tags\n";
	OUT2XML::Print('<b>', @_, '</b>');
}

sub PrintItalic
{ # For backwards compatibility
  warn "subroutine \'PrintItalic\' is depreciated: please update your script and add formatting tags\n";
	OUT2XML::Print('<i>', @_, '</i>');
}

sub PrintUnderline
{ # For backwards compatibility
  warn "subroutine \'PrintUnderline\' is depreciated: please update your script and add formatting tags\n";
	OUT2XML::Print('<u>', @_, '</u>');
}

#--------------------------------------------------------------------------------------------------
# OpenParagraph and CloseParagraph.
#--------------------------------------------------------------------------------------------------
sub OpenParagraph
{ warn "subroutine \'OpenParagraph\' is depreciated: please update your script\n"; }

sub CloseParagraph
{ warn "subroutine \'CloseParagraph\' is depreciated: please update your script\n"; }

#--------------------------------------------------------------------------------------------------
# IconText
#--------------------------------------------------------------------------------------------------
sub IconPrint
{
  my ($self, $icon, $text) = (shift, shift, join('', @_));
  
  ++$self->{__step};
  
  $self->PrintToShell($text);

  my $node = new XMLManip::Node('__icon_print');
  $node->Attribute('icon', $icon);
	$node->Attribute('time', scalar(localtime));
  $node->Attribute('step', $self->{__step});
  $node->Content($text);
  $self->{__current_node}->PushChild($node);
}

#--------------------------------------------------------------------------------------------------
# Execute - This doesn't seem to work on version 5.6.1 of perl.
#--------------------------------------------------------------------------------------------------
sub Execute
{
  my ($self, $command) = (shift, shift);
  my $pid = open3(*CMD_IN, *CMD_OUT, *CMD_ERR, $command);
  
  close(CMD_IN);
  
  my $selector = IO::Select->new();
  $selector->add(*CMD_OUT, *CMD_ERR);
  
  while(my @ready = $selector->can_read())
  {
    foreach my $fh (@ready)
    {
      $self->Error(scalar <CMD_ERR>) if(fileno($fh) == fileno(CMD_ERR));
      $self->Print(scalar <CMD_OUT>) if(fileno($fh) == fileno(CMD_OUT));
      $selector->remove($fh) if eof($fh);
    } 
  }
  
  close(CMD_OUT);
  close(CMD_ERR);
  waitpid($pid, 0);
}

#--------------------------------------------------------------------------------------------------
# AppendXmlNode to the structure
#--------------------------------------------------------------------------------------------------
sub AppendXmlNode
{
	my ($self, $node)	= (shift, shift);	
	$self->{__current_node}->PushChild($node);		
}

#--------------------------------------------------------------------------------------------------
# IncludeCPP
#--------------------------------------------------------------------------------------------------
sub IncludeCPP
{
	my ($self, $file, $line, $width) = (shift, shift, shift, shift);
	
	++$self->{__step};
	
	my $cppNode = new XMLManip::Node('__cpp_include');
	$cppNode->Attribute('file', $file);
	$cppNode->Attribute('line', $line);
	$cppNode->Attribute('width', $width);
	$cppNode->Attribute('step', $self->{__step});
	
	$self->{__current_node}->PushChild($cppNode);
}

#--------------------------------------------------------------------------------------------------
# Die
#--------------------------------------------------------------------------------------------------
sub Die
{
  my ($self, $errCode, $message) = (shift, shift);
  my ($pkg, $file, $line) = caller;

  if($file and $line){ $message = $errCode." : ".ERR::GetError($errCode)." in file \'".$file."\' at line \'".$line."\'"; }
  else               { $message = $errCode." : ".ERR::GetError($errCode); }

  $self->Footer("Finished on ".scalar(localtime), "call to OUT2XML::Die( ".$message." )");
  $self->CloseXMLLog();

  exit($errCode);
}

#--------------------------------------------------------------------------------------------------
# Make sure html output is generated.
#--------------------------------------------------------------------------------------------------
sub DESTROY
{
  my ($self) = (shift);

	unless($self->{__is_generated})
	{
		$self->Footer("Finished on ".scalar(localtime));
  	$self->CloseXMLLog();
	}
}

#--------------------------------------------------------------------------------------------------
# PrintToShell
#--------------------------------------------------------------------------------------------------
sub PrintToShell
{
	my ($self, $text) = (shift, join('', @_));
	
  if($text =~ s/\[bold\](.*?)\[\/bold\]/<b>$1<\/b>/g)
  { warn "formatting [bold] ... [/bold] is depreciated: please update your script to use <b> and </b>\n"; }
  
  if($text =~ s/\[italic\](.*?)\[\/italic\]/<i>$1<\/i>/g)
  { warn "formatting [italic] ... [/italic] is depreciated: please update your script to use <i> and </i>\n"; }
  
  if($text =~ s/\[underline\](.*?)\[\/underline\]/<u>$1<\/u>/g)
  { warn "formatting [underline] ... [/underline] is depreciated: please update your script to use <u> and </u>\n"; }
                                                            
  if($self->{__verbose})                                  
  {                                                         
    my $rawText = $text;                                    
   	$rawText =~ s/\<b>//g;
  	$rawText =~ s/\<\/b>//g;
  	$rawText =~ s/\<i>//g;
  	$rawText =~ s/\<\/i>//g;
  	$rawText =~ s/\<u>//g;
  	$rawText =~ s/\<\/u>//g;
    
    print "$rawText";
  }
}

1;

#--------------------------------------------------------------------------------------------------
#
#  XML2HTML package.
#
#--------------------------------------------------------------------------------------------------
package Logger3::XML2HTML;

use strict;
use warnings;
use ISIS::XMLManip;
use ISIS::HTMLmanip;
use ISIS::ErrorDefs;
use ISIS::Assertion _DEBUG => 1;

use constant ISIS_VERSION     => '3.1.5';
use constant ISIS_LAST_UPDATE => '06/04/2006';

#--------------------------------------------------------------------------------------------------
# Constructor
#--------------------------------------------------------------------------------------------------
sub new
{
  my ($class, $xmlfile, $htmlfile, $discard) = (shift, shift, shift, shift || '');
  my (@stylesheets, @javascripts);
  
  bless { __xml_name     => $xmlfile,
          __html_name    => $htmlfile,
          __discards     => $discard,
         	__css_dep      => \@stylesheets,
          __jsc_dep      => \@javascripts,
          __associations => {},
          __outputer     => undef,
        }, $class;
}

#--------------------------------------------------------------------------------------------------
# LinkCSSFile
#--------------------------------------------------------------------------------------------------
sub LinkCSSFile
{
  my ($self, $file) = (shift, shift);
  
  foreach my $css (@{$self->{__css_dp}})
  { return if($css == $file); }
  
	push @{$self->{__css_dep}}, $file;
}

#--------------------------------------------------------------------------------------------------
# LinkJavascriptFile
#--------------------------------------------------------------------------------------------------
sub LinkJSCFile
{
  my ($self, $file) = (shift, shift);
  
	foreach my $js (@{$self->{__jsc_dep}})
	{ return if($js == $file); }
	
	push @{$self->{__jsc_dep}}, $file;
}

#--------------------------------------------------------------------------------------------------
# AssociateMessageToClass
#--------------------------------------------------------------------------------------------------
sub AssociateMessageToClass
{
  my ($self, $type, $class) = (shift, shift, shift);
  
  $self->{__associations}->{lc($type)} = $class;
}

#--------------------------------------------------------------------------------------------------
# GenHTMLLogFile : Only subroutine to be called.
#--------------------------------------------------------------------------------------------------
sub Generate
{
  my ($self, $ostream) = (shift);
  
  open($ostream, '>'.$self->{__html_name}) or return ERR::FILE_CREATION_FAILED;
  
  $self->{__xml_data} = XMLManip::ParseXMLFile($self->{__xml_name});
  my $outputer = new HTMLManip($ostream, 'configuration.xml', $self->{__xml_data}->Attribute('interface') || '');
  
  $self->{__outputer} = $outputer;
  
  foreach my $css (@{$self->{__css_dep}})
  { $outputer->UserRequireCSSFile($css); }
  
  foreach my $js (@{$self->{__jsc_dep}})
  { $outputer->UserRequireJSFile($js); }

  # Create document.
  my $document = $outputer->Create('Log::Document');

	my %CustomOutputer;
	foreach my $c (@{$self->{__xml_data}->Child('__customoutputer')})
	{
		$CustomOutputer{ $c->Attribute('type') }{ module } = $c->Attribute('module');
		$CustomOutputer{ $c->Attribute('type') }{ config } = $c;
	}

  # Create header.
  my $hNode = ${$self->{__xml_data}->Child('__header')}[0];
	if($hNode)
	{
	  	if ($CustomOutputer{'__header'})
	  	{
			$document->Header($outputer->Create( $CustomOutputer{'__header'}{module},
	                                    $hNode->Attribute('title'),
	                                    $hNode->Attribute('subtitle'),
	                                    $CustomOutputer{'__header'}{config}));

	  	}
	  	else
	  	{
			$document->Header($outputer->Create( 'Log::Header',
	                                    $hNode->Attribute('title'),
	                                    $hNode->Attribute('subtitle')));
	  	}
 	}

	# Create footer.
  my $fNode = ${$self->{__xml_data}->Child('__footer')}[0];
	if ($fNode)
	{
	 	if ($CustomOutputer{'__footer'})
	  	{
			$document->Footer($outputer->Create( $CustomOutputer{'__footer'}{module},
	                                    $fNode->Attribute('title'),
	                                    $fNode->Attribute('subtitle'),
	                                    $CustomOutputer{'__footer'}{config}));

	  	}
	  	else
	  	{
			$document->Footer($outputer->Create('Log::Footer',
	                                    $fNode->Attribute('title'),
	                                    $fNode->Attribute('subtitle')));
	  	}
	}

	# Create summary
	my $sNode = ${$self->{__xml_data}->Child('__summary')}[0];
	$document->Summary($self->__Summary($sNode));

	# Merge all contigus prints to one.
	$self->__MergePrints($self->{__xml_data});

	# Create main content.
	$self->__PrintMainContents($document, @{$self->{__xml_data}->Child('__maincontent')});

	$document->Print();
	
	if($self->{__updated_xml})
	{
	  $self->{__xml_name} =~ s/\.xml/_updated\.xml/;
	  XMLManip::WriteXMLFile($self->{__xml_data}, $self->{__xml_name});
	}

	return ERR::NO_ERROR;
}

#--------------------------------------------------------------------------------------------------
# Print main contents in output HTML logfile.
#--------------------------------------------------------------------------------------------------
sub __PrintMainContents
{
	my ($self, $parent) = (shift, shift);
	my $outputer = $self->{__outputer};

	foreach my $xmlNode (@_)
	{
		my $maincontent = $outputer->Create('Log::MainContent');
		$parent->PushChild($maincontent);
		
		if($xmlNode->Attribute('title'))
		{
	  	my $title = $outputer->Create('Title1', $xmlNode->Attribute('title'));
	  	$maincontent->PushChild($title);
		}

		foreach (@{$xmlNode->Childs()})
		{
			no strict 'refs';
			my $function = $_->Type();
			$self->$function($maincontent, $_);
		}
	}
}

#--------------------------------------------------------------------------------------------------
# Print summary in output HTML logfile.
#--------------------------------------------------------------------------------------------------
sub __Summary
{
  my ($self, $sNode) = (shift, shift);
  my ($outputer, $title, $table) = ($self->{__outputer}, undef, undef);

  my $summary = $outputer->Create('Log::Summary');
	my $content = $outputer->Create('Log::SummaryContent');
	$summary->PushChild($content);

  if($sNode)
  {
    $title = $outputer->Create('Title1', $sNode->Attribute('title'));
    $content->PushChild($title);
    $table = $outputer->Create('Table2D');
    $content->PushChild($table);
  
    foreach (@{$sNode->Child('__elmt')})
    {
      my $tag = $outputer->Create('Text', $_->Attribute('tag'));
      $tag->Style('s_tag');
      my $val = $outputer->Create('Text', $_->Attribute('val'));
      $val->Style('s_val');
      
      $table->AddLine($tag, $val);
    }
    
    $table->SetColumnAttr(0, { nowrap => 'nowrap', valign => 'top' });
    $table->SetColumnAttr(1, { width => '100%' });
  }
  
  $title = $outputer->Create('Title1', 'Global Statistics');
  $content->PushChild($title);
  $table = $outputer->Create('Table2D');
  $content->PushChild($table);
  
  my @texts;
  my %counts = __NbMsgGeneric($self->{__xml_data});
  foreach my $type (sort keys %counts)
  {
    my $value = $counts{$type};
    my $text  = $outputer->Create('Text', "$value $type".($value == 1 ? '' : 's'));
    $text->Style($value ? "gbl_cnt_$type" : 'gbl_cnt_default');
    
    push @texts, $text;
    $self->{__types}->{$type} = 0;
  }

  $table->AddLine(@texts);
  
  return $summary;
}

#--------------------------------------------------------------------------------------------------
# Main content title.
#--------------------------------------------------------------------------------------------------
sub __maintitle
{
	my ($self, $parent, $xmlNode) = (shift, shift, shift);
	my $outputer  = $self->{__outputer};
	my $titleNode = $outputer->Create('Title1', $xmlNode->Attribute('title'));
	
	$parent->PushChild($titleNode);
}

#--------------------------------------------------------------------------------------------------
# Print event.
#--------------------------------------------------------------------------------------------------
sub __event
{
  my ($self, $parent, $xmlNode) = (shift, shift, shift);
  my $outputer = $self->{__outputer};
  
  my $eventNode = $outputer->Create('Node', $xmlNode->Attribute('title'),
  																					{ anim => $xmlNode->Attribute('anim'),
                                              icon => $xmlNode->Attribute('icon') });

  my %counts = __NbMsgGeneric($xmlNode);
  foreach my $type (sort keys %{$self->{__types}})
  {
    my $value = $counts{$type} || '0';
    $eventNode->PushNodeInfo("$value $type".($value == 1 ? '' : 's'),
                             ($value ? "cnt_$type" : 'cnt_default'));
  }
  
  foreach (@{$xmlNode->Childs()})
  {
    no strict 'refs';
    my $function = $_->Type();
    $self->$function($eventNode, $_); 
  }
  
  $parent->PushChild($eventNode);
}

#--------------------------------------------------------------------------------------------------
# Print text with left side icon.
#--------------------------------------------------------------------------------------------------
sub __icon_print
{
  my ($self, $parent, $xmlnode) = (shift, shift, shift);
  my $outputer = $self->{__outputer};
  
  my $content = $xmlnode->Content();

	if ($content)
	{
		$content =~ s/\&lt;b\&gt;/<b>/g;
		$content =~ s/\&lt;\/b\&gt;/<\/b>/g;
		$content =~ s/\&lt;i\&gt;/<i>/g;
		$content =~ s/\&lt;\/i\&gt;/<\/i>/g;
		$content =~ s/\&lt;u\&gt;/<u>/g;
		$content =~ s/\&lt;\/u\&gt;/<\/u>/g;
		$content =~ s/\&lt;br\/\&gt;/\n/g;
	}
	
	my $text = $outputer->Create('Text', $content);
  $text->Style($outputer->GetAssociatedClass($xmlnode->Attribute('icon')));
  
  $parent->PushChild($text);
}

#--------------------------------------------------------------------------------------------------
# Print separators.
#--------------------------------------------------------------------------------------------------
sub __separator
{
	my ($self, $parent, $xmlNode) = (shift, shift, shift);
	my $outputer = $self->{__outputer};
	
	my $separator = $outputer->Create('Separator', $xmlNode->Attribute('style'));
	$parent->PushChild($separator);
}

#--------------------------------------------------------------------------------------------------
# Print all other output types.
#--------------------------------------------------------------------------------------------------
sub AUTOLOAD
{
	my ($method, $self, $parent, $xmlNode) = (our $AUTOLOAD, shift, shift, shift);
	my $outputer = $self->{__outputer};

	return if($method =~ /::DESTROY$/ or $xmlNode->Type() =~ /^$self->{__discards}$/i);
	
	my $content = $xmlNode->Content();

	if ($content)
	{
		$content =~ s/\&lt;b\&gt;/<b>/g;
		$content =~ s/\&lt;\/b\&gt;/<\/b>/g;
		$content =~ s/\&lt;i\&gt;/<i>/g;
		$content =~ s/\&lt;\/i\&gt;/<\/i>/g;
		$content =~ s/\&lt;u\&gt;/<u>/g;
		$content =~ s/\&lt;\/u\&gt;/<\/u>/g;
		$content =~ s/\&lt;br\/\&gt;/\n/g;
	}
	
	my $text = $outputer->Create('Text', $content);
	$text->Style($self->{__associations}->{$xmlNode->Type()} ||
	             $outputer->GetAssociatedClass($xmlNode->Type()));
	
	foreach (@{$xmlNode->Childs()})
  {
    no strict 'refs';
    my $function = $_->Type();
    $self->$function($parent, $_); 
  }

	$parent->PushChild($text);
}

#--------------------------------------------------------------------------------------------------
# Merge printouts.
#--------------------------------------------------------------------------------------------------
sub __MergePrints
{
	my ($self, $node, $i) = (shift, shift, 0);
	my $rCldArray = $node->Childs();
	
	while($i != scalar @$rCldArray)
	{
	  my ($chStart, $chEnd) = ($$rCldArray[$i], undef);
	  if($chStart->Type() eq '__print')
	  {
	    my $j = $i + 1;
	    while(($chEnd = $$rCldArray[$j]) && ($chEnd->Type eq '__print'))
	    { ++$j; }
	    --$j;
	    
	    if($i != $j)
	    {
	      my $node    = new XMLManip::Node('__print', $chStart->Attributes());
	      my $content = '';

	      for my $k ($i .. $j)
	      { $content .= $$rCldArray[$k]->Content(); }
	      
	      $self->{__updated_xml} = 1;
	      $node->Content($content);
	      splice(@$rCldArray, $i, $j - $i + 1, $node);
	    }
	  }
	  else
	  {
	    $self->__MergePrints($chStart) if(scalar @{$chStart->Childs()} != 0);
	  }

	  ++$i;
	}
}

#--------------------------------------------------------------------------------------------------
# Count number of specific messages in event - Generic version.
#--------------------------------------------------------------------------------------------------
sub __NbMsgGeneric
{
  my ($node, %counts) = (shift);

  foreach my $child (@{$node->Childs()})
  {
    unless(scalar @{$child->Childs()} == 0)
    {
      my %res = __NbMsgGeneric($child);
      
      foreach my $type (keys %res)
      {
        $counts{$type} = ($counts{$type} || 0);
        $counts{$type} += $res{$type};
      }
    }

    next if($child->Type() =~ /^__.*$/);
    
    ++$counts{$child->Type()};
  }

  return %counts;
}

1;

__END__

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

ISIS::Logger2 - An HTML log generator module.

=head1 SYNOPSIS

	use ISIS::Logger3;
	use ISIS::HttpServer;
	
	my $logger = new Logger3::OUT2XML('test_log.xml', 1, HttpServer::GetAddress()."/isis_interface");

	# Set temporary log name, interface, and verbose.
	$logger->SetXMLLogName('test_log.xml');
	
	# Link a CSS file to the HTML output.
	$logger->LinkCSSFile('style.css');
	
	# Open the log.
	$logger->OpenXMLLog();
	
	# Print a summary.
	$logger->OpenSummary("Log Summary");
	$logger->SummaryElmt("Build Type", "Multibase");
	$logger->SummaryElmt("Used SymbianOS", "value 2");
	$logger->SummaryElmt("Used Series 60", "value 3");
	$logger->CloseSummary();
	
	# Print a header.
	$logger->Header("Log File Logger2 Test v".Logger2::ISIS_VERSION, "Started on ".(localtime));
	
	# Create a main content.
	$logger->OpenMainContent("Main Content 2");
		$logger->OpenEvent("Event 1 : First step");
		  $logger->Error("This is an error\non two lines");
		  $logger->OpenEvent("SubEvent 1 : Test");
		  	$logger->Print("This is simple text");
		  	$logger->OpenEvent("SubSubEvent 1 : Test");
		  		$logger->Warning("This is a warning");
		  		
		  		$logger->OpenParagraph('bold');
		  		my @array = ('tom', 'dick', 'harry');
		  		foreach (@array) { $logger->Print($_."\n"); }
		  		$logger->CloseParagraph();

		  	$logger->CloseEvent();
		  $logger->CloseEvent();
		$logger->CloseEvent();
		$logger->OpenEvent("Event 2 : Second step");
			$logger->Print("This is a normal output");
		$logger->CloseEvent();
		$logger->OpenEvent("Event 3 : Third step");
			$logger->Warning("This is a warning");
		$logger->CloseEvent();
		$logger->OpenEvent("Event 4 : Fourth step");
			$logger->Remark("This is a remark");
		$logger->CloseEvent();
	$logger->CloseMainContent();
	
	# Print a footer.
	$logger->Footer("Finished on ".(localtime), "No HTML Generation");
	
	# Close the temporary log file.
	$logger->CloseXMLLog();

=head1 DESCRIPTION

The ISIS::Logger2 module provides several packages used to create a complex, 
well presented and organised log file. There are two packages within this module :
C<L<OUT2XML>> and C<L<XML2HTML>>. The first one generates an XML file that will
be parsed by the second one in order to generate the proper output.

The C<L<OUT2XML>> package provides a set of simple subroutines allowing to print
regular output to the terminal while logging all the information for HTML log
generation.

The C<L<XML2HTML>> package contains a set of subroutines that shouldn't be called
directly by the user. It contains a main subroutine 'GenHTMLLogFile' that will
automatically be called after a call to 'OUT2XML::CloseXMLLog' or 'OUT2XML::Die'.
This subroutine parses the whole XML generated by OUT2XML and uses the OUT set of
modules to generate the equivalent HTML output.

=head1 OUT2XML

=head2 SetXMLLogName( STRING ) :

Defines the temporary XML file name. This subroutine should be called before
'OpenXMLLog';

=head2 SetXMLLogInterface( STRING ) :

Defines the interface root to be used for the HTML log file. This subroutine
should be called before 'OpenXMLLog';

=head2 SetXMLLogVerbose( STRING ) :

Defines if logged information should be outputed to the terminal/shell. This
subroutine should be called before 'OpenXMLLog';

=head2 OpenXMLLog( ) :

Opens the XML log - Should be called after 'SetXMLLogName', 'SetXMLLogInterface' and
'SetXMLLogVerbose'.

=head2 CloseXMLLog( ) :

Close the XML log file. This subroutine will automatically call 'XML2HTML::GenHTMLLogFile'.

=head2 OpenSummary( ) :

If verbose is set for the logger, this will ensure that a call to 'SummaryElmt'
prints out its content, otherwise, a call to 'SummaryElmt' will have no effect
on the terminal/shell and will only log its information.

=head2 CloseSummary(  ) :

Ends the verbose of summary elements. See 'OpenSummary' for more information.

=head2 SummaryElmt( NAME, VALUE ) :

Logs a name and its value pair to generate a summary in the outputed HTML file.
If called between 'OpenSummary' and 'CloseSummary', an additionnal output to the
terminal/shell will be performed.

=head2 OpenMainContent( STRING ) :

Creates a new main content in which events can be created. All future calls to
the print out subroutine or events will be encapsulated in that main event until
a call to 'CloseMainContent' is made.

=head2 CloseMainContent( STRING ) :

Closes the current main content. Note that all events and print out subroutine
calls will be discarded.

=head2 OpenEvent( STRING ) :

Creates a new event in which other events and print out subroutine calls can be
made. These events will hide their content until they are clicked on, allowing
the final log user to decide what information to display.

=head2 CloseEvent( STRING ) :

Closes the current event. All events and print out subroutine calls will be passed
to the containing main content or event.

=head2 OpenParagraph( STYLE ) :

This will open a paragraph, and all calls to 'OUT2XML::Print' will be encapsulated in
one HTML div element. The optional style argument will be set as the class of the div
element allowing to modify the text's appearence with a css. The 'OUT2XML::Print'
subroutine can still be called normally.

=head2 CloseParagraph(  ) :

Closes the current paragraph, returning to the previously opened and not closed node.

=head2 Print( STRING ) :

Prints out regular text to the log file. This text will be discarded if not done
in a main content, event or paragraph. If this subroutine is called outside of a
paragraph, an automatic paragraph will be generated for this text. Prefer using
'OUT2XML::OpenParagraph' and 'OUT2XML::CloseParagraph' when calling 'OUT2XML::Print'
several times in a row.

=head2 <NAME>( STRING, [ERROR_CODE] ) :

Prints out a message as a NAME - The message will be encapsulated in a <div> HTML
element with a class attribute matching that name. The corresponding CSS file that
is set with 'SetXMLLogInterface' can have the equivalent definitions to format these
HTML elements.

If an error code is specified, a call to 'Die' will be made terminating the current
script.

=head2 Die( STRING, [ERROR_CODE] ) :

Kills the current script execution. Only calls to 'Die' should be made in a script
using this Logger. Calling subroutines such as 'exit' or 'die' will corrupt the xml
log file and make the HTML generation impossible.

=head1 XML2HTML

=head2 GenHTMLLogFile( XMLFILE ) :

Generates an HTML log file from an XML log file created by the C<L<OUT2XML>> package.
See information regarding the C<L<OUT2XML>> package of the ISIS::Logger2 module.

=head1 AUTHOR



=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
