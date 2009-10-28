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
# Name   : EmbeddedScanLog.pm
# Use    : description.

#
# Synergy :
# Perl %name: EmbeddedScanLog.pm % (%full_filespec:  EmbeddedScanLog.pm-6:perl:fa1s60p1#1 %)
# %derived_by:  wbernard %
# %date_created:  Fri May  5 15:58:07 2006 %
#
# Version History :
#
# v1.1.1 (05/05/2006) :
#  - EmbeddedScanLog::ElectricCloud managed TBS output
#
# v1.1.0 (29/03/2006) :
#  - EmbeddedScanLog::TBS created
#  - EmbeddedScanLog::ElectricCloud created
#  - EmbeddedScanLog autoselect correct parser.
#
# v1.0.0 (09/02/2006) :
#  - Fist version of the package.
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# TBS Package's subroutines
#------------------------------------------------------------------------------
package EmbeddedScanLog::TBS;
use strict;
use ISIS::ScanLogTBS;


# ISIS constants.
use constant ISIS_VERSION 		=> '1.1.0';
use constant ISIS_LAST_UPDATE => '29/03/2006';


sub new
{
	my ( $class, $logname ) = @_;		
  bless { _logname => $logname
        }, $class;
}

sub GetDisplayName
{
	my $self = shift;
	$self->{_logname} =~ /\S*(?:\\|\/)(\S+)(_build_tbs)?_bld\.log$/;
	return "$1";
}

sub Generate
{
	my $self = shift;
	my $scanlog = new ScanLogTBS  ( $self->{_logname} );
	return $scanlog->GenerateDataStructure();
}

sub IsValidLogName($)
{
	my $logname = shift;
	return 1 if ($logname =~ /_bld\.log$/i);
	return 0;
}

sub FindLog
{
	my ($name,$path)= (shift, shift||'.');
	my @array = ( "$path/${name}_bld.log",
							"$path/${name}_build_tbs_bld.log");

	foreach my $n (@array)
	{
		return $n if ( -e $n );
	}
	return undef;
}

1;

#------------------------------------------------------------------------------
# ElectricCloud Package's subroutines
#------------------------------------------------------------------------------
package EmbeddedScanLog::ElectricCloud;
use strict;
use ISIS::ScanLog;

# ISIS constants.
use constant ISIS_VERSION 		=> '1.0.0';
use constant ISIS_LAST_UPDATE => '29/03/2006';

sub new
{
	my ( $class, $logname ) = @_;		
  bless { _logname => $logname
        }, $class;
}

sub GetDisplayName
{
	my $self = shift;
	$self->{_logname} =~ /emake_logs\.(\S+)\.emake\..*$/;
	return "$1";
}

sub Generate
{
	my $self = shift;
	if ( $self->{_logname} =~ /\.emake.stdout.ebs.log$/i)
	{
		my $scanlog = new ScanLogTBS( $self->{_logname} );
		return $scanlog->GenerateDataStructure();
	}
	else
	{
		my $scanlog = new ScanLog( $self->{_logname}, 0, 0 );
		return $scanlog->GenerateDataStructure();
	}
}

sub IsValidLogName($)
{
	my $logname = shift;
	return 1 if ($logname =~ /\.emake.anno.xml$/i );
	return 1 if ($logname =~ /\.emake.stdout.ebs.log$/i );
	return 0;
}

sub FindLog
{
	my ($name,$path)= (shift, shift||'./');
	my $n = "/logs/emake_logs/emake_logs.$name.emake.stdout.ebs.log";
	return $n if ( -e $n );
	$n = "/logs/emake_logs/emake_logs.$name.emake.anno.xml";
	return $n if ( -e $n );
}
1;



#------------------------------------------------------------------------------
# EmbeddedScanLog Package's subroutines
#------------------------------------------------------------------------------
package EmbeddedScanLog;
use strict;
use ISIS::Logger3;
use File::Path; # mkpath

# ISIS constants.
use constant ISIS_VERSION 		=> '1.1.0';
use constant ISIS_LAST_UPDATE => '29/03/2006';

my @__engines;
BEGIN {
@__engines = ('EmbeddedScanLog::ElectricCloud',
							'EmbeddedScanLog::TBS');
}

sub new
{
	my ( $class, $logname ) = @_;
	
	my $scanlogger => undef;
	
	no strict 'refs';
	foreach my $engine (@__engines)
	{
		my $method = $engine."::IsValidLogName";		
		if (&$method($logname))
		{
			$scanlogger = new $engine($logname);
			last;
		}
	}
  bless { __scanlogger => $scanlogger, __logname => $logname  }, $class;
}

sub Generate
{
	my $self = shift;
	if ( $self->{__scanlogger} )
	{                         
		my $node = $self->{__scanlogger}->Generate();
		OUT2XML::AppendXmlNode( $node );	
		$self->__GenerateScanLog( $node );
	}
}

sub FindLog
{
	my ($name,$path)= (shift, shift);
		
	no strict 'refs';
	foreach my $engine (@__engines)
	{
		my $method = $engine."::FindLog";
		my $logfile =  &$method($name,$path);
		return $logfile if ($logfile);
	}
	return undef;
}


sub __GenerateScanLog
{
	my ($self, $node) = (shift, shift);
	my $destpath = '/logs/scanlog';
	mkpath ( $destpath );
	if ( -d $destpath )
	{
		my $name = $self->{__scanlogger}->GetDisplayName();
		my $logger = new Logger3::OUT2XML( "$destpath/$name.xml" );
		$logger->OpenXMLLog();

		$logger->Header("Scanlog - $name");
	
		$logger->OpenMainContent ( "Scanlog" );
			$logger->AppendXmlNode ( $node );
		$logger->CloseMainContent ();
		
		$logger->CloseXMLLog();	}
}

1;

#------------------------------------------------------------------------------
# End of file.
#------------------------------------------------------------------------------