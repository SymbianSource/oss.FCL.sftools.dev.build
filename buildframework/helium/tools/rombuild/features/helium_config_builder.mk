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
#################################################################
# Helium iMaker configuration builder.
# This should ease the iMaker build configuration.
# Each rom creation will be driven by one configuration file,
# which will contains a predefine target call to perform the
# rom build operation.
# Configs could be either generated or manually created.
# imaker -pPRODUCT -cncp51 -f helium_config_builder.mk build-roms
#################################################################

################################################################
# File glober
# $1: location
# $2: perl regexp to match
helium_glob=$(shell perl -e "use File::Find; use File::Spec; File::Find::find(\&wanted, $$ARGV[0]); sub wanted(){my $$name =$$File::Find::name; if ( $$name =~ /$$ARGV[1]/i ) {$$name =~ s/ /?/g; print $$name.' '; } }" $1 $2)


################################################################
# Config files location
ROM_CONFIG_DIR=$(PRODUCT_DIR)/rom_configs
ROM_CONFIGS=$(call helium_glob,$(ROM_CONFIG_DIR),.mk$$)


# target to build one config
%-build-rom:
	@echo === Stage=$* == $*
	-@perl -e "print '++ Started at '.localtime().\"\n\""
	-@perl -e "use Time::HiRes; print '+++ HiRes Start '.Time::HiRes::time().\"\n\";"
	@echo Building imaker -f $* build-rom
	-@imaker -f $* build-rom
	-@perl -e "use Time::HiRes; print '+++ HiRes End '.Time::HiRes::time().\"\n\";"
	-@perl -e "print '++ Finished at '.localtime().\"\n\""

# target to build all configs
build-roms: $(foreach config,$(ROM_CONFIGS),$(config)-build-rom)


################################################################
