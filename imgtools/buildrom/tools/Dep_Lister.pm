#
# Copyright (c) 1997-2009 Nokia Corporation and/or its subsidiary(-ies).
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

# This package contains routines to find the static and dynamic dependencies of a binary.
package Dep_Lister;

use cdfparser;
require Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(
	StaticDeps
);

use strict;

# This subroutine evaluates the static dependencies of an E32 executable and returns the list of
# binary names that this binary is dependent on (as found in its import table). If the input file
# is not a valid E32 executable, this routine returns an 'undef'.
sub StaticDeps()
{
	my ($file) = @_;
	my @statdeps;

	open PIPE, "elf2e32 --dump i --e32input=$file 2>&1 | ";
	my $executable;
	my $ver;
	my $ext;
	my $binary;
	my $binaryInfoRef;
	my $fileName;

	if($file =~ /.*\\(\S+)/)
	{
		$fileName = $1;
	}
	while(<PIPE>)
	{
		if($_ =~ /(\d+) imports from (.*)\{(.*)\}\[?(.*)\]?\.(.*)/i)
		{
			my $skipLines = $1;
			$executable = $2;
			$ver = $3;
			$ext = $5;

			$binary = $executable . "." . $ext;
			
			push @statdeps,$binary;

#			Each imported symbol's ordinal number is printed in these lines...
#			Skip them
			if($skipLines > 0)
			{
				while(<PIPE>)
				{
					$skipLines--;
					if($skipLines == 0 )
					{
						last;
					}
				}	
			}
		}
		elsif($_ =~ /elf2e32 : Error: .* is not a valid E32Image file/)
		{
#			not an e32 image...mark the file as a data file
			return undef;
		}
	}
	close PIPE;
	return (@statdeps);
}

1;
