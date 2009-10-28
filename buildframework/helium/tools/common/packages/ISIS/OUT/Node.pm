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
#!/usr/bin/perl -w
#--------------------------------------------------------------------------------------------------
# Name   : Node.pm
# Use    : HTML node element that can toggle its content.

#
# Synergy :
# Perl %name: Node.pm % (%full_filespec:  Node.pm-4.1.2:perl:fa1s60p1#1 %)
# %derived_by:  wbernard %
# %date_created:  Fri Mar 17 17:14:15 2006 %
#
# Version History :
# v1.1.2 (15/03/2006)
#  - Updated the package constructor to take an extra hash table as last argument.
#  - Updated the Print subroutine to reflect added makeup to HTML look of nodes.
#
# v1.1.1 (01/02/2006)
#  - Corrected node info display method to align cells.
#
# v1.1.0 (26/01/2006)
#  - Corrected HTML to display node info correctly.
#
# v1.0.0 (12/11/2005)
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   NodeInfo package.
#
#--------------------------------------------------------------------------------------------------
package _NodeInfo;

sub new
{
  bless { _outputer => pop,
          class     => pop,
          value     => pop,
        }, shift;
}

sub AUTOLOAD
{
  my $self = shift;
  $self->{_outputer}->_Accessor($self, our $AUTOLOAD, @_);
}

1;

#--------------------------------------------------------------------------------------------------
#
#   Node package.
#
#--------------------------------------------------------------------------------------------------
package OUT::Node;

use strict;
use warnings;
use ISIS::OUT::Outputer;
use ISIS::OUT::Debug;
use ISIS::HttpServer;

use constant ISIS_VERSION     => '1.1.2';
use constant ISIS_LAST_UPDATE => '15/03/2006';

#--------------------------------------------------------------------------------------------------
# Constructor.
#--------------------------------------------------------------------------------------------------
sub new
{
  warn "new OUT::Node( ".join(", ", @_)." )\n" if(DBG::NODE);
  my ($class, $outputer, @childs) = (shift, pop);
  
  my $title  = shift || 'No title';
	my $makeup = shift || {};
  
  $outputer->RequireJSFile('javascript/expand2.js');

  bless { title     => $title,
          style     => $makeup->{style} || 'node_details',
          anim      => $makeup->{anim} || 'button',
          icon      => $makeup->{icon} || undef,
          _info     => undef,
          _childs   => \@childs,
          _outputer => $outputer,
        }, $class;
}

#--------------------------------------------------------------------------------------------------
# Push Node Information.
#--------------------------------------------------------------------------------------------------
sub PushNodeInfo
{
  warn "OUT::Node::PushNodeInfo( ", join(', ', @_), " )\n" if(DBG::NODE);
  my $self     = shift;
  my $outputer = $self->{_outputer};

  push @{$self->{_info}}, new _NodeInfo(shift, shift || 'text_default', $outputer) if(@_);
}

#--------------------------------------------------------------------------------------------------
# Push Child.
#--------------------------------------------------------------------------------------------------
sub PushChild
{
  warn "OUT::Node::PushChild( ", join(', ', @_), " )\n" if(DBG::NODE);
  my $self = shift;
  push @{$self->{_childs}}, shift if(@_);
}

#--------------------------------------------------------------------------------------------------
# Print function.
#--------------------------------------------------------------------------------------------------
sub Print
{
  warn "OUT::Node::Print( ", join(', ', @_), " )\n" if(DBG::NODE);
  my $self     = shift;
  
  my $outputer = $self->{_outputer};
  my $indent   = $outputer->Indent();
  my $iface    = $outputer->Interface();
  my $id       = $outputer->Id();

  $outputer->Id($id + 1);
  
  $outputer->Print("<div class=\"node_head\">\n");
  
  if(scalar @{$self->{_childs}})
  {	
  	$outputer->Print("  <a href=\"javascript:ToggleNode(\'Img", $id, "\')\">\n");
  	$outputer->Indent($indent . '  ');
  }
                   
  $outputer->Print("  <span id=\"Img", $id, "\" style=\"background:url(".HttpServer::GetAddress()."/isis_interface/img/icons/", $self->{anim}, "_", (scalar @{$self->{_childs}} ? 'open' : 'invalid'), ".gif) no-repeat\">\n",
                   "    <span class=\"node_title\">\n",
                   (defined $self->{icon} ? "<span class=\"".$self->{icon}."\">\n" : ""),
                   "      ", $self->{title}, "\n",
                   (defined $self->{icon} ? "</span>\n" : ""),
                   "    </span>\n",
                   "  </span>\n"
                   );

  if(scalar @{$self->{_childs}})
  {
  	$outputer->Indent($indent);
  	$outputer->Print(
  									 "  </a>\n",
	                   "  <a href=\"javascript:ShowChilds(\'Img", $id, "\')\"><span class=\"node_action\">\[Show All\]</span></a>\n",
	                   "  <a href=\"javascript:HideChilds(\'Img", $id, "\')\"><span class=\"node_action\">\[Hide All\]</span></a>\n",
	                   "  <a href=\"javascript:ToggleNode(\'Img", $id, "\')\">\n"
	                  );
	  $outputer->Indent($indent . '  ');
  }
                  
  if($self->{_info})
  {
  	$outputer->Print("  <span class=\"node_info\">\n");
    foreach my $info (@{$self->{_info}})
    { $outputer->Print("    <span class=\"", $info->Class(), "\">", $info->Value(), "</span>\n"); }
    $outputer->Print("  </span>\n");
  }
  
  if(scalar @{$self->{_childs}})
  {
  	$outputer->Indent($indent);
  	$outputer->Print("  </a>\n");
  }
  
  $outputer->Print("</div>\n");
  
  if(scalar @{$self->{_childs}})
  {
  	$outputer->Print(
	                   "<div id=\"Content", $id, "\" style=\"display:none\">\n",
	                   "  <div class=\"node_content\">\n"
	                  );
  	
    $outputer->Indent($indent . '    ');
    foreach (@{$self->{_childs}})
    { $_->Print(); }
    $outputer->Indent($indent);
    
    $outputer->Print(
	                   "   </div>\n",
	                   "</div>\n"
	                  );
  }
}

#--------------------------------------------------------------------------------------------------
# Accessor.
#--------------------------------------------------------------------------------------------------
sub AUTOLOAD
{
  my ($self, $method) = (shift, our $AUTOLOAD);
  warn "$method( ".join(', ', @_)." )\n" if(DBG::NODE);
  $self->{_outputer}->_Accessor($self, $method, @_);
}

1;

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
