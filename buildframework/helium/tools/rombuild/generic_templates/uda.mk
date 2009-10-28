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
# UDA template (Not tested yet!)
###############################################################################

uda${uda.id}: WORKDIR=$(call removedrive,${uda.output.dir})
uda${uda.id}: NAME=${uda.image.name}
uda${uda.id}: UDA_DIR=$(call removedrive,${uda.content.dir})
uda${uda.id}: UI_PLATFORM=${ui.platform}
uda${uda.id}: OPTION_LIST=WORKDIR NAME UDA_DIR
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
	
$(call add_help,uda${uda.id},t,Generates the UDA '${uda.id}')
	