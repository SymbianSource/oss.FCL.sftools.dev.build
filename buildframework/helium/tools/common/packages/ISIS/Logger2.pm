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
# Name   : Logger2.pm
# Use    : ISIS Logging module.

#
# Synergy :
# Perl %name    : % (%full_filespec :  %)
# %derived_by   : %
# %date_created : %
#
# History :
# v2.2.5 (25/05/2006):
#  - Save old html log.
#
# v2.2.4 (03/05/2006):
#  - Added Execute function to launch command and get it's output.
#
#
# v2.2.3 (06/04/2006):
#  - Reworte the way user defined CSS files are handled to make sure they are the last ones
#    included in the document body to allow overwriting of certain values.
#
# v2.2.2 (05/04/2006):
#  - Updated OUT2XML and XML2HTML to store CSS and JS files in arrays to preserve order.
#
# v2.2.1 (16/03/2006):
#    - Added SetCustomModule to manage custom Outputer submodules
#    - Can now specifiy custom Outputer class for Header and Footer.
#
# v2.2.0 (27/01/2006):
#  - Rewrote XML2HTML package :
#    - Corrected event printout.
#    - Added special message count.
#    - Added global special message count.
#    - Errors, Warnings, Remarks and Notes now have Ids.
#    - Any type of specific message is printed.
#
# v2.1.1 (13/01/2006):
#  - Updated Die subroutine to print line and file if specified.
#
# v2.1.0 (11/01/2006):
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
# v2.0.0 (13/12/2005):
#  - Updated module to use ISIS::XMLManip.
#  - Added 'OpenParagraph' and 'CloseParagraph' subroutines to OUT2XML.
#  - Added 'LinkCSSFile' subroutine to OUT2XML.
#  - Added 'DiscardMessageType' subroutine to OUT2XML.
#
# v1.2.0 (07/11/2005):
#  - Fixed event id
#
# v1.1.0 (30/09/2005) :
#  - Added C++ formatting routines.
#  - Added OUT2XML::IncludeCPP to include file in log.
#  - Added XML2HTML::cpp_include to parse corresponding XML tag.
#
# v1.0.0 (20/09/2005) :
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

package Logger2;

require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(OUT2XML XML2HTML);

use constant ISIS_VERSION     => '2.2.5';
use constant ISIS_LAST_UPDATE => '25/05/2006';

1;

my %ModuleData; # Common data to all packages.

#--------------------------------------------------------------------------------------------------
#
#   OUT2XML package;
#
#--------------------------------------------------------------------------------------------------

package OUT2XML;

use strict;
use warnings;
use ISIS::ErrorDefs;
use ISIS::XMLManip;

use constant ISIS_VERSION     => '1.2.0';
use constant ISIS_LAST_UPDATE => '13/12/2005';

#--------------------------------------------------------------------------------------------------
# SetXMLLogName
#--------------------------------------------------------------------------------------------------
sub SetXMLLogName
{
  $ModuleData{htmlFile}  = shift;
  $ModuleData{xmlFile}   = $ModuleData{htmlFile};
  $ModuleData{htmlFile}  =~ s/\.xml/\.html/;
  $ModuleData{xmlFile}   =~ s/\.[^\.]+$//;
  $ModuleData{xmlFile}  .= '.xml';
}

#--------------------------------------------------------------------------------------------------
# SetXMLLogVerbose
#--------------------------------------------------------------------------------------------------
sub SetXMLLogVerbose
{
  $ModuleData{verbose} = shift;
  
  if($ModuleData{verbose} =~ /(?:off|no|0)/i) { $ModuleData{verbose} = 0; }
  else                                        { $ModuleData{verbose} = 1; }
}

#--------------------------------------------------------------------------------------------------
# SetXMLLogInterface    
#--------------------------------------------------------------------------------------------------
sub SetXMLLogInterface
{
  $ModuleData{interface} = shift;
  $ModuleData{interface} =~ s/\\$//;
}

