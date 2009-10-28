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
#################################################################################
# UPCT iMaker integration
#################################################################################
UPCT_OLD_CORE_FPSX=
UPCT_NEW_CORE_FPSX=
UPCT_OLD_ROFS2_FPSX=
UPCT_NEW_ROFS2_FPSX=
UPCT_OLD_ROFS3_FPSX=
UPCT_NEW_ROFS3_FPSX=
UPCT_NAME=$(UPDATE_PACKAGE_DIR)/$(NAME).swupd
UPLOAD_XML=$(UPDATE_PACKAGE_DIR)/$(NAME).xml
UPCT_CONF=$(WORKDIR_UNIX)/$(NAME)_upct_conf.txt
UPCT_CONF_WIN=$(WORKDIR)/$(NAME)_upct_conf.txt
UPCT_PACKINFO=$(WORKDIR_UNIX)/$(NAME)_updpack_info.txt
UPCT_KEEPLOGS=1
UPCT_TEMP_FOLDER=$(WORKDIR_UNIX)
UPCT_TOOL_DIR=$(ITOOL_DIR)/upct_release
UPCT_TOOL=$(UPCT_TOOL_DIR)/$(call iif,$(USE_UNIX),linux_upct.exe,upct.exe)
UPCT_GENERATOR_DIR=$(UPCT_TOOL_DIR)/generator_tools
UPCT_SIGNATURE_TYPE=$(if $(subst prd,,$(TYPE)),,production)$(if $(subst rnd,,$(TYPE)),,rnd)$(if $(subst subcon,,$(TYPE)),,rnd)
SUBCON_SIGNATURE_FILE=
E2F_SIGNCONF=-s saisec002 -p 6003
MAKEUPCT_SIGNATURE_TYPE=$(if $(subst prd,,$(TYPE)),,prd_update_package_signing)$(if $(subst rnd,,$(TYPE)),,rnd)$(if $(subst subcon,,$(TYPE)),,rnd)

#################################################################################
CLEAN_CREATE_UPCT_CONF=echo | Deleting $(UPCT_CONF)\n\
                            | del | $(UPCT_CONF_WIN)
BUILD_CREATE_UPCT_CONF=echo | Creating $(UPCT_CONF_WIN)\n\
	| mkdir | $(dir $(UPCT_CONF_WIN) )|\
	| mkdir | $(dir $(UPCT_NAME) )|\
	| write | $(UPCT_CONF_WIN) | ; Generated configuration for $(PRODUCT_NAME)\
	\nnumber_of_asics $(UPCT_ASCIS)\
	$(if $(UPCT_RAMSIZE),\nram_size $(UPCT_RAMSIZE))\
	$(if $(UPCT_SECTORSIZE),\nsector_size $(UPCT_SECTORSIZE))\
	$(if $(UPCT_BACKUPBLOCK),\nbackup_blocks $(UPCT_BACKUPBLOCK))\
	$(if $(UPCT_CMT_RAM_SIZE),\ncmt_ram_size $(UPCT_CMT_RAM_SIZE))\
	$(if $(UPCT_CMT_SECTOR_SIZE),\ncmt_sector_size $(UPCT_CMT_SECTOR_SIZE))\
	$(if $(UPCT_CMT_BACKUP_BLOCKS),\ncmt_backup_blocks $(UPCT_CMT_BACKUP_BLOCKS))\
	$(if $(UPCT_APE_RAM_SIZE),\nape_ram_size $(UPCT_APE_RAM_SIZE))\
	$(if $(UPCT_APE_SECTOR_SIZE),\nape_sector_size $(UPCT_APE_SECTOR_SIZE))\
	$(if $(UPCT_APE_BACKUP_BLOCKS),\nape_backup_blocks $(UPCT_APE_BACKUP_BLOCKS))\
	$(if $(UPCT_CODESTART_MCUSW),\ncodestart_MCUSW $(UPCT_CODESTART_MCUSW))\
	$(if $(UPCT_APE_PRODUCT_KEY_INDEX),\nape_product_key_index $(UPCT_APE_PRODUCT_KEY_INDEX))\
	$(if $(UPCT_CMT_PRODUCT_KEY_INDEX),\ncmt_product_key_index $(UPCT_CMT_PRODUCT_KEY_INDEX))\
	$(if $(UPCT_SOS_ISASW),\ncodestart_SOS*ISASW $(UPCT_SOS_ISASW))\
	$(if $(KEYCERT_INDEX),\nproduct_key_index $(KEYCERT_INDEX))\
	\n\nupdpack_signature $(UPCT_SIGNATURE_TYPE)\
	\n$(if $(SUBCON_SIGNATURE_FILE),\subcontractor_private_keys_file $(SUBCON_SIGNATURE_FILE))\
	\n$(if $(UPCT_OLD_CORE_FPSX),\nold_core_fpsx $(UPCT_OLD_CORE_FPSX))\
	$(if $(UPCT_OLD_ROFS2_FPSX),\nold_variant_fpsx $(UPCT_OLD_ROFS2_FPSX))\
	$(if $(UPCT_OLD_ROFS3_FPSX),\nold_op_variant_fpsx $(UPCT_OLD_ROFS3_FPSX))\
	$(if $(UPCT_NEW_CORE_FPSX),\nnew_core_fpsx $(UPCT_NEW_CORE_FPSX))\
	$(if $(UPCT_NEW_ROFS2_FPSX),\nnew_variant_fpsx $(UPCT_NEW_ROFS2_FPSX))\
	$(if $(UPCT_NEW_ROFS3_FPSX),\nnew_op_variant_fpsx $(UPCT_NEW_ROFS3_FPSX))\
	\n\nelf2flash $(E2F_TOOL)\
	\nsign_parameters "$(E2F_SIGNCONF)" \
	\ngenerator_tools_path $(UPCT_GENERATOR_DIR)\
	\ntemporary_folder $(UPCT_TEMP_FOLDER)\
	\nupdate_package $(UPCT_NAME)\
	\n\nflag_leave_build_log_files $(UPCT_KEEPLOGS)\
	$(if $(UPCT_PACKINFO),\nflag_dump_info $(UPCT_PACKINFO))\
	$(if $(UPCT_GENERATOR_VERSION),\ndebug_force_generator $(UPCT_GENERATOR_VERSION))\
	$(if $(UPCT_EXTRA_PARAMETERS),\n$(UPCT_EXTRA_PARAMETERS)) \
	\n; End of configuration
	
