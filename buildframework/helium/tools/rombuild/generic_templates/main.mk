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
#
###############################################################################
# iMaker templates
###############################################################################

# defining helium in the build area if not set by the environment
HELIUM_HOME?=\mc\helium

# using winimage from helium delivery.
WINIMAGE_TOOL:=$(if $(strip ${winimage.tool}),${winimage.tool},$(WINIMAGE_TOOL))

CALL_IMAKER_PLATFORM=imaker -p$(PRODUCT_NAME) -c$(COREPLAT_NAME) -f $(E32ROMCFG)/helium_features.mk
CALL_IMAKER=imaker -p$(PRODUCT_NAME) -c$(COREPLAT_NAME) $(if $(UI_PLATFORM),-u$(UI_PLATFORM)) -f $(E32ROMCFG)/helium_features.mk
CALL_TARGET=imaker -p$(PRODUCT_NAME) -c$(COREPLAT_NAME) -f $(E32ROMCFG)/$(COREPLAT_NAME)/$(PRODUCT_NAME)/${output.makefile.filename}

transfer_option=$(foreach option,$1,$(if $($(option)),"$(option)=$($(option))",))


#
# Variation handling
#
LOCALISATION_SWITCH_REGION=1
unzip_%:
	@echo $(call iif,$(LOCALISATION_SWITCH_REGION),Unzipping variation $*...,Region is not switched to $*!)
	$(call iif,$(LOCALISATION_SWITCH_REGION),-@unzip -o -qq -d $(subst \,/,$(EPOCROOT)) /output/build_area/localised/delta_$*_package.zip,)


include /epoc32/rom/config/helium_features.mk
###############################################################################