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

include $(E32ROMCFG)/$(COREPLAT_NAME)/fota_config.mk

makeupctcore${core.id}${image.type}: TYPE=${image.type}
makeupctcore${core.id}${image.type}: NAME=${core.image.name}.core.fota.conf
makeupctcore${core.id}${image.type}: WORKDIR=$(call removedrive,${core.output.dir})
makeupctcore${core.id}${image.type}: MAKEUPCT_PACKAGE_SIZE_MAX=15000000
makeupctcore${core.id}${image.type}: MAKEUPCT_SW_RELEASE_VERSION=${core.version.info}
makeupctcore${core.id}${image.type}: OPTION_LIST=TYPE NAME WORKDIR MAKEUPCT_PACKAGE_SIZE_MAX MAKEUPCT_SW_RELEASE_VERSION MAKEUPCT_PLATFORM UPCT_NUMBER_BACKUP_BUFFERS UPCT_SOS_ISASW UPCT_RAMSIZE UPCT_SECTORSIZE UPCT_ASCIS KEYCERT_INDEX UPCT_EXTRA_PARAMETERS MAKEUPCT_PACKAGE_SIZE_MAX MAKEUPCT_SW_RELEASE_VERSION PRODUCT_TYPE UPCT_CMT_RAM_SIZE UPCT_CMT_SECTOR_SIZE UPCT_CMT_BACKUP_BLOCKS UPCT_APE_RAM_SIZE UPCT_APE_SECTOR_SIZE UPCT_APE_BACKUP_BLOCKS UPCT_CODESTART_MCUSW UPCT_APE_PRODUCT_KEY_INDEX UPCT_CMT_PRODUCT_KEY_INDEX

makeupctcore${core.id}${image.type}:
	@echo === Stage=makeupctcore${core.id}${image.type} == makeupctcore${core.id}${image.type}
	-@perl -e "print '++ Started at '.localtime().\"\n\""
	-@perl -e "use Time::HiRes; print '+++ HiRes Start '.Time::HiRes::time().\"\n\";"
	@echo =========== Configuration =================
	@echo TYPE: $(TYPE)
	@echo NAME: $(NAME)
	@echo WORKDIR: $(WORKDIR)
	@echo MAKEUPCT_SW_RELEASE_VERSION: $(MAKEUPCT_SW_RELEASE_VERSION)
	@echo ===========================================
	@echo $(CALL_IMAKER_PLATFORM) $(call transfer_option,$(OPTION_LIST)) step-MAKEUPCT_CONF_CORE
	-@$(CALL_IMAKER_PLATFORM) $(call transfer_option,$(OPTION_LIST)) step-MAKEUPCT_CONF_CORE
	-@perl -e "use Time::HiRes; print '+++ HiRes End '.Time::HiRes::time().\"\n\";"
	-@perl -e "print '++ Finished at '.localtime().\"\n\""

	
	