#--------------------------------------------------------------------------------------------------
# LinkCSSFile
#--------------------------------------------------------------------------------------------------
sub LinkCSSFile
{
  my ($file) = (shift);
  
  foreach my $css (@{$ModuleData{css}})
  { return if($css eq $file); }
  
  push @{$ModuleData{css}}, $file;
}

#--------------------------------------------------------------------------------------------------
# LinkJSCFile
#--------------------------------------------------------------------------------------------------
sub LinkJSCFile
{
  my ($file) = (shift);
  
  foreach my $js (@{$ModuleData{jsc}})
  { return if($js eq $file); }
  
  push @{$ModuleData{jsc}}, $file;
}

#--------------------------------------------------------------------------------------------------
# DiscardMessageTypes
#--------------------------------------------------------------------------------------------------
sub DiscardMessgeTypes
{
  $ModuleData{discard} = join('|', @_);
}

sub DiscardEmptyNodes
{
	$ModuleData{discard_empty_nodes} = 1;
}

#--------------------------------------------------------------------------------------------------
# AssociateMessageToClass
#--------------------------------------------------------------------------------------------------
sub AssociateMessageToClass
{
	my ($type, $class) = (shift, shift);
	print "Registering $type to HTML class $class\n";
	$ModuleData{classes}->{lc($type)} = $class;
}

#--------------------------------------------------------------------------------------------------
# OpenXMLLog
#--------------------------------------------------------------------------------------------------
sub OpenXMLLog
{
	$ModuleData{classes}->{error}   ||= 'cr_r';
	$ModuleData{classes}->{warning} ||= 'cr_y';
	$ModuleData{classes}->{remark}  ||= 'ch_g';
	$ModuleData{classes}->{note}    ||= 'ch_b';
	
	$ModuleData{discard_empty_nodes} ||= '0';
	
  $ModuleData{step}         = 0;
  $ModuleData{rootNode}     = new XMLManip::Node('__log', { date => scalar(localtime) });
  $ModuleData{currentNode}  = $ModuleData{rootNode};

  $ModuleData{rootNode}->Comment("  Name : ".$ModuleData{xmlFile}."\n  Use  : Temporary XML log file - Generated by OUT2XML");
}

#--------------------------------------------------------------------------------------------------
# CloseXMLLog
#--------------------------------------------------------------------------------------------------
sub CloseXMLLog
{
  $ModuleData{rootNode}->PushChild($ModuleData{summaryNode}) if ($ModuleData{summaryNode});

	foreach my $name ( keys ( %{$ModuleData{customizeOutputer}}) )
	{
		my $custom = new XMLManip::Node('__customoutputer');
		$custom->Attribute('type',$name);
		$custom->Attribute('module',$ModuleData{customizeOutputer}{$name}{module});
		foreach (@{$ModuleData{customizeOutputer}{$name}{config}})
		{
			$custom->PushChild($_);
		}
		$ModuleData{rootNode}->PushChild($custom);
	}
	&XMLManip::WriteXMLFile($ModuleData{rootNode}, $ModuleData{xmlFile});
  &XML2HTML::GenHTMLLogFile($ModuleData{xmlFile}, $ModuleData{htmlFile}, $ModuleData{discard});
}

#--------------------------------------------------------------------------------------------------
# OpenSummary
#--------------------------------------------------------------------------------------------------
sub OpenSummary
{
	my $summaryNode = new XMLManip::Node('__summary');
	
	$summaryNode->Comment(" +++ SUMMARY +++ ");
	$summaryNode->Attribute('title', shift);
  
  $ModuleData{summaryNode} = $summaryNode;
  $ModuleData{inSummary}   = 1;
}

#--------------------------------------------------------------------------------------------------
# CloseSummary
#--------------------------------------------------------------------------------------------------
sub CloseSummary
{
	$ModuleData{inSummary} = 0;
}

