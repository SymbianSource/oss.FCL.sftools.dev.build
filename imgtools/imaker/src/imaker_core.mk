#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Symbian Foundation License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.symbianfoundation.org/legal/sfl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description: iMaker Core image configuration
#



###############################################################################
#   ___ ___  ___ ___
#  / __/ _ \| _ \ __|
# | (_| (_) |   / _|
#  \___\___/|_|_\___|
#

USE_NOROMHDR = 0

CORE_TITLE       = Core (ROM$(call iif,$(USE_ROFS1), & ROFS1))
CORE_DIR         = $(WORKDIR)/core
CORE_NAME        = $(NAME)
CORE_PREFIX      = $(CORE_DIR)/$(CORE_NAME)
CORE_IDIR        =
CORE_HBY         =
CORE_OBY         =
CORE_OPT         =
CORE_MSTOBY      = $(CORE_PREFIX)_core_master.oby
CORE_HEADER      =
CORE_INLINE      =
CORE_TIME        = $(DAY)/$(MONTH)/$(YEAR)

CORE_OBYGEN      =

CORE_VERIBY      = $(CORE_PREFIX)_core_version.iby
CORE_ROMVER      = 0.01(0)
CORE_VERSION     = V $(subst .,,$(COREPLAT_VERSION)).$(subst .,,$(S60_VERSION)).$(BUILD_YEAR).$(BUILD_WEEK).$(BUILD_NUMBER)$(if $(TYPE), $(call ucase,$(TYPE)))
CORE_SWVERFILE   = $(CORE_PREFIX)_core_sw.txt
CORE_SWVERINFO   = $(CORE_VERSION)\\\n$(DAY)-$(MONTH)-$(YEAR2)\\\n$(PRODUCT_TYPE)\\\n(c) $(PRODUCT_MANUFACT)
CORE_MODELFILE   = $(CORE_PREFIX)_core_model.txt
CORE_MODELINFO   = S60
CORE_IMEISVFILE  = $(CORE_PREFIX)_core_imeisv.txt
CORE_IMEISVINFO  = 00
CORE_PLATFILE    = $(CORE_PREFIX)_core_platform.txt
CORE_PLATINFO    = SymbianOSMajorVersion=$(word 1,$(subst ., ,$(SOS_VERSION)))\nSymbianOSMinorVersion=$(word 2,$(subst ., ,$(SOS_VERSION)))\n
CORE_PRODFILE    = $(CORE_PREFIX)_core_product.txt
CORE_PRODINFO    = Manufacturer=$(PRODUCT_MANUFACT)\nModel=$(PRODUCT_MODEL)\nProduct=$(PRODUCT_TYPE)\nRevision=$(PRODUCT_REVISION)
CORE_FWIDFILE    = $(CORE_PREFIX)_core_fwid.txt
CORE_FWID        = core
CORE_FWIDVER     = $(CORE_VERSION) $(PRODUCT_TYPE)
CORE_FWIDINFO    = id=$(CORE_FWID)\nversion=$(CORE_FWIDVER)\n

CORE_PLUGINLOG   = $(CORE_PREFIX)_core_bldromplugin.log
CORE_NDPROMFILE  = $(E32ROMBLD)/romfiles.txt
CORE_ODPROMFILE  = $(E32ROMBLD)/odpromfiles.txt
CORE_CDPROMFILE  = $(E32ROMBLD)/odpcoderomfiles.txt
CORE_ROMFILE     = $(call iif,$(USE_PAGING),$(if $(filter 1,$(USE_PAGEDCODE)),$(CORE_CDPROMFILE),$(CORE_ODPROMFILE)),$(CORE_NDPROMFILE))
CORE_NDPROFSFILE = $(E32ROMBLD)/rofsfiles.txt
CORE_ODPROFSFILE = $(E32ROMBLD)/odprofsfiles.txt
CORE_CDPROFSFILE = $(E32ROMBLD)/odpcoderofsfiles.txt
CORE_ROFSFILE    = $(call iif,$(USE_PAGING),$(if $(filter 1,$(USE_PAGEDCODE)),$(CORE_CDPROFSFILE),$(CORE_ODPROFSFILE)),$(CORE_NDPROFSFILE))
CORE_PAGEFILE    = $(ODP_PAGEFILE)
CORE_UDEBFILE    = $(TRACE_UDEBFILE)

CORE_ICHKLOG     = $(CORE_PREFIX)_core_imgcheck.log
CORE_ICHKOPT     = $(IMGCHK_OPT)
CORE_ICHKIMG     = $(ROM_IMG) $(call iif,$(USE_ROFS1),$(ROFS1_IMG))

CORE_I2FDIR      = $(CORE_DIR)/img2file

#==============================================================================

