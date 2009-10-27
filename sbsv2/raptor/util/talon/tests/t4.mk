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

SHELL:=$(TALON)
TALON_TIMEOUT:=4000
TALON_RETRIES:=4
TALON_RECIPEATTRIBUTES:=platform='$$PLATFORM' mmp='$$MMP' bldinf='$$BLDINF'
export 

$(info testing timeouts)
$(info )

all:
	@|PLATFORM=armv5;MMP=barney.mmp;BLDINF=somebld.inf;|echo "Started a slow command under talon (attempt $$TALON_ATTEMPT):";echo "SHELL=$$SHELL";if (( $$TALON_ATTEMPT <4 )); then echo sleeping 6; sleep 6; echo "hi"; else echo "Not sleeping this time"; fi; echo "this should not appear in the recipe tags unless you try 4 times."