#--------------------------------------------------------------------------------------------------
# SummaryElmt
#--------------------------------------------------------------------------------------------------
sub SummaryElmt
{
  my ($tag, $val) = (shift, shift);
  
  $tag =~ s/\n//g;
  $val =~ s/\n//g;
  
  if($ModuleData{verbose})
  {
    print '  ', $tag, " : ", $val, "\n" if($ModuleData{inSummary}); # STDOUT
  }

	my $elementNode = new XMLManip::Node('__elmt', { tag => $tag, val => $val });
	$ModuleData{summaryNode}->PushChild($elementNode);
}

#--------------------------------------------------------------------------------------------------
# SetCustomModule
#--------------------------------------------------------------------------------------------------
sub SetCustomModule($$$)
{
	my ($name, $module, $customConfigNode) = (shift, shift, shift);
	$ModuleData{customizeOutputer} { $name }{module} = $module;
	$ModuleData{customizeOutputer} { $name }{config} = $customConfigNode;
}

#--------------------------------------------------------------------------------------------------
# Header
#--------------------------------------------------------------------------------------------------
sub Header
{
  my $headerNode = new XMLManip::Node('__header', { title => shift, subtitle => shift });

  $headerNode->Comment(" +++ HEADER +++ ");
  $ModuleData{rootNode}->PushChild($headerNode);
}

#--------------------------------------------------------------------------------------------------
# Footer
#--------------------------------------------------------------------------------------------------
sub Footer
{
  my $footerNode = new XMLManip::Node('__footer', { title => shift, subtitle => shift });

  $footerNode->Comment(" +++ FOOTER +++ ");
  $ModuleData{rootNode}->PushChild($footerNode);
}

#--------------------------------------------------------------------------------------------------
# OpenMainContent
#--------------------------------------------------------------------------------------------------
sub OpenMainContent
{ 
  ++$ModuleData{step};
  my $contentNode = new XMLManip::Node('__maincontent', { title => shift, step => $ModuleData{step} });
	$contentNode->Comment(" +++ MAIN CONTENT +++ ");

  push @{$ModuleData{parentNodes}}, $ModuleData{currentNode};
  $ModuleData{currentNode}->PushChild($contentNode);
  $ModuleData{currentNode} = $contentNode;
}

#--------------------------------------------------------------------------------------------------
# CloseMainContent
#--------------------------------------------------------------------------------------------------
sub CloseMainContent
{
	$ModuleData{currentNode} = pop @{$ModuleData{parentNodes}};
}

#--------------------------------------------------------------------------------------------------
# MainTitle
#--------------------------------------------------------------------------------------------------
sub MainTitle
{
	my ($title) = (shift);
	
	++$ModuleData{step};
	my $titleNode = new XMLManip::Node('__maintitle', { title => $title, step => $ModuleData{step} });
	$titleNode->Comment(" +++ ".uc($title)." +++ ");
	
	$ModuleData{currentNode}->PushChild($titleNode);
}

#--------------------------------------------------------------------------------------------------
# OpenEvent
#--------------------------------------------------------------------------------------------------
sub OpenEvent
{
  my ($title) = (shift);
  ++$ModuleData{step};
  
  my $eventNode = new XMLManip::Node('__event');
  $eventNode->Attribute('title', $title);
  $eventNode->Attribute('time', scalar(localtime));
  $eventNode->Attribute('step', $ModuleData{step});

  if($ModuleData{verbose})
  {
    print "----------------------------------------------------------------------------\n",
          " + ", $title, "\n";
  }
  
	push @{$ModuleData{parentNodes}}, $ModuleData{currentNode};
	$ModuleData{currentNode}->PushChild($eventNode);
	$ModuleData{currentNode} = $eventNode;
}

#--------------------------------------------------------------------------------------------------
# CloseEvent
#--------------------------------------------------------------------------------------------------
sub CloseEvent
{
	$ModuleData{currentNode} = pop @{$ModuleData{parentNodes}};
}

