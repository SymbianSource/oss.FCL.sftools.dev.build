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
# Description: iMaker Variant Build image configuration
#



###############################################################################
# __   __        _          _     ___      _ _    _
# \ \ / /_ _ _ _(_)__ _ _ _| |_  | _ )_  _(_) |__| |
#  \ V / _` | '_| / _` | ' \  _| | _ \ || | | / _` |
#   \_/\__,_|_| |_\__,_|_||_\__| |___/\_,_|_|_\__,_|
#

USE_VARIANTBLD = 0

PRODUCT_VARDIR   = $(if $(and $(call true,$(USE_CONE)),$(call true,$(IMAKER_MKRESTARTS))),$(CONE_OUTDIR),$(PRODUCT_DIR))

VARIANT_NAME     = $(TARGETNAME)
VARIANT_ID       = $(TARGETID)
VARIANT_DIR      = $(if $(filter $(LANGPACK_PREFIX)%,$(TARGETNAME)),$(LANGPACK_DIR),$(if\
  $(filter $(CUSTVARIANT_PREFIX)%,$(TARGETNAME)),$(CUSTVARIANT_DIR),$(if\
    $(filter emmc_% mcard_% uda_%,$(TARGETNAME)),$($(IMAGE_TYPE)_VARDIR),$(if\
      $(filter variant%,$(TARGETNAME)),,$(PRODUCT_VARDIR)))))
VARIANT_OUTDIR   = $(if $(filter CORE ROFS%,$(IMAGE_TYPE)),$($(IMAGE_TYPE)_DIR)/variant,$($(IMAGE_TYPE)_DATADIR))
VARIANT_MKNAME   = variant.mk
VARIANT_MK       = $(if $(VARIANT_DIR),$(wildcard $(VARIANT_DIR)/$(VARIANT_MKNAME)))

VARIANT_HBY      = $(IMAGE_PREFIX)_$(if $(filter CORE ROFS%,$(IMAGE_TYPE)),variant,datadrive).hby
VARIANT_HEADER   = $(if $(VARIANT_INCDIR),$(call includeiby,$(VARIANT_HBY)))
VARIANT_OBY      = $(basename $(VARIANT_HBY)).oby
VARIANT_OVERRIDE = $(if $(filter CORE ROFS%,$(IMAGE_TYPE)),OVERRIDE_REPLACE/ADD)
VARIANT_OBYDATA  = data$(call iif,$(VARIANT_OVERRIDE),-override)="%1"  "%2"$(if $(filter CORE ROFS%,$(IMAGE_TYPE)),,  %4)

