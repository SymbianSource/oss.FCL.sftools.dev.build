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
# global include file : this is included by all generated makefiles
# 1) include all the common tools
# 2) add global targets such as CLEAN and REALLYCLEAN
# 3) specify the top level dependencies between targets
# INPUTS : assumes OSTYPE and FLMHOME are set.
#

ifeq ($(SYMBIAN_FLM_GLOBALS_MK),)
SYMBIAN_FLM_GLOBALS_MK:=1

# get the common tools
include $(FLMHOME)/flmtools.mk

# initialise the list of created directories
makepathLIST:=

# set the variables TOOLPLATFORMDIR and DOTEXE
ifeq ($(filter win,$(HOSTPLATFORM)),win)
DOTEXE:=.exe
TOOLPLATFORMDIR:=
else
DOTEXE:=
TOOLPLATFORMDIR:=/$(HOSTPLATFORM_DIR)
endif

# addglobal(GlobalTargetName)
SYMBIAN_GLOBAL_TARGETS:=

define sgt_addcmds
.PHONY:: $1

$(if $(filter win,$(HOSTPLATFORM)),,$(call lowercase,$1):: $1)

SYMBIAN_GLOBAL_TARGETS:=$$(SYMBIAN_GLOBAL_TARGETS) $(1)
endef

define addglobal
$(eval $(call sgt_addcmds,$(1)))
endef

ALLTARGET:=ALL

.PHONY:: $(ALLTARGET)
$(ALLTARGET):: BUILD

# Global targets should generally be double colon rules because
# they allow horizontal states to be placed into the build system.
# e.g the "EXPORTED" state.
$(call addglobal,BUILD)
$(call addglobal,CLEAN)
$(call addglobal,CLEANEXPORT)
$(call addglobal,EXPORT)
$(call addglobal,FINAL)
$(call addglobal,FREEZE)
$(call addglobal,LIBRARY)
$(call addglobal,LISTING)
$(call addglobal,MAKEFILE)
$(call addglobal,REALLYCLEAN)
$(call addglobal,BITMAP)
$(call addglobal,RESOURCE)
$(call addglobal,ROMFILE)
$(call addglobal,TARGET)
$(call addglobal,WHAT)
$(call addglobal,WHATEXPORTS)
$(call addglobal,WHATARMV5)
$(call addglobal,WHATWINSCW)
$(call addglobal,WHATTOOLS2)
$(call addglobal,WHATTOOLS)
$(call addglobal,WHATTEM)
$(call addglobal,WHATRESOURCES)
$(call addglobal,WHATBITMAP)
$(call addglobal,WHATGNUEM)
$(call addglobal,WHATSTRINGTABLE)

# Ignore errors in some rules so as to "keep going"
# so if one export fails then that won't stop unrelated
# .cpp files from building. (.cpp files must all depend on EXPORT
# so that parallel builds work)
.IGNORE: EXPORT BITMAP RESOURCE LIBRARY
# dependencies between top-level targets
BUILD:: EXPORT MAKEFILE BITMAP RESOURCE LIBRARY TARGET FINAL

MAKEFILE:: EXPORT
BITMAP:: MAKEFILE
RESOURCE:: BITMAP
LIBRARY:: RESOURCE 
TARGET:: LIBRARY
FINAL:: TARGET

.PHONY:: EXPORT


WHAT:: WHATEXPORTS WHATARMV5 WHATWINSCW WHATTOOLS2 WHATTEM WHATGNUEM WHATRESOURCES WHATBITMAP WHATSTRINGTABLE

REALLYCLEAN:: CLEAN CLEANEXPORT

# Create one of every double colon rule
WHATBITMAP::

WHATRESOURCES::

WHATSTRINGTABLE::

WHATTEM::

WHATGNUEM::

WHATTOOLS2::

WHATWINSCW::

WHATARMV5::

WHATEXPORTS::

LISTING::

CLEAN::

CLEANEXPORT::

REALLYCLEAN::

EXPORT::

RESOURCE::

BITMAP::

# put known resource header to resource header dependencies here

eikcdlg_DEPENDS:=eikcore.rsg eikcoctl.rsg
eikmisc_DEPENDS:=eikcore.rsg
eikfile_DEPENDS:=eikcoctl.rsg
eikir_DEPENDS:=eikcoctl.rsg
eikprint_DEPENDS:=eikcoctl.rsg


# For users of SBSv2 who wish to add in their own global settings
# without modifying this file:
-include $(FLMHOME)/user/globals.mk

endif

