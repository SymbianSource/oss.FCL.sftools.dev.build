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


# Macros for creating Standard targets

ifeq ($(_METAFLM_MK_),)
_METAFLM_MK_:=1

## path creation #########################
# Make the destination directory if neccessary.  For some
# make engines we must do this outside the rule or they
# get confused by the apparent way in which different rules
# can create a particular directory and they infer some kind
# of dependency.

# Makepath. Copyright (C) 2008 Symbian Software Ltd.
# buffering with repeat prevention, makes directories after every 30 calls. Any more might overload 
# the createprocess limit on arguments.
#
# makepathLIST is initialised in globals.mk
define makepath_single
$(if $(findstring $1,$(makepathLIST)),,$(eval makepathLIST:=$(makepathLIST) $1))
$(if $(subst 90,,$(words $(makepathLIST))),,$(shell $(GNUMKDIR) -p $(makepathLIST))$(eval makepathLIST:=))
endef

# The following turns out to be extremely slow - something to do with using eval 
# or to do with creating huge numbers of TARGET_ variables? BTW, this is an attempt
# to not make things that we have already made.
# define makepath
# $(info makepath_start)$(foreach DIR,$1,$(if $(TARGET_$(1)),,$(call makepath_single,$(DIR))$(eval TARGET_$(1):=1)))$(info makepath_end)
# endef

# In general, makepath creates directories during FLM evaluation.
# However, if the WHAT target is being processed then it should do nothing.
define makepath
$(strip $(foreach DIR,$(sort $1),$(call makepath_single,$(DIR))))
endef


define makepathfor
$(call makepath,$(dir $1))
endef

# Make any remaining paths in the path buffer
define makepathfinalise
$(strip $(if $(makepathLIST),$(shell $(GNUMKDIR) $(makepathLIST))$(eval makepathLIST:=),))
endef

## END TEST BATCH FILES MACRO