BUILD_CREATE_FOX_UPLOAD=echo | Creating upolad XML $(UPLOAD_XML)\n\
	| write | $(UPLOAD_XML) | ; 

BUILD_CLEAN_FOX_UPLOAD=echo | Deleting $(UPLOAD_XML)\n\
                            | del | $(UPLOAD_XML)

CLEAN_CALL_UPCT=
BUILD_CALL_UPCT=echo | Creating delta package\n\
    | cmd | $(UPCT_TOOL) $(UPCT_CONF)
    

CLEAN_MAKEUPCT_FOTA_CNF= echo | Deleting MakeUPCT $(MAKEUPCT_FOTA_CNF_FILE) config file\n\
	| del | $(MAKEUPCT_FOTA_CNF_FILE) 
BUILD_MAKEUPCT_FOTA_CNF=echo | Creating MakeUPCT $(MAKEUPCT_FOTA_CNF_FILE) config file\n\
	| write | $(MAKEUPCT_FOTA_CNF_FILE) | ; Generated configuration for $(PRODUCT_NAME)\n \
	\nSW_PLATFORM :=$(MAKEUPCT_PLATFORM)  \
	\nUSER_DEFINED_FLASH_DIR :=$(MAKEUPCT_BASE_DIR) \
	\nUSER_DEFINED_NEW_SW_FLASH_DIR :=$(MAKEUPCT_BASE_DIR) \
	\nACT_PRODUCT :=$(PRODUCT_NAME) \
	\nALL_UPDATE_PACKAGES := old_sw_$(MAKEUPCT_OLD_SW_VERSION)_new_sw_$(MAKEUPCT_NEW_SW_VERSION)_type_designator_$(PRODUCT_TYPE) \
	\nSW_TYPE :=$(TYPE) \
	\nSIGNATURE_ID :=$(MAKEUPCT_SIGNATURE_TYPE) \
	\nSTATTISTIC_REQUIRED :=NO \
	\nVARIANTS :=all_variants \
	\nLINUX_DIR :=$(UPCT_TEMP_FOLDER)/wa \
	\nACT_MODEL :=$(MODEL_SW_VERSION_STRING) \
	\nSYMBOL_FILE_USED :=YES \
	\nUPCT_EXTRA_PARAMS := $(if $(UPCT_EXTRA_PARAMETERS), $(UPCT_EXTRA_PARAMETERS))  $(if $(UPCT_GENERATOR_VERSION),\ndebug_force_generator $(UPCT_GENERATOR_VERSION))\

UPCT_STEPS = CREATE_UPCT_CONF CALL_UPCT
#################################################################################

#fota-delta: ;@$(call IMAKER,$(UPCT_STEPS))



#################################################################################
#################################################################################
#################################################################################
#################################################################################
# UPCT configuration builder.
#################################################################################


UPCT_CONF_DIR=$(PRODUCT_DIR)/upct
ALL_UPCT_CONFS=$(wildcard $(UPCT_CONF_DIR)/*.mk)

%-create-upct-config:
	@echo Building $*
	-@imaker -p$(PRODUCT_NAME) -c$(COREPLAT_NAME) -f /epoc32/rom/config/helium_upct.mk -f $* step-CREATE_UPCT_CONF

create-upct-configs: $(foreach config,$(ALL_UPCT_CONFS),$(config)-create-upct-config)

#################################################################################
# MakeUPCT configuration builder.
#################################################################################

MAKEUPCT_CONF_DIR=$(PRODUCT_DIR)/MakeUPCT
ALL_MAKEUPCT_CONFS=$(wildcard $(MAKEUPCT_CONF_DIR)/*.mk)

%-create-makeupct-config:
	@echo Building $*
	-@imaker -p$(PRODUCT_NAME) -c$(COREPLAT_NAME) -f /epoc32/rom/config/helium_upct.mk -f $* step-MAKEUPCT_FOTA_CNF

create-makeupct-configs: $(foreach config,$(ALL_MAKEUPCT_CONFS),$(config)-create-makeupct-config)


.PHONY: create-upct-configs %-create-upct-config create-makeupct-configs %-create-makeupct-config
#################################################################################

