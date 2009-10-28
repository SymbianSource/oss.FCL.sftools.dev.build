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
# Description: iMaker Variant image configuration
#



###############################################################################
# __   __        _          _     ___      _ _    _
# \ \ / /_ _ _ _(_)__ _ _ _| |_  | _ )_  _(_) |__| |
#  \ V / _` | '_| / _` | ' \  _| | _ \ || | | / _` |
#   \_/\__,_|_| |_\__,_|_||_\__| |___/\_,_|_|_\__,_|
#

USE_VARIANTBLD = 0

VARIANT_NAME     = $(TARGETNAME)
VARIANT_ID       = $(TARGETID)
VARIANT_DIR      = $(call iif,$(USE_CUSTVARIANTBLD),,$(PRODVARIANT_DIR))
VARIANT_OUTDIR   = $(if $(filter u U,$(USE_VARIANTBLD)),$(UDA_DATADIR),$($(IMAGE_TYPE)_DIR)/variant)
VARIANT_MKNAME   = variant.mk
VARIANT_MK       = $(if $(VARIANT_DIR),$(wildcard $(VARIANT_DIR)/$(VARIANT_MKNAME)))

VARIANT_PREFIX   = $($(IMAGE_TYPE)_PREFIX)_$(call lcase,$(IMAGE_TYPE))
VARIANT_HBY      = $(VARIANT_PREFIX)_customervariant.hby
VARIANT_HEADER   = $(if $(VARIANT_INCDIR),$(call includeiby,$(VARIANT_HBY)))
VARIANT_OBY      = $(VARIANT_PREFIX)_customervariant.oby
VARIANT_OVERRIDE = $(if $(filter 1 2,$(USE_VARIANTBLD)),1,0)
VARIANT_OBYDATA  = data$(call iif,$(VARIANT_OVERRIDE),-override)="%1"  "%2"

VARIANT_CONFML   = $(call iif,$(USE_CUSTVARIANTBLD),$(wildcard $(VARIANT_DIR)/$(CONFT_CFGNAME).confml),$(PRODVARIANT_CONFML))
VARIANT_CONFCP   = $(call iif,$(USE_CUSTVARIANTBLD),$(if $(VARIANT_CONFML),$(CONFT_CFGNAME)),$(PRODVARIANT_CONFCP))
VARIANT_CPDIR    = $(wildcard $(VARIANT_DIR)/content)
VARIANT_INCDIR   = $(wildcard $(VARIANT_DIR)/include)
VARIANT_SISDIR   = $(wildcard $(VARIANT_DIR)/sis)
VARIANT_OPCDIR   = $(wildcard $(VARIANT_DIR)/opcache)
VARIANT_ZIPDIR   = $(wildcard $(VARIANT_DIR)/zip)

#==============================================================================

CLEAN_CUSTVARIANT =\
  del | "$(VARIANT_HBY)" "$(VARIANT_OBY)" | deldir | $(VARIANT_OUTDIR) |\
  $(if $(VARIANT_CONFML),$(CLEAN_CENREP)  |)\
  $(if $(VARIANT_SISDIR),$(CLEAN_SISINST) |)\
  $(if $(VARIANT_OPCDIR),$(CLEAN_OPCACHE) |)

