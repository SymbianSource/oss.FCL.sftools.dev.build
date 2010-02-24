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

TALON_RECIPEATTRIBUTES:=name='$$RECIPENAME' host='$$HOSTNAME'
export TALON_RECIPEATTRIBUTES 


$(info SHELL="$(SHELL)")

# using an override doesn't i.e. "make SHELL:=xxxx" fails on windows at least.
# so one can try "make TALON:=xxxx" and in the makefile one must set SHELL=$(TALON)

all: hello world

hello:
	@echo "some output" 
	@|RECIPENAME=hello;|echo "The recipe name is $$RECIPENAME"


world:
	@echo "more output" 
	@|RECIPENAME=world;|echo "The recipe name is $$RECIPENAME"

