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
#
# Configuration side
#
##
# Defines the list of product variants we should generate the IBY for.
# productname_IBYFILE must be defined
# productname_TAG could be defined
PRODUCT_VARIANTS?=
##
# Defines where to export the help delivery, could be empty if referencing from the
# project location
TARGET_PATH?=

#
# Internal implementation
#
define BUILDER
@echo Generating $1 $(if $2,destination is $2) $(if $3,using tag $3)  $(if $4,excludes [$4])
@echo -- Running python $(HELIUM_HOME)/tools/localisation/helps/generate_iby_32.py --output=$1 $(if $2,--rootdest=$2) $(if $3,--tag=$3) $(foreach exc,$4,--exclude=$(exc))
python $(HELIUM_HOME)/tools/localisation/helps/generate_iby_32.py --output=$1 $(if $2,--rootdest=$2) $(if $3,--tag=$3) $(foreach exc,$4,--exclude=$(exc))

endef

BLD:
	@echo Helium home: $(HELIUM_HOME)
	$(if $(TARGET_PATH),perl -MExtUtils::Command -e mkpath $(TARGET_PATH))
	$(if $(TARGET_PATH),xcopy  /E /R /Y /F ..\data $(TARGET_PATH))
	$(foreach product,$(PRODUCT_VARIANTS),$(call BUILDER,$($(product)_IBYFILE),$(TARGET_PATH),$($(product)_TAG),$($(product)_EXCLUDES)))

RELEASABLES:
	@echo $(foreach product,$(PRODUCT_VARIANTS),$($(product)_IBYFILE))	

SAVESPACE: BLD

LIB: do_nothing
MAKMAKE: do_nothing
FINAL: do_nothing
FREEZE: do_nothing
RESOURCE: do_nothing


do_nothing:
	@echo Nothing to do