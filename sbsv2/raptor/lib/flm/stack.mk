#
# Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# # Implements a stack mechanism for FLMS
# # Author: Timothy Murphy
# # CHANGE THIS FILE AT YOUR PERIL! :-)
# # It is very sensitive to spaces on the end of variables.
# # It took a lot of trouble to get this exactly right so 
# # be careful about changing it.
# # A "call stack" is necessary for variables which are used
# # in an append-manner by glue makefiles.  This behavior
# # is only needed where and FLM call has the form:
# # 	OUTPUTPATH:=$(OUTPUTPATH)/subdir
# #	include $(FLMHOME)/exefile.flm
# # This is because the outputpath setting must be undone
# # before the next call to an FLM that uses OUTPUTPATH (otherwise it keeps growing)
# # USAGE:
# # $(call vsave,VARIABLE1 VARIABLE2)
# # $(call vrestore)
#

ifeq ($(VARIABLE_STACK_NAME),)
VARIABLE_STACK_NAME:=STACK
endif
# $(1) should list the variables 

# vadd must be exactly of the form of 3 lines, the middle one containing "$(1)"
# Otherwise the extra return will be treated like a character rather than as whitespace

define LINEFEED


endef

define vadd
$(1):=$(2)

endef

#
# Create a kind of stack "frame"
# The parameters are names of variables whose values are to be stored in the frame
# so that these values may be restored later.
#
# use thus:
# $(call vsave,OUTPUTPATH SOURCEPATH CDEFS)
#
define vsave
$(eval 
VARIABLE_STACK_NAME:=$(VARIABLE_STACK_NAME).F
$$(VARIABLE_STACK_NAME):=$$(foreach VAR,$(1),$$(call vadd,$$(VAR),$$($$(VAR)))))
endef

#
# Pop the top stack frame.
#
# use thus:
# $(call vrestore)
#
define vrestore
$(eval $($(VARIABLE_STACK_NAME))
VARIABLE_STACK_NAME:=$(patsubst %.F,%,$(VARIABLE_STACK_NAME))
)
endef

