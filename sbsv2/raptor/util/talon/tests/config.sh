#!/bin/bash
#
# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
# set up the environment for some talon tests.

eval `$SBS_HOME/bin/gethost.sh -e`

if [[ "$HOSTPLATFORM" =~ "win" ]]; then
TEST_SHELL=$(cygpath -w $SBS_HOME/win32/bin/talon.exe)
TEST_TALON_SHELL=$(cygpath -w $SBS_CYGWIN/bin/bash.exe)
else
TEST_SHELL=$SBS_HOME/$HOSTPLATFORM_DIR/bin/talon
TEST_TALON_SHELL=/bin/bash
fi

cat >settings.mk <<-endofsettings
	SHELL:=$TEST_SHELL
	TALON_SHELL:=$TEST_TALON_SHELL
	TALON_BUILDID:=100
	TALON_DEBUG:=""
	export TALON_SHELL TALON_BUILDID TALON_DEBUG
endofsettings