#--------------------------------------------------------------------------------------------------
# AUTOLOAD (For text output : Print, Error, Warning, Remark, Note).
#--------------------------------------------------------------------------------------------------
sub AUTOLOAD
{
  my ($method, $text) = (our $AUTOLOAD, join('', @_));
  return unless($text);
  ++$ModuleData{step};
  my ($type) = ($method =~ /::(.*)$/);

  if($text =~ s/\[bold\](.*?)\[\/bold\]/<b>$1<\/b>/g)
  { warn "formatting [bold] ... [/bold] is depreciated: please update your script to use <b> and </b>\n"; }
  
  if($text =~ s/\[italic\](.*?)\[\/italic\]/<i>$1<\/i>/g)
  { warn "formatting [italic] ... [/italic] is depreciated: please update your script to use <i> and </i>\n"; }
  
  if($text =~ s/\[underline\](.*?)\[\/underline\]/<u>$1<\/u>/g)
  { warn "formatting [underline] ... [/underline] is depreciated: please update your script to use <u> and </u>\n"; }
                                                            
  if($ModuleData{verbose})                                  
  {                                                         
    my $rawText = $text;                                    
   	$rawText =~ s/\<b>//g;
  	$rawText =~ s/\<\/b>//g;
  	$rawText =~ s/\<i>//g;
  	$rawText =~ s/\<\/i>//g;
  	$rawText =~ s/\<u>//g;
  	$rawText =~ s/\<\/u>//g;
    
    if($type !~ /^print$/i) { print " \/!\\ ", uc($type)," :\n$rawText\n\n"; }
    else                    { print "$rawText"; $type = '__'.$type; }
  }

  my $node = new XMLManip::Node(lc($type));
  $node->Attribute('time', scalar(localtime));
  $node->Attribute('step', $ModuleData{step});
  $node->Content($text);

  $ModuleData{currentNode}->PushChild($node);
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
  my ($icon, $text) = (shift, join('', @_));
  ++$ModuleData{step};

  my $node = new XMLManip::Node('__icon_print');
  $node->Attribute('icon', $icon);
  
  if($text =~ s/\[bold\](.*?)\[\/bold\]/<b>$1<\/b>/g)
  { warn "formatting [bold] ... [/bold] is depreciated: please update your script to use <b> and </b>\n"; }
  
  if($text =~ s/\[italic\](.*?)\[\/italic\]/<i>$1<\/i>/g)
  { warn "formatting [italic] ... [/italic] is depreciated: please update your script to use <i> and </i>\n"; }
  
  if($text =~ s/\[underline\](.*?)\[\/underline\]/<u>$1<\/u>/g)
  { warn "formatting [underline] ... [/underline] is depreciated: please update your script to use <u> and </u>\n"; }
                                                            
  if($ModuleData{verbose})                                  
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

	$node->Attribute('time', scalar(localtime));
  $node->Attribute('step', $ModuleData{step});
  $node->Content($text);
  $ModuleData{currentNode}->PushChild($node);
}

#--------------------------------------------------------------------------------------------------
# AppendXmlNode to the structure
#--------------------------------------------------------------------------------------------------
sub AppendXmlNode
{
	my ($node)	= (shift);	
	$ModuleData{currentNode}->PushChild($node);		
}

#--------------------------------------------------------------------------------------------------
# Allow to execute a command and get it's output into the logger
#--------------------------------------------------------------------------------------------------
use IPC::Open3;  
sub Execute
{
	my ( $cmd ) = @_;
	my $childpid = open3(\*WTRFH, \*RDRFH, \*ERRFH, $cmd);
	close(WTRFH);
	close(ERRFH);
	my $out = "";
	while(<RDRFH>)
	{
			$out .= <RDRFH>;
	}
	# Closing cleanly....
	close(RDRFH);		

	# dump content
	OUT2XML::Print ( $out."\n" );

	waitpid($childpid, 0);
}


