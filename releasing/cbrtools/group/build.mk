# Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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
#
# Description:
# Extension Makefile for creating the CBR tools installable package
#

# Constants
TOOLS_DIR = $(EPOCROOT)tools
WORK_DIR = $(EPOCROOT)temp\cbr
SRC_DIR = ..\perl
CUR_DIR = $(shell chdir)
include version.mk

# Targets

do_nothing: 
	rem do_nothing

MAKMAKE : do_nothing

RESOURCE : do_nothing

FREEZE : do_nothing

SAVESPACE : BLD

LIB: do_nothing

RELEASABLES :
ifeq ("$(PLATFORM) $(CFG)", "TOOLS REL")
	@echo $(TOOLS_DIR)\cbr\cbrtools$(VERSION).zip	
endif


# remove jar file and class files
CLEAN :
ifeq ("$(PLATFORM) $(CFG)", "TOOLS REL")
	-del $(TOOLS_DIR)\cbr\cbrtools$(VERSION).zip	
	-rmdir /s/q $(WORK_DIR)
endif

# Called with
#
# $(PLATFORM) = TOOLS
# $(CFG)      = DEB, REL

# Note: DISTRIBUTION.POLICY files are only shipped with the example 

BLD	:  
	@echo BLD called with $(PLATFORM) $(CFG)
ifeq ("$(PLATFORM) $(CFG)", "TOOLS REL")
	-rmdir /S/Q $(WORK_DIR)
	-mkdir $(TOOLS_DIR)\cbr
	-del $(TOOLS_DIR)\cbr\cbrtools$(VERSION).zip	
	-mkdir $(WORK_DIR)
	xcopy /EI $(SRC_DIR) $(WORK_DIR)	
	cd $(WORK_DIR); zip -9r $(TOOLS_DIR)\cbr\cbrtools$(VERSION).zip *	
	-rmdir /S/Q $(WORK_DIR)
endif

FINAL : do_nothing
