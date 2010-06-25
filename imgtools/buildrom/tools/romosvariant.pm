# Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Collection of utilitiy functions which is copied from Symbian OS perl modules. 
# It provides platform related information to ROM Tools including buildrom, 
# features.pl, etc.
# 

package romosvariant;

require Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(
	os_name
	is_windows
	is_linux
	env_delimiter
	path_delimiter
);

use strict;

sub os_name
{
	return $^O;
}

sub is_windows
{
	if ($^O =~ /^MSWin32$/i){
		return 1;
	}else{
		return 0;
	}	
}

sub is_linux
{
	if ($^O =~ /^MSWin32$/i){
		return 0;
	}else{
		return 1;
	}	
}

sub env_delimiter
{
	if ($^O =~ /^MSWin32$/i){
		return ";";
	}else{
		return ":";
	}
}

sub path_delimiter
{
	if ($^O =~ /^MSWin32$/i){
		return "\\";
	}else{
		return "\/";
	}
}

1;
