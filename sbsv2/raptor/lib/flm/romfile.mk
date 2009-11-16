# romfile.mk
#
# Copyright (c) 2008 : Symbian Software Limited. All rights reserved.
#
# define macros that are needed by romfile creation

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


