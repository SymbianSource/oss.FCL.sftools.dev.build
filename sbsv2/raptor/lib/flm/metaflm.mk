#
# Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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

# GENERATE STANDARD CLEAN TARGET 
# example usage:
# $(eval $(call GenerateStandardCleanTarget,$(FILE_LIST),$(DIRECTORY_LIST)))

## CLEAN macros #####################################
# The clean macro does not generate a target but extension makefiles do have
# CLEAN targets that need to be attached to something.
.PHONY:: CLEAN

define GenerateStandardCleanTarget
$(info <clean bldinf='$(COMPONENT_META)' mmp='$(PROJECT_META)' config='$(SBS_CONFIGURATION)'>)
$(foreach ITEM,$(1),$(info <file>$(ITEM)</file>))
$(foreach ITEM,$(2),$(info <dir>$(ITEM)</dir>))
$(info </clean>)
endef

## End CLEAN macros #####################################


## WHAT macros #####################################


## Begin --what Macros #####
define outputWhat
ifeq ($(OSTYPE),cygwin)
$(2)::
	@for FILE in $(subst %20,$(CHAR_SPACE),$(subst /,\\,$(call dblquote,$(1)))); do \
		echo $$$$FILE; \
	done;
else
$(2)::
	@for FILE in $(subst %20,$(CHAR_SPACE),$(1)); do \
		echo $$$$FILE; \
	done
endif
endef

## End --what Macros #####

## Begin .whatlog Macros #####
define whatLogOpen
<whatlog bldinf='$(COMPONENT_META)' mmp='$(PROJECT_META)' config='$(SBS_CONFIGURATION)'>
endef

define whatLogItem
$(if $(findstring EXPORT,$(1)),<export ,$(if $(findstring RESOURCE,$(1)),<resource>,$(if $(findstring BITMAP,$(1)),<bitmap>,$(if $(findstring STRINGTABLE,$(1)),<stringtable>,$(if $(findstring ARCHIVE,$(1)),<member>,<build>)))))$(subst %20,$(CHAR_SPACE),$(2))$(if $(findstring EXPORT,$(1)),/>,$(if $(findstring RESOURCE,$(1)),</resource>,$(if $(findstring BITMAP,$(1)),</bitmap>,$(if $(findstring STRINGTABLE,$(1)),</stringtable>,$(if $(findstring ARCHIVE,$(1)),</member>,</build>)))))
endef

define whatLogClose
</whatlog>
endef

define outputWhatLog
$(info $(call whatLogOpen))
$(foreach ITEM,$(1),$(info $(call whatLogItem,$(2),$(ITEM))))
$(info $(call whatLogClose))
endef

## End .whatlog Macros #####

# General FLM entry points for what-related processing
define WhatExports
endef

define whatmacro
$(call outputWhatLog,$(1),$(2))
endef

define whatUnzip
endef	
## END WHAT UNZIP MACRO 

## End WHAT macros #####################################

# Macro for creating the test BATCH files.
# Arguments: $(1) -> Target Name $(2) -> Output Batch file path
define MakeTestBatchFiles
    $(if $(BATCHFILE_CREATED_$(2))
        ,
            $(if $(TARGET_CREATED_$(2)_$(TARGET))
                ,
                ,
                    $$(shell echo -e "$(1)\r" >> $(2))
            )
       	,
       	    $$(shell $(GNUMKDIR) -p $(dir $(2)))
       	    $$(shell echo -e "$(1)\r" > $(2))
    )
endef

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
$(if $(subst 30,,$(words $(makepathLIST))),,$(shell $(GNUMKDIR) -p $(makepathLIST))$(eval makepathLIST:=))
endef

# The following turns out to be extremely slow - something to do with using eval 
# or to do with creating huge numbers of TARGET_ variables? BTW, this is an attempt
# to not make things that we have already made.
# define makepath
# $(info makepath_start)$(foreach DIR,$1,$(if $(TARGET_$(1)),,$(call makepath_single,$(DIR))$(eval TARGET_$(1):=1)))$(info makepath_end)
# endef

# In general, makepath creates directories during FLM evaluation.
# However, if the WHAT target is being processed then it should do nothing.
ifeq ($(filter WHAT,$(call uppercase,$(MAKECMDGOALS))),)
define makepath
$(strip $(foreach DIR,$(sort $1),$(call makepath_single,$(DIR))))
endef
else
define makepath
endef
endif


define makepathfor
$(call makepath,$(dir $1))
endef

# Make any remaining paths in the path buffer
define makepathfinalise
$(strip $(if $(makepathLIST),$(shell $(GNUMKDIR) -p $(makepathLIST))$(eval makepathLIST:=),))
endef

## ROMFILE macro #####################################
define DoRomSet

ifeq ($(call uppercase,$(TARGETTYPE)),LIB)
BUILDROMTARGET:=
endif

ifeq ($(call uppercase,$(TARGETTYPE)),KEXT)
ROMFILETYPE:=extension[MAGIC]
ABIDIR:=KMAIN
endif
ifeq ($(call uppercase,$(TARGETTYPE)),LDD)
ROMFILETYPE:=device[MAGIC]
ABIDIR:=KMAIN
endif
ifeq ($(call uppercase,$(TARGETTYPE)),PDD)
ROMFILETYPE:=device[MAGIC]
ABIDIR:=KMAIN
endif
ifeq ($(call uppercase,$(TARGETTYPE)),VAR)
ROMFILETYPE:=variant[MAGIC]
ABIDIR:=KMAIN
endif
ifeq ($(call uppercase,$(TARGETTYPE)),KDLL)
ABIDIR:=KMAIN
endif

ifneq ($(CALLDLLENTRYPOINTS),)
ROMFILETYPE:=dll
endif
ifeq ($(ROMFILETYPE),primary)
ABIDIR:=KMAIN
endif

endef

## End of ROMFILE macro ##############################

## Macros for writing FLMs without needing to know eval

# declaring targets as RELEASABLE, for example,
#
# $(call raptor_release,$(TARGET1) $(TARGET2),RESOURCE)
#
# the optional type (RESOURCE) can be one of,
# EXPORT RESOURCE BITMAP STRINGTABLE ARCHIVE
#
# no argument means just a default (binary) releasable.
#
define raptor_release
$(eval $(call outputWhatLog,$1,$2))
endef

# declaring things that need to be cleaned.
#
# any files which are generated but are not RELEASABLE should be listed
# using this macro, for example,
#
# $(call raptor_clean,$(OBJECT_FILES))
#
define raptor_clean
$(eval $(call GenerateStandardCleanTarget,$1))
endef

endif 
# end of metaflm
## END TEST BATCH FILES MACRO
