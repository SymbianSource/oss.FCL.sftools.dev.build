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

SHELL:=$(SBS_HOME)/win32/bin/talon.exe
TALON_SHELL:=$(SBS_HOME)/win32/cygwin/bin/bash.exe
TALON_BUILDID:=1
TALON_RECIPEATTRIBUTES:=123

export

all::
	@|name=fred;|mkdir out;touch source.txt;xcopy /y source.txt out

