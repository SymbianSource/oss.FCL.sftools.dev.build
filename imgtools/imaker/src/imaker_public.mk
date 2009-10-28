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
# Description: iMaker public interface
#



#==============================================================================
# Product variant variables

FEATVARIANT_CONFML = $(wildcard $(PRODUCT_DIR)/$(FEATURE_VARIANT).confml)

PRODVARIANT_DIR    = $(PRODUCT_DIR)
PRODVARIANT_CONFML = $(or $(FEATVARIANT_CONFML),$(PRODUCT_DIR)/$(PRODUCT_NAME).confml)
PRODVARIANT_CONFCP =\
  $(PLATFORM_NAME) $(PRODUCT_MSTNAME) $(PRODUCT_NAME)\
  $(if $(FEATVARIANT_CONFML),$(call select,$(PRODUCT_NAME),$(FEATURE_VARIANT),,$(FEATURE_VARIANT)))

#==============================================================================
# Customer variant variables
# Root for customer variant (custvariant) package settings

CUSTVARIANT_ROOT   = $(PRODUCT_DIR)/customer
CUSTVARIANT_PREFIX = custvariant_
CUSTVARIANT_NAME   =
CUSTVARIANT_ID     =
CUSTVARIANT_DIR    = $(CUSTVARIANT_ROOT)/$(CUSTVARIANT_NAME)
CUSTVARIANT_COMPLP =

#==============================================================================
# The Target specific override settings

$(CUSTVARIANT_PREFIX)%: CUSTVARIANT_NAME = $(TARGETNAME)
$(CUSTVARIANT_PREFIX)%: CUSTVARIANT_ID   = $(TARGETID)
$(CUSTVARIANT_PREFIX)%: VARIANT_DIR      = $(CUSTVARIANT_DIR)
$(CUSTVARIANT_PREFIX)%: variantrofs3_$(TARGETID)$(TARGETEXT) ;

#==============================================================================
# Helps

$(call add_help,PRODVARIANT_DIR,v,(string),Overrides the VARIANT_DIR for product variant, see the instructions of VARIANT_CONFCP for details.)
$(call add_help,PRODVARIANT_CONFML,v,(string),Overrides the VARIANT_CONFML for product variant, see the instructions of VARIANT_CONFML for details.)
$(call add_help,PRODVARIANT_CONFCP,v,(string),Overrides the VARIANT_CONFCP for product variant, see the instructions of VARIANT_CONFCP for details.)
$(call add_help,CUSTVARIANT_DIR,v,(string),Overrides the VARIANT_DIR for customer variant, see the instructions of VARIANT_CONFCP for details.)
$(call add_help,CUSTVARIANT_COMPLP,v,(string),Compatible language variant.)
