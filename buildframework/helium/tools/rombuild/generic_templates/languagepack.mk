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
# languagepack template
###############################################################################

languagepack${languagepack.id}${image.type}: TYPE=${image.type}
languagepack${languagepack.id}${image.type}: NAME=${languagepack.image.name}
languagepack${languagepack.id}${image.type}: WORKDIR=$(call removedrive,${languagepack.output.dir})
languagepack${languagepack.id}${image.type}: LPID=${languagepack.id}
languagepack${languagepack.id}${image.type}: UI_PLATFORM=${ui.platform}
languagepack${languagepack.id}${image.type}: VARIATION_DIRS=$(call find_variant_path,$(LPID),$(call updatedrive,${variation.dir}))
languagepack${languagepack.id}${image.type}: CUSTOM_VARIANT_OPT=-DLPID=$(LPID)  $(foreach dir,$(VARIATION_DIRS),-I$(dir)) ${rommake.flags}
languagepack${languagepack.id}${image.type}: SOSROFS2_VERSION=${rofs2.version.info}
languagepack${languagepack.id}${image.type}: USE_VERGEN=1
languagepack${languagepack.id}${image.type}: ROFS2_FWID=${rofs2.fwid.id}
languagepack${languagepack.id}${image.type}: ROFS2_FWIDVER=${rofs2.fwid.version}
languagepack${languagepack.id}${image.type}: ENABLE_SW_STRING=1
languagepack${languagepack.id}${image.type}: LP_SW_VERSION_STRING=${languagepack.template}
languagepack${languagepack.id}${image.type}: RD_LOCALISATION=0
languagepack${languagepack.id}${image.type}: HELIUM_LOCALISATION=${enable.helium.lpa}
languagepack${languagepack.id}${image.type}: DEFAULT_LANGUAGE_ID=$(strip ${default})
languagepack${languagepack.id}${image.type}: LANGUAGE_IDS=$(subst $(comma), ,$(strip ${languages}))
languagepack${languagepack.id}${image.type}: OPTION_LIST=TYPE NAME WORKDIR CUSTOM_VARIANT_OPT SOSROFS2_VERSION USE_VERGEN ROFS2_FWID ROFS2_FWIDVER RD_LOCALISATION HELIUM_LOCALISATION DEFAULT_LANGUAGE_ID LANGUAGE_IDS ENABLE_SW_STRING LP_SW_VERSION_STRING
languagepack${languagepack.id}${image.type}: unzip_${variation}
	@echo === Stage=languagepack${languagepack.id}${image.type} == languagepack${languagepack.id}${image.type}
	-@perl -e "print '++ Started at '.localtime().\"\n\""
	-@perl -e "use Time::HiRes; print '+++ HiRes Start '.Time::HiRes::time().\"\n\";"
	@echo =========== Configuration =================
	@echo PRODUCT              : $(PRODUCT_NAME)
	@echo TYPE                 : $(TYPE)
	@echo NAME                 : $(NAME)
	@echo LPID                 : $(LPID)
	@echo CUSTOM_VARIANT_OPT   : $(CUSTOM_VARIANT_OPT)	
	@echo WORKDIR              : $(WORKDIR)
	@echo SOSROFS2_VERSION     : $(SOSROFS2_VERSION)
	@echo LP_SW_VERSION_STRING : $(LP_SW_VERSION_STRING)
	@echo ===========================================
	@echo $(CALL_IMAKER) $(call transfer_option,$(OPTION_LIST)) rofs2
	-@$(CALL_IMAKER) $(call transfer_option,$(OPTION_LIST)) rofs2
	-@perl -e "use Time::HiRes; print '+++ HiRes End '.Time::HiRes::time().\"\n\";"
	-@perl -e "print '++ Finished at '.localtime().\"\n\""


$(call add_help,languagepack${languagepack.id}${image.type},t,Generates the languagepack '${languagepack.id}' (${image.type}))