ROM_BUILDOPT   = $(call iif,$(USE_NOROMHDR),-no-header)
ROM_CHECKSUM   = 0x12345678
ROM_IMGHDRSIZE = 256
ROM_HEADER     =
ROM_FOOTER     =

ROM_IMG        = $(CORE_PREFIX).rom.img
ROM_INC        = $(CORE_PREFIX).rom.inc
ROM_LOG        = $(CORE_PREFIX).rom.log
ROM_OUTOBY     = $(CORE_PREFIX).rom.oby
ROM_SYM        = $(CORE_PREFIX).rom.symbol

ROFS1_HEADER   =
ROFS1_IMG      = $(CORE_PREFIX).rofs1.img
ROFS1_LOG      = $(CORE_PREFIX).rofs1.log
ROFS1_OUTOBY   = $(CORE_PREFIX).rofs1.oby
ROFS1_SYM      = $(CORE_PREFIX).rofs1.symbol

#==============================================================================

define CORE_MSTOBYINFO
  $(BLDROM_HDRINFO)

  $(BLDROM_PLUGINFO)

  // Core header
  //
  $(CORE_HDRINFO)

  // Core ROM
  //
  ROM_IMAGE[0] {
    $(ROM_HDRINFO)
    $(BLR.CORE.OBY)
    $(CORE_INLINE)
    $(ROM_FOOTERINFO)
  }
  $(call iif,$(USE_ROFS1),

    // Core ROFS1
    //
    ROM_IMAGE 1 rofs1 non-xip size=$(ROFS_MAXSIZE)

    ROM_IMAGE[1] {
      $(ROFS1_HDRINFO)
      // Content to be moved from ROM to ROFS1
    }
  )
endef

define CORE_HDRINFO
  $(DEFINE) _IMAGE_WORKDIR $(CORE_DIR)
  $(call mac2cppdef,$(BLR.CORE.OPT))
  $(BLR.CORE.HBY)
  $(CORE_HEADER)
  $(if $(filter 1,$(USE_VARIANTBLD)),$(VARIANT_HEADER))
endef

define ROM_HDRINFO
  $(ODP_ROMINFO)
  $(ROM_HEADER)
endef

define ROM_FOOTERINFO
  $(if $(ROM_BUILDOPT),ROMBUILD_OPTION $(ROM_BUILDOPT))
  romname $(notdir $(ROM_IMG))
  $(if $(CORE_TIME),time=$(CORE_TIME))
  $(if $(ROM_CHECKSUM),romchecksum=$(ROM_CHECKSUM))
  $(ROM_FOOTER)
endef

define ROFS1_HDRINFO
  $(call ODP_CODEINFO,1)
  $(ROFS1_HEADER)
  $(if $(CORE_TIME),time=$(CORE_TIME))
endef

define CORE_VERIBYINFO
  // Generated `$(CORE_VERIBY)$' for Core image creation
  $(if $(CORE_ROMVER),

    version=$(CORE_ROMVER))

  OVERRIDE_REPLACE/ADD
  data-override=$(CORE_SWVERFILE)  RESOURCE_FILES_DIR\versions\sw.txt
  data-override=$(CORE_MODELFILE)  RESOURCE_FILES_DIR\versions\model.txt
  data-override=$(CORE_IMEISVFILE)  RESOURCE_FILES_DIR\versions\imeisv.txt
  data-override=$(CORE_PLATFILE)  RESOURCE_FILES_DIR\versions\platform.txt
  data-override=$(CORE_PRODFILE)  RESOURCE_FILES_DIR\versions\product.txt
  $(call iif,$(USE_FOTA),
    data-override=$(CORE_FWIDFILE)  RESOURCE_FILES_DIR\versions\fwid1.txt)
  OVERRIDE_END
endef

#==============================================================================

CLEAN_COREFILE =\
  del | "$(CORE_MSTOBY)" "$(CORE_VERIBY)" "$(CORE_SWVERFILE)" "$(CORE_MODELFILE)"\
    "$(CORE_IMEISVFILE)" "$(CORE_PLATFILE)" "$(CORE_PRODFILE)" "$(CORE_FWIDFILE)" |\
  del | $(call getgenfiles,$(CORE_OBYGEN))

BUILD_COREFILE =\
  echo-q | Generating file(s) for Core image creation |\
  write  | $(CORE_MSTOBY) | $(call def2str,$(CORE_MSTOBYINFO)) |\
  $(call iif,$(USE_ROFS1),$(call iif,$(USE_VERGEN),\
    write  | $(CORE_VERIBY)     | $(call def2str,$(CORE_VERIBYINFO)) |\
    writeu | $(CORE_SWVERFILE)  | $(CORE_SWVERINFO)  |\
    writeu | $(CORE_MODELFILE)  | $(CORE_MODELINFO)  |\
    writeu | $(CORE_IMEISVFILE) | $(CORE_IMEISVINFO) |\
    writeu | $(CORE_PLATFILE)   | $(CORE_PLATINFO)   |\
    writeu | $(CORE_PRODFILE)   | $(CORE_PRODINFO)   |\
    writeu | $(CORE_FWIDFILE)   | $(CORE_FWIDINFO)   |))\
  $(CORE_OBYGEN)


