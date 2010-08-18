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
# Description: iMaker ROFS3 image configuration
#



###############################################################################
#  ___  ___  ___ ___   ____
# | _ \/ _ \| __/ __| |__ /
# |   / (_) | _|\__ \  |_ \
# |_|_\\___/|_| |___/ |___/
#

ROFS3_FEAXML   = $(E32INC)/s60customswfeatures.xml
ROFS3_FEAIBY   = $(ROFS3_DIR)/s60customswfeatures.iby

ROFS3_ID       = $(CUSTVARIANT_ID)
ROFS3_REVISION = $(CUSTVARIANT_REVISION)
ROFS3_SWVERTGT = $(IMAGE_VERSDIR)\customersw.txt
ROFS3_FWID     = customer

ROFS3_ICHKIMG += $(ROFS2_ICHKIMG)

ROFS3_CONECONF = $(PRODUCT_NAME)_custvariant_$(CUSTVARIANT_ID)$(addprefix _,$(CUSTVARIANT_NAME))_root.confml
ROFS3_CONEOPT  = --layer-wildcard=*/custvariant* --impl-tag=target:rofs3


###############################################################################
# Customer variant

CUSTVARIANT_ROOT     = $(PRODUCT_DIR)/customer
CUSTVARIANT_ROOT2    = $(if $(PRODUCT_MSTNAME),$(PRODUCT_MSTDIR)/customer)
#CUSTVARIANT_ROOT3    = $(PLATFORM_DIR)/country
CUSTVARIANT_PREFIX   = custvariant_
CUSTVARIANT_ID       = $(if $(filter $(CUSTVARIANT_PREFIX)%,$(TARGETNAME)),$(TARGETID1),00)
CUSTVARIANT_NAME     = $(if $(filter $(CUSTVARIANT_PREFIX)%,$(TARGETNAME)),$(TARGETID2-),vanilla)
CUSTVARIANT_REVISION = 01
CUSTVARIANT_DIR      = $(if $(and $(call true,$(USE_CONE)),$(call true,$(IMAKER_MKRESTARTS))),$(CONE_OUTDIR),$(strip\
  $(eval __i_custvardir :=)$(foreach croot,$(sort $(filter CUSTVARIANT_ROOT%,$(.VARIABLES))),\
    $(if $(__i_custvardir),,$(eval __i_custvardir := $(if $(wildcard $($(croot))),\
      $(wildcard $($(croot))/$(CUSTVARIANT_PREFIX)$(CUSTVARIANT_ID)$(addprefix _,$(CUSTVARIANT_NAME)))))))\
  )$(or $(__i_custvardir),$(CUSTVARIANT_ROOT)/$(CUSTVARIANT_PREFIX)$(CUSTVARIANT_ID)$(addprefix _,$(CUSTVARIANT_NAME)))$(call iif,$(USE_CONE),/content))
CUSTVARIANT_COMPLP   =

CUSTVARIANT_EXPORT = $(if $(filter $(CUSTVARIANT_PREFIX)%,$(TARGETNAME)),$(addprefix $(CUSTVARIANT_PREFIX)%:CUSTVARIANT_,ID NAME))
TARGET_EXPORT     += $(CUSTVARIANT_EXPORT)

# custvariant_%
$(CUSTVARIANT_PREFIX)%: rofs3_$$* ;


###############################################################################
# Helps

$(call add_help,CUSTVARIANT_DIR,v,(string),Overrides the VARIANT_DIR for customer variant, see the instructions of VARIANT_DIR for details.)
$(call add_help,CUSTVARIANT_COMPLP,v,(string),Compatible language variant.)

CUSTVARIANT_HELP = $(call add_help,$(foreach croot,$(filter CUSTVARIANT_ROOT%,$(.VARIABLES)),\
  $(if $(wildcard $($(croot))),$(call getlastdir,$(filter %/,$(wildcard $($(croot))/$(CUSTVARIANT_PREFIX)*/))))),\
  t,Customer $$(subst $$(CUSTVARIANT_PREFIX),,$$1) variant target.)

BUILD_HELPDYNAMIC += $(CUSTVARIANT_HELP)


# END OF IMAKER_ROFS3.MK
