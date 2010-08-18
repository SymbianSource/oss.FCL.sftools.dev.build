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
# Makefile that demonstrates the effect of state saving macros
# when used across multiple FLM calls

#
# basically for testing the stack.mk amkefile fragmemt
# Which chould be inluded by flmtools.mk
#


.PHONY: stack-debug

OUTPUTPATH:=_PRE_OUTPUTPATH_
SOURCEPATH:=_PRE_SOURCEPATH_

COMMA:= ,
EMPTY:=
SPACE:= $(EMPTY) $(EMPTY)


include $(FLMHOME)/flmtools.mk

OUTPUTPATH:=ORIGINAL_OUTPUTPATH OP2 OP3
SOURCEPATH:=ORIGINAL_SOURCEPATH SP2 SP3

###############################################################################
# Rules for testing
.PHONY: all

all: stack-debug stack-debug2 stack-debug3
	@echo "FLM stack TEST SUCCEEDED"

.PHONY: stack-debug
stack-debug: VARIABLE_STACK_NAME:=$(VARIABLE_STACK_NAME)
stack-debug: OUTPUTPATH:=$(OUTPUTPATH)
stack-debug: SOURCEPATH:=$(SOURCEPATH)

stack-debug:
	@echo NAME=\"$(VARIABLE_STACK_NAME)\"
	@echo "	Stack Name: \"$(VARIABLE_STACK_NAME)\""
	@echo "	Stack contents: \"$($(VARIABLE_STACK_NAME)$)\""
	@echo "Original Parameters iprior to 'FLM Call': "
	@echo "	OUTPUTPATH: "$(OUTPUTPATH)
	@echo "	SOURCEPATH: "$(SOURCEPATH)
	[ "$(OUTPUTPATH)" == "ORIGINAL_OUTPUTPATH OP2 OP3" ]
	[ "$(SOURCEPATH)" == "ORIGINAL_SOURCEPATH SP2 SP3" ]


$(call vsave,OUTPUTPATH SOURCEPATH)
OUTPUTPATH:=MODIFIED OUTPUTPATH
SOURCEPATH:=MODIFIED OUTPUTPATH



.PHONY: stack-debug2
stack-debug2: VARIABLE_STACK_NAME:=$(VARIABLE_STACK_NAME)
stack-debug2: OUTPUTPATH:=$(OUTPUTPATH)
stack-debug2: SOURCEPATH:=$(SOURCEPATH)
stack-debug2:
	@echo "--------------------"
	@echo "	Stack Name: \"$(VARIABLE_STACK_NAME)\""
	@echo "Parameters after 'FLM Call': "
	@echo "	OUTPUTPATH: "$(OUTPUTPATH)
	@echo "	SOURCEPATH: "$(SOURCEPATH)
	[ "$(OUTPUTPATH)" == "MODIFIED OUTPUTPATH" ]
	[ "$(SOURCEPATH)" == "MODIFIED OUTPUTPATH" ]


$(call vrestore)


.PHONY: stack-debug3
stack-debug3: VARIABLE_STACK_NAME:=$(VARIABLE_STACK_NAME)
stack-debug3: OUTPUTPATH:=$(OUTPUTPATH)
stack-debug3: SOURCEPATH:=$(SOURCEPATH)
stack-debug3:
	@echo "--------------------"
	@echo "	Stack Name: \"$(VARIABLE_STACK_NAME)\""
	@echo "Parameters after restore: "
	@echo "	OUTPUTPATH: "$(OUTPUTPATH)
	@echo "	SOURCEPATH: "$(SOURCEPATH)
	[ "$(OUTPUTPATH)" == "ORIGINAL_OUTPUTPATH OP2 OP3" ]
	[ "$(SOURCEPATH)" == "ORIGINAL_SOURCEPATH SP2 SP3" ]
