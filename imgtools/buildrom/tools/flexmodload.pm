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
# Runtime module-loading routine for loading e32toolp modules into 'main' module
# 
#


package flexmodload;

use romutl;

require Exporter;
@ISA=qw(Exporter);

@EXPORT=qw(
	FlexLoad_ModuleL
);

sub FlexLoad_ModuleL (@) {
# Loads a module into the 'main' package, including all the functions the module defines for export

	my @ModBaseList=@_;
	my $ModBase;
	foreach $ModBase (@ModBaseList) {
		$ModBase=lc $ModBase;

		package main;
		require $ModBase.".pm" or die "ERROR: Can't load function from \"$ModBase.pm\"\n";
		my $Package=ucfirst lc $ModBase;
		$Package->import;
	}
}

1;