#--------------------------------------------------------------------------------------------------
# IncludeCPP
#--------------------------------------------------------------------------------------------------
sub IncludeCPP
{
	my ($file, $line, $width) = (shift, shift, shift);
	++$ModuleData{step};
	
	my $cppNode = new XMLManip::Node('__cpp_include');
	$cppNode->Attribute('file', $file);
	$cppNode->Attribute('line', $line);
	$cppNode->Attribute('width', $width);
	$cppNode->Attribute('step', $ModuleData{step});
	
	$ModuleData{currentNode}->PushChild($cppNode);
}

#--------------------------------------------------------------------------------------------------
# Die
#--------------------------------------------------------------------------------------------------
sub Die
{
  my ($errCode, $message) = (shift);
  my ($pkg, $file, $line) = caller;

  if($file and $line){ $message = $errCode." : ".ERR::GetError($errCode)." in file \'".$file."\' at line \'".$line."\'"; }
  else               { $message = $errCode." : ".ERR::GetError($errCode); }

  Footer("Finished on ".scalar(localtime), "call to OUT2XML::Die( ".$message." )");
  CloseXMLLog();

  exit($errCode);
}

1;

#--------------------------------------------------------------------------------------------------
#
#  XML2HTML package.
#
#--------------------------------------------------------------------------------------------------

package XML2HTML;

use strict;
use warnings;
use File::Copy;
use ISIS::XMLManip;
use ISIS::HTMLmanip;
use ISIS::ErrorDefs;

use constant ISIS_VERSION     => '2.0.0 alpha';
use constant ISIS_LAST_UPDATE => '13/12/2005';

my $XMLData; # xml file parsed data.

#--------------------------------------------------------------------------------------------------
# GenHTMLLogFile : Only subroutine to be called.
#--------------------------------------------------------------------------------------------------
sub GenHTMLLogFile
{
	my ($xmlfile, $htmlfile, $discard, $ostream) = (shift, shift, shift);

  $ModuleData{discard} = $discard || '';
  
  # Saving old log id existing
  if ( -e $htmlfile )
  {
  	my $id = 1;
  	my $nn;
  	do {
  		$nn = $htmlfile;
  		$nn =~ s/\.html/_${id}.html/;
  		$id++;
  	}
  	while ( -e $nn );
  	print "$htmlfile -> $nn\n";	
  	move ($htmlfile, $nn);
  }
  
	open($ostream, '>'.$htmlfile) or return ERR::FILE_CREATION_FAILED;

  # Read XML and create document body.
	$XMLData  = &XMLManip::ParseXMLFile($xmlfile);
	my $outputer = new HTMLManip($ostream, 'configuration.xml', $ModuleData{interface});
	
	foreach my $css (@{$ModuleData{css}})
	{ $outputer->UserRequireCSSFile($css); }
	
	foreach my $js (@{$ModuleData{jsc}})
	{ $outputer->UserRequireJSFile($js); }
	
	my $document = $outputer->Create('Log::Document');
	
	my %CustomOutputer;
	foreach my $c (@{$XMLData->Child('__customoutputer')})
	{
		$CustomOutputer{ $c->Attribute('type') }{ module } = $c->Attribute('module');
		$CustomOutputer{ $c->Attribute('type') }{ config } = $c;
	}
	
	# Create header.
	my $hNode = ${$XMLData->Child('__header')}[0];
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
	my $fNode = ${$XMLData->Child('__footer')}[0];
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
	my $sNode = ${$XMLData->Child('__summary')}[0];
	$document->Summary(&__Summary($outputer, $sNode, $XMLData));
	
	# Merge all contigus prints to one.
	&__MergePrints($XMLData);
	
	# Create main content.
	&__PrintMainContents($document, $outputer, @{$XMLData->Child('__maincontent')});
	
	$document->Print();
	
	if($ModuleData{updatedxml})
	{
	  $xmlfile =~ s/\.xml/_updated\.xml/;
	  &XMLManip::WriteXMLFile($XMLData, $xmlfile);
	}

	return ERR::NO_ERROR;
}

