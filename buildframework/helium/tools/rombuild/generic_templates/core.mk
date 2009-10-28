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
# Core template
###############################################################################

core${core.id}${image.type}: TYPE=${image.type}
core${core.id}${image.type}: UI_PLATFORM=${ui.platform}
core${core.id}${image.type}: USE_FOTI=$(and $(call iif,${use.foti},1,),$(call iif,$(subst rnd,,$(subst prd,,$(TYPE))),,1))
core${core.id}${image.type}: USE_FOTA=$(and $(call iif,${use.fota},1,),$(call iif,$(subst rnd,,$(subst prd,,$(TYPE))),,1))
core${core.id}${image.type}: PREBUILD_STEPS=$(call iif,$(USE_FOTI),foti,) $(call iif,$(USE_FOTA),fota,)
core${core.id}${image.type}: NAME=${core.image.name}
core${core.id}${image.type}: WORKDIR=$(call removedrive,${core.output.dir})
core${core.id}${image.type}: CORE_UDEBFILE_LIST=$(subst $(comma), ,${mytraces.binaries})
core${core.id}${image.type}: SOSCORE_VERSION=${core.version.info}
core${core.id}${image.type}: SOSROFS1_VERSION=${rofs1.version.info}
core${core.id}${image.type}: USE_VERGEN=1
core${core.id}${image.type}: CORE_FWID=${rofs1.fwid.id}
core${core.id}${image.type}: CORE_FWIDVER=${rofs1.fwid.version}
core${core.id}${image.type}: ENABLE_SW_STRING=1
core${core.id}${image.type}: CORE_SW_VERSION_STRING=${core.template}
core${core.id}${image.type}: MODEL_SW_VERSION_STRING=${model.template}
core${core.id}${image.type}: ENABLE_ROMSYMBOL=${enable.romsymbol}
core${core.id}${image.type}: OPTION_LIST=TYPE HWID USE_FOTI USE_FOTA NAME WORKDIR CORE_UDEBFILE_LIST SOSCORE_VERSION SOSROFS1_VERSION USE_VERGEN CORE_FWID CORE_FWIDVER ENABLE_SW_STRING CORE_SW_VERSION_STRING MODEL_SW_VERSION_STRING
core${core.id}${image.type}: unzip_western
	@echo === Stage=core${core.id}${image.type} == core${core.id}${image.type}
	-@perl -e "print '++ Started at '.localtime().\"\n\""
	-@perl -e "use Time::HiRes; print '+++ HiRes Start '.Time::HiRes::time().\"\n\";"
	@echo =========== Configuration =================
	@echo PRODUCT              : $(PRODUCT_NAME)
	@echo TYPE                 : $(TYPE)
	@echo NAME                 : $(NAME)
	@echo WORKDIR              : $(WORKDIR)
	@echo CORE_UDEBFILE_LIST   : $(CORE_UDEBFILE_LIST)
	@echo BLDROM_OPTION        : $(BLDROM_OPTION)
	@echo USE_FOTI             : $(USE_FOTI)
	@echo USE_FOTA             : $(USE_FOTA)
	@echo PREBUILD_STEPS       : $(PREBUILD_STEPS)
	@echo SOSCORE_VERSION      : $(SOSCORE_VERSION)
	@echo SOSROFS1_VERSION     : $(SOSROFS1_VERSION)	
	@echo ENABLE_ROMSYMBOL     : $(ENABLE_ROMSYMBOL)
	@echo ===========================================
	-@$(if $(strip $(PREBUILD_STEPS)),@echo $(CALL_IMAKER_PLATFORM) $(PREBUILD_STEPS),)
	-@$(if $(strip $(PREBUILD_STEPS)),$(CALL_IMAKER_PLATFORM) $(PREBUILD_STEPS),)
	@echo $(CALL_IMAKER) $(call transfer_option,$(OPTION_LIST)) core
	-@$(CALL_IMAKER) $(call transfer_option,$(OPTION_LIST)) core
	-@perl -e "use Time::HiRes; print '+++ HiRes End '.Time::HiRes::time().\"\n\";"
	-@perl -e "print '++ Finished at '.localtime().\"\n\""


$(call add_help,core${core.id}${image.type},t,Generates the core '${core.id}' (${image.type}))