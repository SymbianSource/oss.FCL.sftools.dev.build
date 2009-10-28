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
# Customer template
###############################################################################

customer${customer.id}${image.type}: CUSTOMERID=${customer.id}
customer${customer.id}${image.type}: TYPE=${image.type}
customer${customer.id}${image.type}: NAME=${customer.image.name}
customer${customer.id}${image.type}: UI_PLATFORM=${ui.platform}
customer${customer.id}${image.type}: WORKDIR=$(call removedrive,${customer.output.dir})
customer${customer.id}${image.type}: VARIATION_DIRS=$(call find_variant_path,$(CUSTOMERID),$(call updatedrive,${variation.dir}))
customer${customer.id}${image.type}: CUSTOM_VARIANT_OPT= -DCUSTOMERID=$(CUSTOMERID) $(foreach dir,$(VARIATION_DIRS),-I$(dir)) -DSECTION -DUSE_MULTIROFS ${rommake.flags}
customer${customer.id}${image.type}: SOSROFS3_VERSION=${rofs3.version.info}
customer${customer.id}${image.type}: USE_VERGEN=1
customer${customer.id}${image.type}: ROFS3_FWID=${rofs3.fwid.id}
customer${customer.id}${image.type}: ROFS3_FWIDVER=${rofs3.fwid.version}
customer${customer.id}${image.type}: ENABLE_SW_STRING=1
customer${customer.id}${image.type}: CUSTOMER_SW_VERSION=${customer.template}
customer${customer.id}${image.type}: OPTION_LIST=TYPE NAME WORKDIR CUSTOM_VARIANT_OPT SOSROFS3_VERSION USE_VERGEN ROFS3_FWID ROFS3_FWIDVER ENABLE_SW_STRING CUSTOMER_SW_VERSION
customer${customer.id}${image.type}: unzip_${variation}
	@echo === Stage=customer${customer.id}${image.type} == customer${customer.id}${image.type}
	-@perl -e "print '++ Started at '.localtime().\"\n\""
	-@perl -e "use Time::HiRes; print '+++ HiRes Start '.Time::HiRes::time().\"\n\";"
	@echo =========== Configuration =================
	@echo PRODUCT             : $(PRODUCT_NAME)
	@echo TYPE                : $(TYPE)
	@echo NAME                : $(NAME)
	@echo WORKDIR             : $(WORKDIR)
	@echo OVERRIDEOBY         : $(OVERRIDEOBY)
	@echo CUSTOMERID          : $(CUSTOMERID)
	@echo CUSTOM_VARIANT_OPT  : $(CUSTOM_VARIANT_OPT)
	@echo SOSROFS3_VERSION    : $(SOSROFS3_VERSION)
	@echo CUSTOMER_SW_VERSION : $(CUSTOMER_SW_VERSION)
	@echo ===========================================
	@echo $(CALL_IMAKER) $(call transfer_option,$(OPTION_LIST)) rofs3
	-@$(CALL_IMAKER) $(call transfer_option,$(OPTION_LIST)) rofs3
	-@perl -e "use Time::HiRes; print '+++ HiRes End '.Time::HiRes::time().\"\n\";"
	-@perl -e "print '++ Finished at '.localtime().\"\n\""

$(call add_help,customer${customer.id}${image.type},t,Generates the customer variant '${customer.id}' (${image.type}))