###############################################################################
# Core pre-build step

CLEAN_COREPRE = $(if $(filter 1,$(USE_VARIANTBLD)),$(CLEAN_CUSTVARIANT) |) $(CLEAN_COREFILE)
BUILD_COREPRE =\
  $(if $(filter 1,$(USE_VARIANTBLD)),$(BUILD_CUSTVARIANT) |)\
  mkcd | $(CORE_DIR) |\
  $(BUILD_COREFILE)

#==============================================================================
# Core build step

BLR.CORE.IDIR  = $(call dir2inc,$(CORE_IDIR) $(call iif,$(USE_FEATVAR),,$(FEATVAR_IDIR)))
BLR.CORE.HBY   = $(call includeiby,<data_caging_paths_for_iby.hrh> $(CORE_HBY))
BLR.CORE.OBY   = $(call includeiby,$(CORE_OBY) $(if $(filter 1,$(USE_VARIANTBLD)),$(VARIANT_OBY)) $(BLDROBY) $(call iif,$(USE_ROFS1),$(call iif,$(USE_VERGEN),$(CORE_VERIBY))))
BLR.CORE.OPT   = $(CORE_OPT) $(if $(filter 1,$(USE_PAGEDCODE)),$(if $(ODP_CODECOMP),-c$(ODP_CODECOMP))) -o$(notdir $(CORE_NAME).img) $(BLDROPT)
BLR.CORE.POST  =\
  move | $(CORE_PREFIX).log | $(ROM_LOG) |\
  move | $(CORE_PREFIX).oby | $(ROM_OUTOBY) |\
  test | $(ROM_IMG) | $(call iif,$(USE_PAGEDROM),test | $(ROM_INC) |)\
  $(call iif,$(USE_ROFS1),test | $(ROFS1_IMG))

CLEAN_CORE = $(CLEAN_BLDROM)
BUILD_CORE = $(BUILD_BLDROM)

#==============================================================================
# Core post-build step

CLEAN_COREPOST = $(CLEAN_IMGCHK) | $(CLEAN_CORESYM)
BUILD_COREPOST =\
  $(call iif,$(USE_IMGCHK),$(BUILD_IMGCHK) |)\
  $(call iif,$(USE_SYMGEN),$(BUILD_CORESYM))

CLEAN_CORESYM = del | "$(ROM_SYM)" "$(ROFS1_SYM)"
BUILD_CORESYM =\
  echo-q | Creating $(CORE_TITLE) symbol file(s) |\
  cmd    | $(MAKSYM_TOOL) $(call pathconv,$(ROM_LOG) $(ROM_SYM)) |\
  $(call iif,$(USE_ROFS1),cmd | $(MAKSYMROFS_TOOL) $(call pathconv,$(ROFS1_LOG) $(ROFS1_SYM)))

#==============================================================================

SOS.CORE.STEPS = $(call iif,$(SKIPPRE),,COREPRE) $(call iif,$(SKIPBLD),,CORE) $(call iif,$(SKIPPOST),,COREPOST)
ALL.CORE.STEPS = $(SOS.CORE.STEPS)


###############################################################################
# Targets

.PHONY: core core-all core-image core-pre core-check core-symbol core-i2file

core core-% rom-% rofs1-%: IMAGE_TYPE = CORE
core-all     : USE_SYMGEN = 1

core core-all: ;@$(call IMAKER,$$(ALL.CORE.STEPS))
core-image   : ;@$(call IMAKER,$$(SOS.CORE.STEPS))

core-pre     : ;@$(call IMAKER,COREPRE)
core-check   : ;@$(call IMAKER,IMGCHK)
core-symbol  : ;@$(call IMAKER,CORESYM)

core-i2file  : ;@$(call IMAKER,COREI2F)

core-trace-% : LABEL         = _trace_$*
core-trace-% : USE_UDEB      = 1
core-trace-% : CORE_UDEBFILE = $(call findfile,$(TRACE_PREFIX)$*$(TRACE_SUFFIX),$(TRACE_IDIR))
core-trace-% :\
  ;@$(if $(wildcard $(CORE_UDEBFILE)),,$(error Can't make target `$@', file `$(CORE_UDEBFILE)' not found))\
    $(call IMAKER,$$(ALL.CORE.STEPS))


# END OF IMAKER_CORE.MK
