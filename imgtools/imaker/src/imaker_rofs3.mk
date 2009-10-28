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
# Description: iMaker ROFS3 image configuration
#



###############################################################################
#  ___  ___  ___ ___   ____
# | _ \/ _ \| __/ __| |__ /
# |   / (_) | _|\__ \  |_ \
# |_|_\\___/|_| |___/ |___/
#

ROFS3_TITLE      = ROFS3
ROFS3_DIR        = $(WORKDIR)/rofs3
ROFS3_NAME       = $(NAME)
ROFS3_PREFIX     = $(ROFS3_DIR)/$(ROFS3_NAME)
ROFS3_IDIR       =
ROFS3_HBY        =
ROFS3_OBY        =
ROFS3_OPT        =
ROFS3_MSTOBY     = $(ROFS3_PREFIX)_rofs3_master.oby
ROFS3_HEADER     =
ROFS3_INLINE     =
ROFS3_FOOTER     =
ROFS3_TIME       = $(DAY)/$(MONTH)/$(YEAR)

ROFS3_OBYGEN     = #geniby | $(ROFS3_PREFIX)_rofs3_collected.oby | $(E32ROMINC)/customervariant/* | *.iby | \#include "%3" | end

ROFS3_VERIBY     = $(ROFS3_PREFIX)_rofs3_version.iby
ROFS3_ROMVER     = 0.01(0)
ROFS3_VERSION    = $(CORE_VERSION)
ROFS3_CUSTSWFILE = $(ROFS3_PREFIX)_rofs3_customersw.txt
ROFS3_CUSTSWINFO = $(ROFS3_VERSION)\\\n$(DAY)-$(MONTH)-$(YEAR2)
ROFS3_FWIDFILE   = $(ROFS3_PREFIX)_rofs3_fwid.txt
ROFS3_FWID       = customer
ROFS3_FWIDVER    = $(ROFS3_VERSION) Customer
ROFS3_FWIDINFO   = id=$(ROFS3_FWID)\nversion=$(ROFS3_FWIDVER)\n

ROFS3_IMG        = $(ROFS3_PREFIX).rofs3.img
ROFS3_LOG        = $(ROFS3_PREFIX).rofs3.log
ROFS3_OUTOBY     = $(ROFS3_PREFIX).rofs3.oby
ROFS3_SYM        = $(ROFS3_PREFIX).rofs3.symbol

ROFS3_PLUGINLOG  = $(ROFS3_PREFIX)_rofs3_bldromplugin.log
ROFS3_PAGEFILE   = $(ODP_PAGEFILE)
ROFS3_UDEBFILE   = $(TRACE_UDEBFILE)

ROFS3_ICHKLOG    = $(ROFS3_PREFIX)_rofs3_imgcheck.log
ROFS3_ICHKOPT    = $(IMGCHK_OPT)
ROFS3_ICHKIMG    = $(ROFS3_IMG) $(ROFS2_ICHKIMG)

ROFS3_I2FDIR     = $(ROFS3_DIR)/img2file

#==============================================================================

define ROFS3_MSTOBYINFO
  $(BLDROM_HDRINFO)

  ROM_IMAGE 0        non-xip size=0x00000000
  ROM_IMAGE 1 dummy1 non-xip size=$(ROFS_MAXSIZE)
  ROM_IMAGE 2 dummy2 non-xip size=$(ROFS_MAXSIZE)
  ROM_IMAGE 3  rofs3 non-xip size=$(ROFS_MAXSIZE)

  $(BLDROM_PLUGINFO)

  // ROFS3 header
  //
  $(ROFS3_HDRINFO)

  ROM_IMAGE[3] {
    $(call ODP_CODEINFO,3)
    $(BLR.ROFS3.OBY)
    $(ROFS3_INLINE)
    $(ROFS3_FOOTERINFO)
  }
endef

define ROFS3_HDRINFO
  $(DEFINE) _IMAGE_WORKDIR $(ROFS3_DIR)
  $(call mac2cppdef,$(BLR.ROFS3.OPT))
  $(BLR.ROFS3.HBY)
  $(ROFS3_HEADER)
  $(if $(filter 3,$(USE_VARIANTBLD)),$(VARIANT_HEADER))
endef

define ROFS3_FOOTERINFO
  $(if $(ROFS3_TIME),time=$(ROFS3_TIME))
  $(ROFS3_FOOTER)
endef

