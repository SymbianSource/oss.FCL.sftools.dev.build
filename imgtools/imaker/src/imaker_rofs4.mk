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
# Description: iMaker ROFS4 image configuration
#



###############################################################################
#  ___  ___  ___ ___   _ _
# | _ \/ _ \| __/ __| | | |
# |   / (_) | _|\__ \ |_  _|
# |_|_\\___/|_| |___/   |_|
#

ROFS4_TITLE      = ROFS4
ROFS4_DIR        = $(WORKDIR)/rofs4
ROFS4_NAME       = $(NAME)
ROFS4_PREFIX     = $(ROFS4_DIR)/$(ROFS4_NAME)
ROFS4_IDIR       =
ROFS4_HBY        =
ROFS4_OBY        =
ROFS4_OPT        =
ROFS4_MSTOBY     = $(ROFS4_PREFIX)_rofs4_master.oby
ROFS4_HEADER     =
ROFS4_INLINE     =
ROFS4_FOOTER     =
ROFS4_TIME       = $(DAY)/$(MONTH)/$(YEAR)

ROFS4_OBYGEN     =

ROFS4_VERSION    = $(CORE_VERSION)

ROFS4_IMG        = $(ROFS4_PREFIX).rofs4.img
ROFS4_LOG        = $(ROFS4_PREFIX).rofs4.log
ROFS4_OUTOBY     = $(ROFS4_PREFIX).rofs4.oby
ROFS4_SYM        = $(ROFS4_PREFIX).rofs4.symbol

ROFS4_PLUGINLOG  = $(ROFS4_PREFIX)_rofs4_bldromplugin.log
ROFS4_PAGEFILE   = $(ODP_PAGEFILE)
ROFS4_UDEBFILE   = $(TRACE_UDEBFILE)

ROFS4_ICHKLOG    = $(ROFS4_PREFIX)_rofs4_imgcheck.log
ROFS4_ICHKOPT    = $(IMGCHK_OPT)
ROFS4_ICHKIMG    = $(ROFS4_IMG) $(ROFS2_ICHKIMG)

ROFS4_I2FDIR     = $(ROFS4_DIR)/img2file

#==============================================================================

define ROFS4_MSTOBYINFO
  $(BLDROM_HDRINFO)

  ROM_IMAGE 0        non-xip size=0x00000000
  ROM_IMAGE 1 dummy1 non-xip size=$(ROFS_MAXSIZE)
  ROM_IMAGE 2 dummy2 non-xip size=$(ROFS_MAXSIZE)
  ROM_IMAGE 3 dummy3 non-xip size=$(ROFS_MAXSIZE)
  ROM_IMAGE 4  rofs4 non-xip size=$(ROFS_MAXSIZE)
  ROM_IMAGE 5 dummy5 non-xip size=$(ROFS_MAXSIZE)
  ROM_IMAGE 6 dummy6 non-xip size=$(ROFS_MAXSIZE)

  $(BLDROM_PLUGINFO)

  // ROFS4 header
  //
  $(ROFS4_HDRINFO)

  ROM_IMAGE[4] {
    $(call ODP_CODEINFO,4)
    $(BLR.ROFS4.OBY)
    $(ROFS4_INLINE)
    $(ROFS4_FOOTERINFO)
  }
endef

define ROFS4_HDRINFO
  $(DEFINE) _IMAGE_WORKDIR $(ROFS4_DIR)
  $(call mac2cppdef,$(BLR.ROFS4.OPT))
  $(BLR.ROFS4.HBY)
  $(ROFS4_HEADER)
endef

define ROFS4_FOOTERINFO
  $(if $(ROFS4_TIME),time=$(ROFS4_TIME))
  $(ROFS4_FOOTER)
endef

#==============================================================================

CLEAN_ROFS4FILE =\
  del | "$(ROFS4_MSTOBY)" |\
  del | $(call getgenfiles,$(ROFS4_OBYGEN))

BUILD_ROFS4FILE =\
  echo-q | Generating file(s) for $(ROFS4_TITLE) image creation |\
  write  | $(ROFS4_MSTOBY) | $(call def2str,$(ROFS4_MSTOBYINFO)) |\
  $(ROFS4_OBYGEN)


###############################################################################
# ROFS4 pre

CLEAN_ROFS4PRE = $(CLEAN_ROFS4FILE)
BUILD_ROFS4PRE =\
  mkcd | $(ROFS4_DIR) |\
  $(BUILD_ROFS4FILE)

#==============================================================================
# ROFS4 build

BLR.ROFS4.IDIR = $(call dir2inc,$(ROFS4_IDIR) $(call iif,$(USE_FEATVAR),,$(FEATVAR_IDIR)))
BLR.ROFS4.HBY  = $(call includeiby,$(IMAGE_HBY) $(ROFS4_HBY))
BLR.ROFS4.OBY  = $(call includeiby,$(ROFS4_OBY))
BLR.ROFS4.OPT  = $(ROFS4_OPT) $(if $(filter 4,$(USE_PAGEDCODE)),$(if $(ODP_CODECOMP),-c$(ODP_CODECOMP))) -o$(ROFS4_NAME).img $(BLDROPT)
BLR.ROFS4.POST = $(call iif,$(KEEPTEMP),,del | $(ROFS4_PREFIX).???)

CLEAN_ROFS4 = $(CLEAN_BLDROM)
BUILD_ROFS4 = $(BUILD_BLDROM)

#==============================================================================
# ROFS4 post

CLEAN_ROFS4POST = $(CLEAN_IMGCHK) | $(CLEAN_MAKSYMROFS)
BUILD_ROFS4POST =\
  $(call iif,$(USE_IMGCHK),$(BUILD_IMGCHK) |)\
  $(call iif,$(USE_SYMGEN),$(BUILD_MAKSYMROFS))

#==============================================================================

SOS.ROFS4.STEPS = $(call iif,$(USE_ROFS4),$(call iif,$(SKIPPRE),,ROFS4PRE) $(call iif,$(SKIPBLD),,ROFS4) $(call iif,$(SKIPPOST),,ROFS4POST))
ALL.ROFS4.STEPS = $(SOS.ROFS4.STEPS)


###############################################################################
# Targets

.PHONY: rofs4 rofs4-all rofs4-image rofs4-pre rofs4-check rofs4-symbol rofs4-i2file

rofs4 rofs4-%  : IMAGE_TYPE = ROFS4
rofs4-all      : USE_SYMGEN = 1

rofs4 rofs4-all: ;@$(call IMAKER,$$(ALL.ROFS4.STEPS))
rofs4-image    : ;@$(call IMAKER,$$(SOS.ROFS4.STEPS))

rofs4-pre      : ;@$(call IMAKER,ROFS4PRE)
rofs4-check    : ;@$(call IMAKER,IMGCHK)
rofs4-symbol   : ;@$(call IMAKER,MAKSYMROFS)

rofs4-i2file   : USE_ROFS = 4
rofs4-i2file   : ;@$(call IMAKER,VARIANTI2F)


# END OF IMAKER_ROFS4.MK
