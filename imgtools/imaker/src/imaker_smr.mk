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
# Description: iMaker SMR image configuration
#



###############################################################################
#  ___ __  __ ___
# / __|  \/  | _ \
# \__ \ |\/| |   /
# |___/_|  |_|_|_\
#

SMR_TITLE  = SMR
SMR_DIR    = $(CORE_DIR)/smr
SMR_NAME   = $(NAME)
SMR_PREFIX = $(SMR_DIR)/$(SMR_NAME)
SMR_IDIR   =
SMR_HBY    =
SMR_OBY    =
SMR_OPT    = $(BLDROM_OPT) -s -D_EABI=$(ARM_VERSION)
SMR_MSTOBY = $(SMR_PREFIX)_smr_master.oby
SMR_HEADER =

SMR_OBYGEN =

SMR_IMG    = $(SMR_PREFIX).smr.img
SMR_LOG    = $(SMR_PREFIX).smr.log
SMR_OUTOBY = $(SMR_PREFIX).smr.oby

SMR_CONECONF =
SMR_CONEOPT  = --all-layers --impl-tag=target:smr

#==============================================================================

define SMR_MSTOBYINFO
  $(call BLDROM_HDRINFO,SMR)

  ROM_IMAGE 0 non-xip size=0x00000000

  /* $(SMR_TITLE) header
  */
  $(SMR_HDRINFO)

  SMR_IMAGE {
    $(BLR.SMR.OBY)
    imagename=$(notdir $(SMR_IMG))
  }
endef

define SMR_HDRINFO
  $(DEFINE) _IMAGE_WORKDIR $(SMR_DIR)
  $(call mac2cppdef,$(BLR.SMR.OPT))
  $(BLR.SMR.HBY)
  $(SMR_HEADER)
  $(if $(filter 1,$(USE_VARIANTBLD)),$(VARIANT_HEADER))
endef


###############################################################################
# SMR pre-build step

CLEAN_SMRPRE =\
  $(if $(filter 1,$(USE_VARIANTBLD)),$(CLEAN_VARIANT) |)\
  del | "$(SMR_MSTOBY)" | del | $(call getgenfiles,$(SMR_OBYGEN))

BUILD_SMRPRE =\
  $(if $(filter 1,$(USE_VARIANTBLD)),$(BUILD_VARIANT) |)\
  mkdir   | "$(SMR_DIR)" |\
  echo-q  | Generating file(s) for $(SMR_TITLE) image creation  |\
  write-c | "$(SMR_MSTOBY)" | $(call def2str,$(SMR_MSTOBYINFO)) |\
  $(SMR_OBYGEN)

#==============================================================================
# SMR build step

BLR.SMR.IDIR = $(call dir2inc,$(SMR_IDIR) $(call iif,$(USE_FEATVAR),,$(FEATVAR_IDIR)))
BLR.SMR.HBY  = $(call includeiby,$(IMAGE_HBY) $(SMR_HBY))
BLR.SMR.OBY  = $(call includeiby,$(SMR_OBY))\
  $(call includeiby,$(if $(filter 1,$(USE_VARIANTBLD)),$(VARIANT_OBY)) $(BLDROBY))
BLR.SMR.OPT  = $(SMR_OPT) -o$(call pathconv,$(SMR_PREFIX)).img $(BLDROPT)
BLR.SMR.POST =\
  move | "$(SMR_OUTOBY).log" | $(SMR_LOG) |\
  test | "$(SMR_IMG)"

CLEAN_SMR = $(call CLEAN_BLDROM,SMR)
BUILD_SMR = $(call BUILD_BLDROM,SMR)

REPORT_SMR =\
  $(SMR_TITLE) dir   | $(SMR_DIR) | d |\
  $(SMR_TITLE) image | $(SMR_IMG) | f

#==============================================================================

SOS.SMR.STEPS = $(call iif,$(USE_SMR),\
  $(call iif,$(SKIPPRE),,$(and $(filter 1,$(USE_VARIANTBLD)),$(call true,$(USE_CONE)),CONEGEN RESTART) SMRPRE)\
  $(call iif,$(SKIPBLD),,SMR) $(call iif,$(SKIPPOST),,SMRPOST))

ALL.SMR.STEPS = $(SOS.SMR.STEPS)


###############################################################################
# Targets

.PHONY: smr smr-all smr-image smr-cone smr-pre

smr smr%: IMAGE_TYPE = SMR

smr smr-all: ;@$(call IMAKER,$$(ALL.SMR.STEPS))
smr-image  : ;@$(call IMAKER,$$(SOS.SMR.STEPS))
smr-cone   : ;@$(call IMAKER,CONEGEN)
smr-pre    : ;@$(call IMAKER,SMRPRE)


# END OF IMAKER_SMR.MK
