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
# Flash template
###############################################################################

flash${flash.id}${image.type}: TYPE=${image.type}
flash${flash.id}${image.type}: HWID=${rommake.hwid}
flash${flash.id}${image.type}: PLATSECBIN=${use.platsecbin}
flash${flash.id}${image.type}: UI_PLATFORM=${ui.platform}
flash${flash.id}${image.type}: USE_FOTI=$(and $(call iif,${use.foti},1,),$(call iif,$(subst rnd,,$(subst prd,,$(TYPE))),,1))
flash${flash.id}${image.type}: USE_FOTA=$(and $(call iif,${use.fota},1,),$(call iif,$(subst rnd,,$(subst prd,,$(TYPE))),,1))
flash${flash.id}${image.type}: PREBUILD_STEPS=$(call iif,$(USE_FOTI),foti,) $(call iif,$(USE_FOTA),fota,)
flash${flash.id}${image.type}: CUSTOM_CORE_OBY=${image.master.iby}
flash${flash.id}${image.type}: MOBILE_CRASH_SENDER=${enable.mobile.crash.sender}
flash${flash.id}${image.type}: NAME=${flash.image.name}
flash${flash.id}${image.type}: WORKDIR=$(call removedrive,${flash.output.dir})
flash${flash.id}${image.type}: CORE_UDEBFILE_LIST=$(subst $(comma), ,${mytraces.binaries})
flash${flash.id}${image.type}: CUSTOM_CORE_OPT=${rommake.flags}
flash${flash.id}${image.type}: SOSCORE_VERSION=${core.version.info}
flash${flash.id}${image.type}: SOSROFS1_VERSION=${rofs1.version.info}
flash${flash.id}${image.type}: SOSROFS2_VERSION=${rofs2.version.info}
flash${flash.id}${image.type}: SOSROFS3_VERSION=${rofs3.version.info}
flash${flash.id}${image.type}: USE_VERGEN=1
flash${flash.id}${image.type}: CORE_FWID=${rofs1.fwid.id}
flash${flash.id}${image.type}: CORE_FWIDVER=${rofs1.fwid.version}
flash${flash.id}${image.type}: ROFS2_FWID=${rofs2.fwid.id}
flash${flash.id}${image.type}: ROFS2_FWIDVER=${rofs2.fwid.version}
flash${flash.id}${image.type}: ROFS3_FWID=${rofs3.fwid.id}
flash${flash.id}${image.type}: ROFS3_FWIDVER=${rofs3.fwid.version}
flash${flash.id}${image.type}: ENABLE_SW_STRING=1
flash${flash.id}${image.type}: CORE_SW_VERSION_STRING=${core.template}
flash${flash.id}${image.type}: MODEL_SW_VERSION_STRING=${model.template}
flash${flash.id}${image.type}: LP_SW_VERSION_STRING=${languagepack.template}
flash${flash.id}${image.type}: CUSTOMER_SW_VERSION_STRING=${customer.template}
flash${flash.id}${image.type}: USE_ROMSYMGEN=${enable.romsymbol}
flash${flash.id}${image.type}: OPTION_LIST=TYPE HWID USE_FOTI USE_FOTA CUSTOM_CORE_OBY NAME WORKDIR CORE_UDEBFILE_LIST CUSTOM_CORE_OPT MOBILE_CRASH_SENDER SOSCORE_VERSION  SOSROFS1_VERSION SOSROFS2_VERSION SOSROFS3_VERSION CORE_FWID CORE_FWIDVER ROFS2_FWID ROFS2_FWIDVER ROFS3_FWID ROFS3_FWIDVER ENABLE_SW_STRING CORE_SW_VERSION_STRING MODEL_SW_VERSION_STRING LP_SW_VERSION_STRING CUSTOMER_SW_VERSION_STRING USE_ROMSYMGEN USE_VERGEN 
flash${flash.id}${image.type}: unzip_western
	@echo === Stage=flash${flash.id}${image.type} == flash${flash.id}${image.type}
	-@perl -e "print '++ Started at '.localtime().\"\n\""
	-@perl -e "use Time::HiRes; print '+++ HiRes Start '.Time::HiRes::time().\"\n\";"
	@echo =========== Configuration =================
	@echo PRODUCT             : $(PRODUCT_NAME)
	@echo TYPE                : $(TYPE)
	@echo NAME                : $(NAME)
	@echo USE_OVERRIDE        : $(USE_OVERRIDE)
	@echo OVERRIDEOBY         : $(OVERRIDEOBY)
	@echo CORE_OBY            : $(CORE_OBY)
	@echo BLDROM_OPTION       : $(BLDROM_OPTION)
	@echo MOBILE_CRASH_SENDER : $(MOBILE_CRASH_SENDER)
	@echo WORKDIR             : $(WORKDIR)
	@echo TRACES              : $(call iif,$(USE_UDEB),ON,OFF)
	@echo UDEBFILE_LIST       : $(UDEBFILE_LIST)
	@echo USE_FOTI            : $(call iif,$(USE_FOTI),ON,OFF)
	@echo USE_FOTA            : $(call iif,$(USE_FOTA),ON,OFF)
	@echo PREBUILD_STEPS      : $(PREBUILD_STEPS)
	@echo SOSCORE_VERSION     : $(SOSCORE_VERSION)
	@echo SOSROFS1_VERSION    : $(SOSROFS1_VERSION)	
	@echo SOSROFS2_VERSION    : $(SOSROFS2_VERSION)
	@echo SOSROFS3_VERSION    : $(SOSROFS3_VERSION)
	@echo ENABLE_ROMSYMBOL    : $(ENABLE_ROMSYMBOL)
	@echo ===========================================
	-@$(if $(strip $(PREBUILD_STEPS)),@echo $(CALL_IMAKER_PLATFORM) $(PREBUILD_STEPS),)
	-@$(if $(strip $(PREBUILD_STEPS)),$(CALL_IMAKER_PLATFORM) $(PREBUILD_STEPS),)
	-@echo $(CALL_IMAKER) $(call transfer_option,$(OPTION_LIST)) flash
	-@$(CALL_IMAKER) $(call transfer_option,$(OPTION_LIST)) flash
	-@perl -e "use Time::HiRes; print '+++ HiRes End '.Time::HiRes::time().\"\n\";"
	-@perl -e "print '++ Finished at '.localtime().\"\n\""



$(call add_help,flash${flash.id}${image.type},t,Generates the flash '${flash.id}' (${image.type}))
