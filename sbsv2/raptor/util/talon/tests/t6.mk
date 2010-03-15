#
# Copyright (c) 2009-2010 Nokia Corporation and/or its subsidiary(-ies).
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
include settings.mk

# Making sure that forcesuccess works.

TALON_RECIPEATTRIBUTES:=flags='$$TALON_FLAGS'
TALON_RETRIES:=1

export TALON_RECIPEATTRIBUTES TALON_RETRIES

.PHONY: all fred

all: fred
	@echo "t6-PASSED"
	
fred:
	|TALON_FLAGS=FORCESUCCESS;|echo "Forcesuccess'd command"; exit 1


