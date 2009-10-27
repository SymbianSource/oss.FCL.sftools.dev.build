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
# ARMv5 e32 postlinking FLM
# Knows how to postlink all possible ABIV2 executables for ARM
#

# Interface
#
#  Metadata supplied (or deduced from)
#
#   BYTEPAIRCOMPRESS
#   CAPABILITY
#   DEBUGGABLE                     Can be "udeb" or "urel" or "udeb urel" or ""
#   E32TARGET
#   EPOCALLOWDLLDATA
#   EPOCFIXEDPROCESS
#   EPOCHEAPSIZEMAX
#   EPOCHEAPSIZEMIN
#   EPOCPROCESSPRIORITY
#   EPOCSTACKSIZE
#   EXPORTUNFROZEN
#   INFLATECOMPRESS
#   POSTLINKFPU
#   POSTLINKTARGETTYPE
#   SID
#   SMPSAFE
#   UID2
#   UID3
#   VERSION
#   VENDORID
#
#  Other
#
#   ARMLIBS
#   AUTOEXPORTS                    Symbols that must be assumed to exist for this TARGETTYPE in the format: export,ordinal;export,ordinal;..
#   CANIGNORENONCALLABLE           If the TARGETTYPE allows it, disregard non-callable exports (v-tables, type information, etc.)
#   CANHAVEEXPORTS
#   CLEANTARGETS
#   ELF2E32
#   EPOCDATALINKADDRESS            Redundant?
#   EPOCROOT
#   EXPTARGET
#   GENERATED_DEFFILE
#   GENERATED_DSO
#   HAVE_ORDERONLY
#   IMPORTLIBRARYREQUIRED
#   INTERMEDIATEPATH
#   LINKASVERSIONED
#   LINK_TARGET                    Postlinker elf input
#   NAMEDSYMLKUP
#   PAGEDCODE_OPTION
#   POSTLINKDEFFILE
#   POSTLINKER_SUPPORTS_WDP
#   RUNTIME_LIBS_PATH
#   SAVESPACE
#   STATIC_LIBS_PATH
#   UID1
#   VARIANTTYPE


# Capabilities
ADDED_CAPABILITIES:=$(subst $(CHAR_SPACE),+,$(filter-out -%,$(CAPABILITY)))
SUBTRACTED_CAPABILITIES:=$(subst $(CHAR_SPACE),,$(filter -%,$(CAPABILITY)))
FINAL_CAPABILITIES:=$(if $(ADDED_CAPABILITIES),$(ADDED_CAPABILITIES)$(SUBTRACTED_CAPABILITIES),NONE)

# Paging options for the old postlinker
POSTLINKER_PAGEDOPTION:=--defaultpaged
ifeq ($(PAGED),1)
  POSTLINKER_PAGEDOPTION:=--paged
endif
ifeq ($(PAGED),0)
  POSTLINKER_PAGEDOPTION:--unpaged
endif

# Postlink target
define e32postlink
$(E32TARGET): $(LINK_TARGET) $(POSTLINKDEFFILE) $(ELF2E32) $(if $(HAVE_ORDERONLY),|,) $(EPOCROOT)/epoc32/build/TEM_LIB
	$(call startrule,postlink) \
	$(ELF2E32) \
	  --sid=0x$(if $(SID),$(SID),$(if $(UID3),$(UID3),0)) \
	  --version=$(VERSION) \
	  --capability=$(FINAL_CAPABILITIES) \
	  --linkas=$(call dblquote,$(LINKASVERSIONED)) \
	  --fpu=$(POSTLINKFPU) \
	  --targettype=$(POSTLINKTARGETTYPE) \
	  --output=$$(call dblquote,$$@) \
	  --elfinput=$(call dblquote,$(LINK_TARGET)) \
	  $(if $(UID1),--uid1=0x$(UID1),) \
	  $(if $(UID2),--uid2=0x$(UID2),) \
	  $(if $(UID3),--uid3=0x$(UID3),) \
	  $(if $(VENDORID),--vid=0x$(VENDORID),) \
	  $(if $(EXPTARGET),--customdlltarget,) \
	  $(if $(ARMLIBS),--excludeunwantedexports,) \
	  $(if $(EPOCALLOWDLLDATA),--dlldata,) \
	  $(if $(EPOCPROCESSPRIORITY),--priority=$(EPOCPROCESSPRIORITY),) \
	  $(if $(EPOCSTACKSIZE),--stack=0x$(EPOCSTACKSIZE),) \
	  $(if $(EPOCHEAPSIZEMIN),--heap=0x$(EPOCHEAPSIZEMIN)$(CHAR_COMMA)0x$(EPOCHEAPSIZEMAX),) \
	  $(if $(EPOCFIXEDPROCESS),--fixedaddress,) \
	  $(if $(EPOCDATALINKADDRESS),--datalinkaddress=$(EPOCDATALINKADDRESS),) \
	  $(if $(NAMEDSYMLKUP),--namedlookup,) \
	  $(if $(SMPSAFE),--smpsafe,) \
	  $(if $(POSTLINKDEFFILE),--definput=$(POSTLINKDEFFILE),) \
	  $(if $(EXPORTUNFROZEN),--unfrozen,) \
	  $(if $(AUTOEXPORTS),--sysdef=$(call dblquote,$(AUTOEXPORTS)),) \
	  $(if $(CANIGNORENONCALLABLE), \
	    $(if $(IMPORTLIBRARYREQUIRED),,--ignorenoncallable),) \
	  $(if $(CANHAVEEXPORTS), --defoutput="$(GENERATED_DEFFILE)" --dso=$(GENERATED_DSO)) \
	  $(if $(filter $(VARIANTTYPE),$(DEBUGGABLE)),--debuggable,) \
	  $(if $(POSTLINKER_SUPPORTS_WDP), \
	    --codepaging=$(PAGEDCODE_OPTION) --datapaging=$(PAGEDDATA_OPTION), \
	    $(POSTLINKER_PAGEDOPTION)) \
	  $(if $(NOCOMPRESSTARGET), \
	    --uncompressed, \
	    $(if $(INFLATECOMPRESS),--compressionmethod inflate,$(if $(BYTEPAIRCOMPRESS),--compressionmethod bytepair,))) \
	  --libpath="$(call concat,$(PATHSEP)$(CHAR_SEMIC),$(strip $(RUNTIME_LIBS_PATH) $(STATIC_LIBS_PATH)))" \
	  $(if $(SAVESPACE),$(if $(EXPORTUNFROZEN),,;$(GNURM) -rf $(INTERMEDIATEPATH); true)) \
	$(call endrule,postlink)
endef
$(eval $(e32postlink))

CLEANTARGETS:=$(CLEANTARGETS) $(E32TARGET)
CLEANTARGETS:=$(CLEANTARGETS) $(GENERATED_DEFFILE)
CLEANTARGETS:=$(CLEANTARGETS) $(GENERATED_DSO)
