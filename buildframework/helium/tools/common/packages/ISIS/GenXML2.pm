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
# Name   : GenBuildTools.pm
# Use    : description.

#
# Synergy :
# Perl %name: GenXML2.pm % (%full_filespec:  GenXML2.pm-2:perl:fa1s60p1#1 %)
# %derived_by:  wbernard %
# %date_created:  Wed Apr 26 08:24:25 2006 %
#
# Version History :
#
# v1.1.0 (26/04/2006) :
#  - Fix input file loading by managing duplicate id name.
#
# v1.0 (22/12/2005) :
#  - Fist version of the package.
#------------------------------------------------------------------------------
package GenXML2;
use Cwd;

sub new
{
	my ($class) = @_;
	#no strict 'refs';
  my $self = {
    		m_CurrentStep => 0,
				m_Data => {}
    };
  bless $self, $class;
}

sub parseFile
{
	my ($self, $filename, @args) = @_;

	my $drive = Cwd::cwd(); $drive =~ /(.:)/; $drive = $1;

	$filename = $drive.$filename if ($filename =~ /^\\/);

	open (INPUT, "cpp.exe -nostdinc -u  @args $filename |");
	my $id = 0;
	foreach my $line (<INPUT>)
	{
		$line =~ s/#.*$//;
		next if ($line =~ /^\s*$/);
		if ($line =~ /^\s*NEWSTEP\s*$/)
		{
			#print "NEWSTEP\n";
			$self->{ m_CurrentStep } = $self->{ m_CurrentStep }+1;
		}
		elsif ($line =~ /(\w+)\s*,\s*(\S+)\s*,\s*\"(.*)\"/)
		{
			#print "$1, $2, $3\n";
			
			my $name = $1;
			my $path = $2;
			my $cmd = $3;
			$self->{ m_Data }->{ $self->{ m_CurrentStep } }->{$id}->{'name'} = $name;
			$self->{ m_Data }->{ $self->{ m_CurrentStep } }->{$id}->{'path'} = $path;
			$self->{ m_Data }->{ $self->{ m_CurrentStep } }->{$id}->{'cmd'} = $cmd;
			++$id;
		}
		else
		{
			warn "WARNING: error at line $line\n";
		}
	}

	close (INPUT)
}



sub generateTBSXML
{
		my ($self, $filename) = @_;
		
		my $id = 1;
		open (OUTPUT, ">$filename") or die "Cannot open $filename";
		
		print OUTPUT "<?xml version=\"1.0\"?>\n";
        print OUTPUT "<!DOCTYPE Build  [\n";
        print OUTPUT "<!ELEMENT Product (Commands)>\n";
        print OUTPUT "<!ATTLIST Product name CDATA #REQUIRED>\n";
        print OUTPUT "<!ELEMENT Commands (Execute+ | SetEnv*)>\n";
        print OUTPUT "<!ELEMENT Execute EMPTY>\n";
        print OUTPUT "<!ATTLIST Execute ID CDATA #REQUIRED>\n";
        print OUTPUT "<!ATTLIST Execute Stage CDATA #REQUIRED>\n";
        print OUTPUT "<!ATTLIST Execute Component CDATA #REQUIRED>\n";
        print OUTPUT "<!ATTLIST Execute Cwd CDATA #REQUIRED>\n";
        print OUTPUT "<!ATTLIST Execute CommandLine CDATA #REQUIRED>\n";
        print OUTPUT "<!ELEMENT SetEnv EMPTY>\n";
        print OUTPUT "<!ATTLIST SetEnv Order ID #REQUIRED>\n";
        print OUTPUT "<!ATTLIST SetEnv Name CDATA #REQUIRED>\n";
        print OUTPUT "<!ATTLIST SetEnv Value CDATA #REQUIRED>\n";
				print OUTPUT "]>\n";
		
		print OUTPUT "<Product Name=\"genxml2\">\n";
    print OUTPUT "   <Commands>\n";
    print OUTPUT "   		<SetEnv Order=\"1\" Name=\"EPOCROOT\" Value=\"\\\"/>\n";
		print OUTPUT "   <SetEnv Order=\"2\" Name=\"PATH\" Value=\"\\epoc32\\gcc\\bin;\\epoc32\\tools;%PATH%\"/>\n";

		foreach my $key ( sort { $a <=> $b } keys ( %{$self->{ m_Data }} ) )
		{
			foreach my $name ( keys ( %{$self->{ m_Data }->{ $key } } ) )
			{				
				print OUTPUT "<Execute ID=\"$id\" Stage=\"$key\" Component=\"".$self->{ m_Data }->{ $key }->{$name}->{'name'}."\" Cwd=\"".$self->{ m_Data }->{ $key }->{$name}->{'path'}."\" CommandLine=\"".$self->{ m_Data }->{ $key }->{$name}->{'cmd'}."\" />\n";
				$id++;
			}
		}
    print OUTPUT "   </Commands>\n";
		print OUTPUT "</Product>\n";
		close (OUTPUT);
}
1;
#------------------------------------------------------------------------------
# End of file.
#------------------------------------------------------------------------------