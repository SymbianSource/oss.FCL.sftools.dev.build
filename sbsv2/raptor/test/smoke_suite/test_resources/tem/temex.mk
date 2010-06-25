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
#
# A test-template extension makefile
# supposed to demonstrate that different calls
# to the same template extension makefile will
# get different variable values.
# i.e. it's supposed to show target specific variables 
# working properly for template extension makefiles.

# The test is by manual comparison at the moment.



define print
echo ""
echo ""
@echo ""
@echo "EPOCROOT=$(EPOCROOT)"
@echo "PLATFORM=$(PLATFORM)"
@echo "CFG=$(CFG)"
@echo "TO_ROOT=$(TO_ROOT)"
@echo "TO_BLDINF=$(TO_BLDINF)"
@echo "EPOCBLD=$(EPOCBLD)"
@echo "EXTENSION_ROOT=$(EXTENSION_ROOT)"
@echo "HOST_SHELL=$(HOST_SHELL)"
@echo "/=$(/)"
@echo ";=$(;)"
@echo "RMDIR=$(RMDIR)"
@echo "RM=$(RM)"
@echo "ERASE=$(ERASE)"
@echo "MKDIR=$(MKDIR)"
@echo "CP=$(CP)"
@echo "PLATFORM_PATH=$(PLATFORM_PATH)"
@echo "CFG_PATH=$(CFG_PATH)"
@echo "TARGET=$(TARGET)"
@echo "SOURCE=$(SOURCE)"
@echo "TEMTARGET=$(TEMTARGET)"
@echo "TEMPLATE_EXTENSION_MAKEFILE=$(TEMPLATE_EXTENSION_MAKEFILE)"
@echo ""
@echo "Options:"
@echo "PREFIX=$(PREFIX)"
@echo "MEMMODEL=$(MEMMODEL)"
@echo "NAME=$(NAME)"
@echo ""
@echo "TEMCALLVALUE=$(TEMCALLVALUE)"
@echo "TEMCALL_TESTUNIQ_FILENAME=$(TEMCALL_TESTUNIQ_FILENAME)"
endef

# Test for duplicate calls (bad_bld.inf)
BLANK:=
SPACE:=$(BLANK) $(BLANK)
COLON:=:
TESTUNIQ:=TEMTEST_$(MEMMODEL)$(NAME)$(TARGET)$(CFG)$(PLATFORM)$(TEMTARGET)
TESTUNIQ:=$(subst /,_,$(TESTUNIQ))
TESTUNIQ:=$(subst $(SPACE),_,$(TESTUNIQ))
TESTUNIQ:=$(subst $(COLON),_,$(TESTUNIQ))
TEMCALL_TESTUNIQ_FILENAME:=$(EPOCROOT)/epoc32/build/$(TESTUNIQ).out

$(info TEMCALL_TESTUNIQ_FILENAME=$(TEMCALL_TESTUNIQ_FILENAME))
$(info TEMTARGET=$(TEMTARGET))
TEMCALLVALUE:=$(shell if [ ! -e "$(TEMCALL_TESTUNIQ_FILENAME)" ]; then echo "$(TEMCALL_TESTUNIQ_FILENAME)" > "$(TEMCALL_TESTUNIQ_FILENAME)"; echo "1";else echo "0"; fi)

ifneq ($(TEMCALLVALUE),1)
$(shell touch $(EPOCROOT)/epoc32/raptor_smoketest_tem_failed)
$(error repeated call to TEM with same values, tested with file $(TEMCALL_TESTUNIQ_FILENAME), resulting in '$(TEMCALLVALUE)' at $(shell date; cat $(TEMCALL_TESTUNIQ_FILENAME)))
else
$(shell touch $(EPOCROOT)/epoc32/raptor_smoketest_tem_succeeded)
endif

PARS:=$(PREFIX)$(MEMMODEL)$(NAME)
ifneq ($(PARS),yetanotheraonetwothreeotherstuff)
ifneq ($(PARS),1yetanother1aonetwothree1otherstuff)
$(error Unexpected TEM call parameters for this test: $(PARS))
endif
endif




DO_NOTHING : 
	@echo "DO_NOTHING"
	$(print)


MAKMAKE :
	@echo "MAKMAKE"
	$(print)

BLD :
	@echo "BLD"
	$(print)

SAVESPACE :
	@echo "SAVESPACE"
	$(print)

FREEZE :
	@echo "FREEZE"
	$(print)

LIB :
	@echo "LIB"
	$(print)

CLEANLIB :
	@echo "CLEANLIB"
	$(print)

RESOURCE :
	@echo "RESOURCE"
	$(print)

CLEAN :
	@echo "CLEAN"
	$(print)

RELEASABLES :
	@echo "RELEASABLES"
	$(print)

FINAL :
	@echo "FINAL"
	$(print)

