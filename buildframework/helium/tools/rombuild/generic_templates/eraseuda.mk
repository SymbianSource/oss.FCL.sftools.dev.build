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
# Erase UDA template
###############################################################################

eraseuda${image.type}: WORKDIR=$(call removedrive,${eraseuda.output.dir})
eraseuda${image.type}: NAME=${eraseuda.image.name}
eraseuda${image.type}: TYPE=${image.type}
eraseuda${image.type}: UI_PLATFORM=${ui.platform}
eraseuda${image.type}: OPTION_LIST=WORKDIR NAME TYPE
eraseuda${image.type}:
	@echo === Stage=mceraseuda == mceraseuda
	-@perl -e "print '++ Started at '.localtime().\"\n\""
	-@perl -e "use Time::HiRes; print '+++ HiRes Start '.Time::HiRes::time().\"\n\";"
	@echo =========== Configuration =================
	@echo PRODUCT : $(PRODUCT_NAME)
	@echo WORKDIR : $(WORKDIR)
	@echo NAME    : $(NAME)
	@echo TYPE    : $(TYPE)
	@echo ===========================================
	@echo $(CALL_IMAKER) $(call transfer_option,$(OPTION_LIST)) udaerase
	-@$(CALL_IMAKER) $(call transfer_option,$(OPTION_LIST)) udaerase
	-@perl -e "use Time::HiRes; print '+++ HiRes End '.Time::HiRes::time().\"\n\";"
	-@perl -e "print '++ Finished at '.localtime().\"\n\""
 
$(call add_help,eraseuda${image.type},t,Generates the uda erase (${image.type}))