VARIANT_CPDIR    = $(if $(wildcard $(VARIANT_DIR)/content/*),$(VARIANT_DIR)/content)
VARIANT_INCDIR   = $(if $(wildcard $(VARIANT_DIR)/include/*),$(VARIANT_DIR)/include)
VARIANT_SISDIR   = $(if $(wildcard $(VARIANT_DIR)/sis/*),$(VARIANT_DIR)/sis)
VARIANT_OPCDIR   = $(if $(wildcard $(VARIANT_DIR)/opcache/*),$(VARIANT_DIR)/opcache)
VARIANT_WGZDIR   = $(if $(wildcard $(VARIANT_DIR)/widget/*),$(VARIANT_DIR)/widget)
VARIANT_ZIPDIR   = $(if $(wildcard $(VARIANT_DIR)/zip/*),$(VARIANT_DIR)/zip)

#==============================================================================

CLEAN_VARIANT =\
  del | "$(VARIANT_HBY)" "$(VARIANT_OBY)" | deldir | "$(VARIANT_OUTDIR)" |\
  $(CLEAN_SISINST) | $(CLEAN_OPCACHE) | $(CLEAN_WIDGET)

BUILD_VARIANT =\
  echo-q | Variant target              USE_VARIANTBLD = $(call iif,$(USE_VARIANTBLD),`$(USE_VARIANTBLD)',-) |\
  echo-q | Variant directory           VARIANT_DIR    = $(or $(filter -,$(VARIANT_DIR)),$(if $(VARIANT_DIR),`$(VARIANT_DIR)',-)) |\
  echo-q | Variant config makefile     VARIANT_MK     = $(if $(VARIANT_MK),`$(VARIANT_MK)',-) |\
  echo-q | Variant include directory   VARIANT_INCDIR = $(if $(VARIANT_INCDIR),`$(VARIANT_INCDIR)',-) |\
  echo-q | Variant SIS conf            SISINST_INI    = $(if $(SISINST_INI),`$(SISINST_INI)',-)       |\
  echo-q | Variant SIS directory       VARIANT_SISDIR = $(if $(VARIANT_SISDIR),`$(VARIANT_SISDIR)',-) |\
  echo-q | Variant operator cache conf OPC_INI        = $(if $(OPC_INI),`$(OPC_INI)',-)               |\
  echo-q | Variant operator cache dir  VARIANT_OPCDIR = $(if $(VARIANT_OPCDIR),`$(VARIANT_OPCDIR)',-) |\
  echo-q | Variant widget preinst conf WIDGET_INI     = $(if $(WIDGET_INI),`$(WIDGET_INI)',-)         |\
  echo-q | Variant widget preinst dir  VARIANT_WGZDIR = $(if $(VARIANT_WGZDIR),`$(VARIANT_WGZDIR)',-) |\
  echo-q | Variant zip content dir     VARIANT_ZIPDIR = $(if $(VARIANT_ZIPDIR),`$(VARIANT_ZIPDIR)',-) |\
  echo-q | Variant copy content dir    VARIANT_CPDIR  = $(if $(VARIANT_CPDIR),`$(VARIANT_CPDIR)',-)   |\
  echo-q | Variant output directory    VARIANT_OUTDIR = $(if $(VARIANT_OUTDIR),`$(VARIANT_OUTDIR)',-) |\
  $(if $(VARIANT_DIR),,\
    error | 1 | Variable VARIANT_DIR is not set while making target $(TARGETNAME). |)\
  $(if $(wildcard $(subst \,/,$(VARIANT_DIR))),,\
    error | 1 | Variable VARIANT_DIR does not point to an existing directory ($(VARIANT_DIR)). |)\
  $(if $(word 2,$(USE_VARIANTBLD))$(filter-out 0 1 2 3 4 5 6 e E m M u U,$(USE_VARIANTBLD)),\
    error | 1 | Variable USE_VARIANTBLD is incorrectly defined. Possible values are 1 - 6$(,) e$(,) m and u. |)\
  mkdir | "$(VARIANT_OUTDIR)" |\
  $(if $(VARIANT_INCDIR),\
    echo-q | Generating oby(s) for Variant image creation |\
    geniby | $(VARIANT_HBY) | $(VARIANT_INCDIR) |\
      __header__ | define _IMAGE_VARINCDIR $(call quote,$(VARIANT_INCDIR)) | *.hrh | \#include "%3" | end |\
    geniby | $(VARIANT_OBY) | $(VARIANT_INCDIR) | *.iby | \#include "%3" | end |)\
  $(if $(or $(SISINST_INI),$(VARIANT_SISDIR)),\
    $(BUILD_SISINST) |)\
  $(if $(or $(OPC_INI),$(VARIANT_OPCDIR)),\
    $(BUILD_OPCACHE) |)\
  $(if $(or $(WIDGET_INI),$(VARIANT_WGZDIR)),\
    $(BUILD_WIDGET) |)\
  $(if $(VARIANT_ZIPDIR),\
    echo-q | Extracting zip content directory |\
    cmd    | $(7ZIP_TOOL) x -y $(VARIANT_ZIPDIR)/* -o$(VARIANT_OUTDIR) |)\
  $(if $(VARIANT_CPDIR),\
    echo-q  | Copying copy content directory |\
    copydir | "$(VARIANT_CPDIR)" | $(VARIANT_OUTDIR) |)\
  $(call iif,$(filter CORE ROFS%,$(IMAGE_TYPE))$(USE_SOSUDA),\
    geniby-r | >>$(VARIANT_OBY) | $(VARIANT_OUTDIR) |\
      $(call iif,$(VARIANT_OVERRIDE),__header__ | $(VARIANT_OVERRIDE) |)\
      * | $(VARIANT_OBYDATA) |\
      $(call iif,$(VARIANT_OVERRIDE),__footer__ | OVERRIDE_END |) end)

#  geniby-dr | >>$(VARIANT_OBY) | $(VARIANT_OUTDIR) | * | dir="%2" | end


# END OF IMAKER_VARIANT.MK