BUILD_CUSTVARIANT =\
  echo-q | Variant target             USE_VARIANTBLD = $(call iif,$(USE_VARIANTBLD),`$(USE_VARIANTBLD)$',-) |\
  echo-q | Variant directory          VARIANT_DIR    = $(or $(filter -,$(VARIANT_DIR)),$(if $(VARIANT_DIR),`$(VARIANT_DIR)$',-)) |\
  echo-q | Variant config makefile    VARIANT_MK     = $(if $(VARIANT_MK),`$(VARIANT_MK)$',-) |\
  echo-q | Variant include directory  VARIANT_INCDIR = $(if $(VARIANT_INCDIR),`$(VARIANT_INCDIR)$',-) |\
  echo-q | Variant confml file        VARIANT_CONFML = $(if $(VARIANT_CONFML),`$(VARIANT_CONFML)$',-) |\
  echo-q | Variant CenRep configs     VARIANT_CONFCP = $(if $(VARIANT_CONFCP),`$(VARIANT_CONFCP)$',-) |\
  echo-q | Variant SIS directory      VARIANT_SISDIR = $(if $(VARIANT_SISDIR),`$(VARIANT_SISDIR)$',-) |\
  echo-q | Variant operator cache dir VARIANT_OPCDIR = $(if $(VARIANT_OPCDIR),`$(VARIANT_OPCDIR)$',-) |\
  echo-q | Variant zip content dir    VARIANT_ZIPDIR = $(if $(VARIANT_ZIPDIR),`$(VARIANT_ZIPDIR)$',-) |\
  echo-q | Variant copy content dir   VARIANT_CPDIR  = $(if $(VARIANT_CPDIR),`$(VARIANT_CPDIR)$',-)   |\
  echo-q | Variant output directory   VARIANT_OUTDIR = $(if $(VARIANT_OUTDIR),`$(VARIANT_OUTDIR)$',-) |\
  $(if $(VARIANT_DIR),,\
    error | 1 | Variable VARIANT_DIR is not set while making target $@!\n |)\
  $(if $(word 2,$(USE_VARIANTBLD))$(filter-out 0 1 2 3 4 5 6 u U,$(USE_VARIANTBLD)),\
    error | 1 | Variable USE_VARIANTBLD is incorrectly defined. Possible values are 1 - 3 (6) and u.\n |)\
  mkdir  | $(VARIANT_OUTDIR) |\
  $(if $(VARIANT_INCDIR),\
    echo-q | Generating oby(s) for Variant image creation |\
    geniby | $(VARIANT_HBY) | $(VARIANT_INCDIR) | *.hrh | \#include "%3" | end |\
    geniby | $(VARIANT_OBY) | $(VARIANT_INCDIR) | *.iby | \#include "%3" | end |)\
  $(if $(wildcard $(VARIANT_CONFML)),\
    $(BUILD_CENREP) |)\
  $(if $(VARIANT_SISDIR),\
    $(call iif,$(USE_SOSUDA),\
      geniby-r | >>$(VARIANT_OBY) | $(VARIANT_SISDIR) | *.sis* | sisfile="%1" | end,\
      $(BUILD_SISINST)) |)\
  $(if $(VARIANT_OPCDIR),\
    $(BUILD_OPCACHE) |)\
  $(if $(VARIANT_ZIPDIR),$(if $(wildcard $(VARIANT_ZIPDIR)/*),\
    echo-q | Extracting zip content directory |\
    cmd    | $(7ZIP_TOOL) x -y $(VARIANT_ZIPDIR)/* -o$(VARIANT_OUTDIR) |))\
  $(if $(VARIANT_CPDIR),\
    echo-q | Copying copy content directory |\
    copy   | $(VARIANT_CPDIR)/* | $(VARIANT_OUTDIR) |)\
  $(if $(filter u U,$(USE_VARIANTBLD)),,\
    geniby-r | >>$(VARIANT_OBY) | $(VARIANT_OUTDIR) | * | $(VARIANT_OBYDATA) | end |)\
  write | >>$(VARIANT_OBY) | |

#==============================================================================

variantrofs%: USE_CUSTVARIANTBLD = 1

$(foreach rofs,2 3 4 5 6,\
  $(eval .PHONY: variantrofs$(rofs))\
  $(eval variantrofs$(rofs) variantrofs$(rofs)%: USE_VARIANTBLD = $(rofs))\
  $(eval variantrofs$(rofs) variantrofs$(rofs)%: rofs$(rofs)$(TARGETEXT) ;)\
)

$(call add_help,variantrofs2,t,Create an image from a variant with rofs2. Be sure to define the VARIANT_DIR.)
$(call add_help,variantrofs3,t,Create an image from a customer variant folder. Be sure to define the VARIANT_DIR.)
$(call add_help,variantuda,t,Create an image from a variant userdata folder. Be sure to define the VARIANT_DIR.)

#==============================================================================

SOS.VARIANT.STEPS = $(foreach rofs,2 3 4 5 6,$(SOS.ROFS$(rofs).STEPS))
ALL.VARIANT.STEPS = $(SOS.VARIANT.STEPS)

#==============================================================================
# Targets

.PHONY: variant variant-image variant-symbol variant-i2file

variant: ;@$(call IMAKER,$$(ALL.VARIANT.STEPS))

variant-image: ;@$(call IMAKER,$$(SOS.VARIANT.STEPS))

variant-symbol:\
  ;@$(call IMAKER,$(foreach rofs,2 3 4 5 6,$(call iif,$(USE_ROFS$(rofs)),ROFS$(rofs)SYM)))

variant-i2file: ;@$(call IMAKER,VARIANTI2F)


# END OF IMAKER_VARIANT.MK
