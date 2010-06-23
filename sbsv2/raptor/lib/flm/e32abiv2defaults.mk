#
# Copyright (c) 2007-2010 Nokia Corporation and/or its subsidiary(-ies).
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
# e32abiv2defaults.flm
# ARMv5 EXE/DLL ABIv2 Function Like Makefile (FLM)
#

# This is for variables that are not set in an FLM call but
# only in e32abiv2 flms.  

AUTOEXPORTS:=
CANHAVEEXPORTS:=
CANIGNORENONCALLABLE:=
DOPOSTLINK:=
IMPORTLIBRARYREQUIRED:=
LINKER_ENTRYPOINT_LIBDEP:=
LINKER_ENTRYPOINT_SETTING:=
LINKER_STUB_LIBRARY:=
NAMEDSYMLKUP:=
POSTLINKDEFFILE:=
POSTLINKFILETYPE:=
POSTLINKTARGETTYPE:=
STATIC_RUNTIME_LIB:=
SUPPORT_FREEZE:=
NOHIDEALL:=
DEFAULT_NEWLIB:=$(DEFAULT_SYMBIAN_NEWLIB)


# Reset these variables as they change for every single target type
# LINKER_ENTRYPOINT_ADORNMENT will be blank for GCCE; for RVCT it will look like "(uc_exe_.o)"
# LINKER_ENTRYPOINT_DECORATION will be blank for RVCT; for GCCE it will look like "-u _E32Startup"
# LINKER_SEPARATOR is a comma for GCCE as g++ is used for linking; for RVCT is should be a space, but
# as make strips trailing spaces, we use the CHAR_SPACE variable.

LINKER_ENTRYPOINT_ADORNMENT:=
LINKER_ENTRYPOINT_DECORATION:=
LINKER_SEPARATOR:=

# For GCCE
ifeq ($(TOOLCHAIN),GCCE)
LINKER_ENTRYPOINT_DECORATION:=$(if $(call isoneof,$(TARGETTYPE),exexp exe),-Wl$(CHAR_COMMA)-u$(CHAR_COMMA)_E32Startup,-Wl$(CHAR_COMMA)-u$(CHAR_COMMA)_E32Dll)
LINKER_SEPARATOR:=$(CHAR_COMMA)
endif

# For RVCT
ifeq ($(TOOLCHAIN),RVCT)
  ifeq ($(call isoneof,$(TARGETTYPE),exe stdexe),1) # isoneof returns 1 if true, empty string if false
	LINKER_ENTRYPOINT_ADORNMENT:=(uc_exe_.o)
  endif

  ifeq ($(call isoneof,$(TARGETTYPE),ani textnotifier2 stddll plugin plugin3 fsy pdl dll pdll),1)
	LINKER_ENTRYPOINT_ADORNMENT:=(uc_dll_.o)
  endif

  ifeq ($(call isoneof,$(TARGETTYPE),var var2),1)
	LINKER_ENTRYPOINT_ADORNMENT:=(v_entry_.o)
  endif

  ifeq ($(call isoneof,$(TARGETTYPE),ldd pdd),1)
	LINKER_ENTRYPOINT_ADORNMENT:=(D_ENTRY_.o)
  endif

  ifeq ($(TARGETTYPE),kext)
	LINKER_ENTRYPOINT_ADORNMENT:=(X_ENTRY_.o)
  endif

  ifeq ($(TARGETTYPE),kdll)
	LINKER_ENTRYPOINT_ADORNMENT:=(L_ENTRY_.o)
  endif
LINKER_SEPARATOR:=$(CHAR_SPACE)
endif

# "OPTION" metadata from the front-end can potentially be supplied simultaneously for both GCCE and RVCT,
# so we need to make a decision on what we make use of based on the TOOLCHAIN in use.
# Currently we only support changes to RVCT tool calls.

LINKEROPTION:=
OPTION_COMPILER:=
OPTION_REPLACE_COMPILER:=

ifeq ($(TOOLCHAIN),RVCT)
  LINKEROPTION:=$(LINKEROPTION_ARMCC)
  OPTION_COMPILER:=$(OPTION_ARMCC)
  OPTION_REPLACE_COMPILER:=$(OPTION_REPLACE_ARMCC)
endif

# "ARMFPU" overrides for 'fpu-ness' in compiler and postlinker calls in .mmp files are currently only
# supported for RVCT-based builds, GCCE builds always make use of the interface defined defaults.
ifeq ($(TOOLCHAIN),GCCE)
  ARMFPU:=
endif