define ROFS3_VERIBYINFO
  // Generated `$(ROFS3_VERIBY)$' for ROFS3 image creation
  $(if $(ROFS3_ROMVER),

    version=$(ROFS3_ROMVER))

  OVERRIDE_REPLACE/ADD
  $(if $(ROFS3_CUSTSWINFO),
    data-override=$(ROFS3_CUSTSWFILE)  RESOURCE_FILES_DIR\versions\customersw.txt)
  $(call iif,$(USE_FOTA),
    data-override=$(ROFS3_FWIDFILE)  RESOURCE_FILES_DIR\versions\fwid3.txt)
  OVERRIDE_END
endef

#==============================================================================

CLEAN_ROFS3FILE =\
  del | "$(ROFS3_MSTOBY)" "$(ROFS3_VERIBY)" "$(ROFS3_CUSTSWFILE)" "$(ROFS3_FWIDFILE)" |\
  del | $(call getgenfiles,$(ROFS3_OBYGEN))

BUILD_ROFS3FILE =\
  echo-q | Generating file(s) for ROFS3 image creation |\
  write  | $(ROFS3_MSTOBY) | $(call def2str,$(ROFS3_MSTOBYINFO)) |\
  $(call iif,$(USE_VERGEN),\
    write  | $(ROFS3_VERIBY)     | $(call def2str,$(ROFS3_VERIBYINFO)) |\
    writeu | $(ROFS3_CUSTSWFILE) | $(ROFS3_CUSTSWINFO) |\
    writeu | $(ROFS3_FWIDFILE)   | $(ROFS3_FWIDINFO) |)\
  $(ROFS3_OBYGEN)


###############################################################################
# ROFS3 pre

CLEAN_ROFS3PRE = $(if $(filter 3,$(USE_VARIANTBLD)),$(CLEAN_CUSTVARIANT) |) $(CLEAN_ROFS3FILE)
BUILD_ROFS3PRE =\
  $(if $(filter 3,$(USE_VARIANTBLD)),$(BUILD_CUSTVARIANT) |)\
  mkcd | $(ROFS3_DIR) |\
  $(BUILD_ROFS3FILE)

#==============================================================================
# ROFS3 build

BLR.ROFS3.IDIR = $(call dir2inc,$(ROFS3_IDIR) $(call iif,$(USE_FEATVAR),,$(FEATVAR_IDIR)))
BLR.ROFS3.HBY  = $(call includeiby,$(IMAGE_HBY) $(ROFS3_HBY))
BLR.ROFS3.OBY  = $(call includeiby,$(ROFS3_OBY) $(if $(filter 3,$(USE_VARIANTBLD)),$(VARIANT_OBY)) $(call iif,$(USE_VERGEN),$(ROFS3_VERIBY)))
BLR.ROFS3.OPT  = $(ROFS3_OPT) $(if $(filter 3,$(USE_PAGEDCODE)),$(if $(ODP_CODECOMP),-c$(ODP_CODECOMP))) -o$(notdir $(ROFS3_NAME).img) $(BLDROPT)
BLR.ROFS3.POST = $(call iif,$(KEEPTEMP),,del | $(ROFS3_PREFIX).???)

CLEAN_ROFS3 = $(CLEAN_BLDROM)
BUILD_ROFS3 = $(BUILD_BLDROM)

#==============================================================================
# ROFS3 post

CLEAN_ROFS3POST = $(CLEAN_IMGCHK) | $(CLEAN_MAKSYMROFS)
BUILD_ROFS3POST =\
  $(call iif,$(USE_IMGCHK),$(BUILD_IMGCHK) |)\
  $(call iif,$(USE_SYMGEN),$(BUILD_MAKSYMROFS))

#==============================================================================

SOS.ROFS3.STEPS = $(call iif,$(USE_ROFS3),$(call iif,$(SKIPPRE),,ROFS3PRE) $(call iif,$(SKIPBLD),,ROFS3) $(call iif,$(SKIPPOST),,ROFS3POST))
ALL.ROFS3.STEPS = $(SOS.ROFS3.STEPS)


###############################################################################
# Targets

.PHONY: rofs3 rofs3-all rofs3-image rofs3-pre rofs3-check rofs3-symbol rofs3-i2file

rofs3 rofs3-%  : IMAGE_TYPE = ROFS3
rofs3-all      : USE_SYMGEN = 1

rofs3 rofs3-all: ;@$(call IMAKER,$$(ALL.ROFS3.STEPS))
rofs3-image    : ;@$(call IMAKER,$$(SOS.ROFS3.STEPS))

rofs3-pre      : ;@$(call IMAKER,ROFS3PRE)
rofs3-check    : ;@$(call IMAKER,IMGCHK)
rofs3-symbol   : ;@$(call IMAKER,MAKSYMROFS)

rofs3-i2file   : USE_ROFS = 3
rofs3-i2file   : ;@$(call IMAKER,VARIANTI2F)


# END OF IMAKER_ROFS3.MK
