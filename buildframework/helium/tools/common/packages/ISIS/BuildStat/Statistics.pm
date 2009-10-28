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
# Name   : Statistics.pm
# Use    : description.

#
# Version History :
#
# v1.0 (03/05/2006) :
#  - Fist version of the script.
#------------------------------------------------------------------------------
package Statistics;
use strict;
use ISIS::XMLManip;
use Time::HiRes;
use HTTP::Request::Common;
use LWP::UserAgent;


# ISIS constants.
use constant ISIS_VERSION 		=> '1.0.0';
use constant ISIS_LAST_UPDATE => '03/05/2006';

#------------------------------------------------------------------------------
# Package Function
#------------------------------------------------------------------------------

sub new
{
	my ($class, $type, $id, $toolchain) = @_;
	my $self = {
			__type => $type,
			__id => $id,
			__tools => $toolchain,
			__date => Time::HiRes::time(),
			__steps => undef,
			__cstep => undef,
		};
	return bless $self, $class;
}


sub AddStep
{
	my ($self, $name, $buildtime) = @_;
	my $h = { 'name' => $name, 'buildtime' => $buildtime};
	push 	@{$self->{__steps}}, $h;
}

sub StartStep
{
	my ($self, $name) = @_;
	$self->{__cstep}->{'name'} = $name;
	$self->{__cstep}->{'starttime'} = Time::HiRes::time();
}

sub StopStep
{
	my ($self) = @_;
	$self->{__cstep}->{'buildtime'} = Time::HiRes::time() - $self->{__cstep}->{'starttime'};
	$self->AddStep($self->{__cstep}->{'name'}, $self->{__cstep}->{'buildtime'});
	$self->{__cstep} = undef;
}

sub GenerateXML
{
	my ($self, $filename) = @_;
	open (OUT, $filename);
	close (OUT);
	my $rootNode = new XMLManip::Node('statistics');
 
 	my $buildinfo = new XMLManip::Node('buildinfo',  { type => $self->{__type},
 		 					id => $self->{__id},
			 		  tools => $self->{__tools},
			 		  date => $self->{__date} });
 	$rootNode->PushChild($buildinfo);
 	 		
	foreach my $step ( @{$self->{__steps}} )
	{
		my $xstep = new XMLManip::Node('step', {name => $step->{'name'}, time => $step->{'buildtime'}});
		
		$buildinfo->PushChild( $xstep );
	}
 
	&XMLManip::WriteXMLFile($rootNode, $filename);
}

sub GenerateXMLAndUpload
{
	my ($self, $server) = @_;
	my $filename = '/statistics.xml';
	$self->GenerateXML( $filename );

	$HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;


	my $hash = {
			'data_file' => [ $filename ],
			'filename' => 'statistics.txt'
		};
	
	#my $request = HTTP::Request->new( );
	my $ua = LWP::UserAgent->new;
	my $response = $ua->request(POST "$server", 'Content-Type' => 'multipart/form-data', Content => $hash );
	print $response->as_string."\n";

}

1;
#------------------------------------------------------------------------------
# End of file.
#------------------------------------------------------------------------------