#--------------------------------------------------------------------------------------------------
# Print main contents in output HTML logfile.
#--------------------------------------------------------------------------------------------------
sub __PrintMainContents
{
	my ($parent, $outputer) = (shift, shift);

	foreach my $xmlNode (@_)
	{
		my $maincontent = $outputer->Create('Log::MainContent');
		$parent->PushChild($maincontent);
		
	  my $title = $outputer->Create('Title1', $xmlNode->Attribute('title'));
	  $maincontent->PushChild($title);

		foreach (@{$xmlNode->Childs()})
		{
			no strict 'refs';
			my $function = $_->Type();
			&$function($maincontent, $outputer, $_);
		}
	}
}

#--------------------------------------------------------------------------------------------------
# Print summary in output HTML logfile.
#--------------------------------------------------------------------------------------------------
sub __Summary
{
  my ($outputer, $sNode, $rootNode) = (shift, shift, shift);
  my ($title, $table) = (undef, undef);

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
  }
  
  $title = $outputer->Create('Title1', 'Global Statistics');
  $content->PushChild($title);
  $table = $outputer->Create('Table2D');
  $content->PushChild($table);
  
  my @texts;
  my %counts = &__NbMsgGeneric($rootNode);
  foreach my $type (sort keys %counts)
  {
    my $value = $counts{$type};
    my $text  = $outputer->Create('Text', "$value $type".($value == 1 ? '' : 's'));
    $text->Style($value ? "gbl_cnt_$type" : 'gbl_cnt_default');
    
    push @texts, $text;
    $ModuleData{types}{$type} = 0;
  }

  $table->AddLine(@texts);
  
  return $summary;
}

#--------------------------------------------------------------------------------------------------
# Main content title.
#--------------------------------------------------------------------------------------------------
sub __maintitle
{
	my ($parent, $outputer, $xmlNode) = (shift, shift, shift);
	my $titleNode = $outputer->Create('Title1', $xmlNode->Attribute('title'));
	
	$parent->PushChild($titleNode);
}

#--------------------------------------------------------------------------------------------------
# Print event.
#--------------------------------------------------------------------------------------------------
sub __event
{
  my ($parent, $outputer, $xmlNode) = (shift, shift, shift);
  
  my $eventNode = $outputer->Create('Node', $xmlNode->Attribute('title'));
  $eventNode->DiscardIfEmpty() if($ModuleData{discard_empty_nodes});

  my %counts = &__NbMsgGeneric($xmlNode);
  foreach my $type (sort keys %{$ModuleData{types}})
  {
    my $value = $counts{$type} || '0';
    $eventNode->PushNodeInfo("$value $type".($value == 1 ? '' : 's'),
                             ($value ? "cnt_$type" : 'cnt_default'));
  }
  
  foreach (@{$xmlNode->Childs()})
  {
    no strict 'refs';
    my $function = $_->Type();
    &$function($eventNode, $outputer, $_); 
  }
  
  $parent->PushChild($eventNode);
}

#--------------------------------------------------------------------------------------------------
# Print text with left side icon.
#--------------------------------------------------------------------------------------------------
sub __icon_print
{
  my ($parent, $outputer, $xmlnode) = (shift, shift, shift);
  
  my $text = $outputer->Create('Text', $xmlnode->Content());
  $text->Style($outputer->GetAssociatedClass($xmlnode->Attribute('icon')));
  
  $parent->PushChild($text);
}

