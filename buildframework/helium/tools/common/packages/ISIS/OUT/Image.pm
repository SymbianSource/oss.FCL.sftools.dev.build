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
# Name   : Image.pm
# Use    : Simple HTML image element.

#
# Synergy :
# Perl %name: Image.pm % (%full_filespec:  Image.pm-2:perl:fa1s60p1#1 %)
# %derived_by:  wbernard %
# %date_created:  Thu Feb  2 14:18:22 2006 %
#
# Version History :
#
# v1.0 (12/11/2005) :
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

package OUT::Image;

use strict;
use warnings;
use ISIS::OUT::Outputer;
use ISIS::OUT::Debug;

use constant ISIS_VERSION     => '1.00';
use constant ISIS_LAST_UPDATE => '21/12/2005';

#--------------------------------------------------------------------------------------------------
# Constructor.
#--------------------------------------------------------------------------------------------------
sub new
{
  warn "new OUT::Image( ", join(', ', @_), " )\n" if(DBG::IMAGE);
  my $outputer = pop;
  
  bless { file      => $outputer->Interface().$_[1],
          height    => pop,
          width     => pop,
          alt       => undef,          
          _outputer => $outputer,
        }, shift; 
}

sub Print
{
  my $self = shift;
  my $outputer = $self->{_outputer};
  $self->{alt} ||= '';
  
  $outputer->Print("<div class=\"icon\">\n",
                   "  <img src=\"", $self->{file}, "\" width=\"", $self->{width}, "\" height=\"", $self->{height}, "\" alt=\"", $self->{alt}, "\" />\n",
                   "</div>\n"
                  );
}

sub AUTOLOAD
{
	my ($self, $method) = (shift, our $AUTOLOAD);
	warn "$method( ".join(', ', @_)." )\n" if(DBG::IMAGE);
	$self->{_outputer}->_Accessor($self, $method, @_);
}

1;

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
