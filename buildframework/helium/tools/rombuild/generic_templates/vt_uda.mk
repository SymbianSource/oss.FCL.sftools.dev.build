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
# UDA template
###############################################################################

uda${uda.id}: WORKDIR=$(call removedrive,${uda.output.dir})
uda${uda.id}: NAME=${uda.image.name}
uda${uda.id}: HELIUM_UDA=1
uda${uda.id}: UDA_CONTENT_DIRS=$(foreach content,$(subst $(comma), ,${uda.content.subdirs}),$(call removedrive,${uda.content.dir}/$(content)))
uda${uda.id}: UDA_CONTENT_SIS=$(foreach content,$(subst $(comma), ,${uda.content.sis}),$(call removedrive,$(content)))
uda${uda.id}: UDA_SW_STRING=${uda.template}
uda${uda.id}: INTERPRETSIS_TOOL=${interpretsis.tool}
uda${uda.id}: INTERPRETSIS_HAL_CONFIG=${interpretsis.hal.config}
uda${uda.id}: OPTION_LIST=WORKDIR NAME HELIUM_UDA UDA_CONTENT_DIRS UDA_SW_STRING UDA_CONTENT_SIS WINIMAGE_TOOL INTERPRETSIS_TOOL INTERPRETSIS_HAL_CONFIG
uda${uda.id}:
	@echo === Stage=uda${uda.id} == uda${uda.id}
	-@perl -e "print '++ Started at '.localtime().\"\n\""
	-@perl -e "use Time::HiRes; print '+++ HiRes Start '.Time::HiRes::time().\"\n\";"
	@echo =========== Configuration =================
	@echo UDA_CONTENTDIR: $(UDA_CONTENTDIR)
	@echo WORKNAME: $(WORKNAME)
	@echo ===========================================
	@echo $(CALL_IMAKER_PLATFORM) $(call transfer_option,$(OPTION_LIST)) uda
	-@$(CALL_IMAKER_PLATFORM) $(call transfer_option,$(OPTION_LIST)) uda
	-@perl -e "use Time::HiRes; print '+++ HiRes End '.Time::HiRes::time().\"\n\";"
	-@perl -e "print '++ Finished at '.localtime().\"\n\""
	