#--------------------------------------------------------------------------------------------------
# Print all other output types.
#--------------------------------------------------------------------------------------------------
sub AUTOLOAD
{
	my ($method, $parent, $outputer, $xmlNode) = (our $AUTOLOAD, shift, shift, shift);
	
	#print $method, "\n";
	return if($xmlNode->Type() =~ /^$ModuleData{discard}$/);
	
	my $content = $xmlNode->Content();

	if ($content)
	{
		$content =~ s/\&lt;b\&gt;/<b>/g;
		$content =~ s/\&lt;\/b\&gt;/<\/b>/g;
		$content =~ s/\&lt;i\&gt;/<i>/g;
		$content =~ s/\&lt;\/i\&gt;/<\/i>/g;
		$content =~ s/\&lt;u\&gt;/<u>/g;
		$content =~ s/\&lt;\/u\&gt;/<\/u>/g;
	}
	
	my $text = $outputer->Create('Text', $content);
	$text->Style($ModuleData{classes}->{$xmlNode->Type()});
	
	foreach (@{$xmlNode->Childs()})
  {
    no strict 'refs';
    my $function = $_->Type();
    &$function($parent, $outputer, $_); 
  }

	$parent->PushChild($text);
}

#--------------------------------------------------------------------------------------------------
# Merge printouts.
#--------------------------------------------------------------------------------------------------
sub __MergePrints
{
	my ($node, $i) = (shift, 0);
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
	      { $content .= $$rCldArray[$k]->Content() || ''; }
	      
	      $ModuleData{updatedxml} = 1;
	      $node->Content($content);
	      splice(@$rCldArray, $i, $j - $i + 1, $node);
	    }
	  }
	  else
	  {
	    __MergePrints($chStart) if(scalar @{$chStart->Childs()} != 0);
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

	use ISIS::Logger2;

	# Set temporary log name, interface, and verbose.
	OUT2XML::SetXMLLogName('test_log.xml');
	OUT2XML::SetXMLLogInterface('isis_interface/');
	OUT2XML::SetXMLLogVerbose('on');
	
	# Link a CSS file to the HTML output.
	OUT2XML::LinkCSSFile('style.css');
	
	# Open the log.
	OUT2XML::OpenXMLLog();
	
	# Print a summary.
	OUT2XML::OpenSummary("Log Summary");
	OUT2XML::SummaryElmt("Build Type", "Multibase");
	OUT2XML::SummaryElmt("Used SymbianOS", "value 2");
	OUT2XML::SummaryElmt("Used Series 60", "value 3");
	OUT2XML::CloseSummary();
	
	# Print a header.
	OUT2XML::Header("Log File Logger2 Test v".Logger2::ISIS_VERSION, "Started on ".(localtime));
	
	# Create a main content.
	OUT2XML::OpenMainContent("Main Content 2");
		OUT2XML::OpenEvent("Event 1 : First step");
		  OUT2XML::Error("This is an error\non two lines");
		  OUT2XML::OpenEvent("SubEvent 1 : Test");
		  	OUT2XML::Print("This is simple text");
		  	OUT2XML::OpenEvent("SubSubEvent 1 : Test");
		  		OUT2XML::Warning("This is a warning");
		  		
		  		OUT2XML::OpenParagraph('bold');
		  		my @array = ('tom', 'dick', 'harry');
		  		foreach (@array) { OUT2XML::Print($_."\n"); }
		  		OUT2XML::CloseParagraph();

		  	OUT2XML::CloseEvent();
		  OUT2XML::CloseEvent();
		OUT2XML::CloseEvent();
		OUT2XML::OpenEvent("Event 2 : Second step");
			OUT2XML::Print("This is a normal output");
		OUT2XML::CloseEvent();
		OUT2XML::OpenEvent("Event 3 : Third step");
			OUT2XML::Warning("This is a warning");
		OUT2XML::CloseEvent();
		OUT2XML::OpenEvent("Event 4 : Fourth step");
			OUT2XML::Remark("This is a remark");
		OUT2XML::CloseEvent();
	OUT2XML::CloseMainContent();
	
	# Print a footer.
	OUT2XML::Footer("Finished on ".(localtime), "No HTML Generation");
	
	# Close the temporary log file.
	OUT2XML::CloseXMLLog();

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
