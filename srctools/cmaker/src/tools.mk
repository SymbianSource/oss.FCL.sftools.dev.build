ifneq ($(TOOLS_INCLUDE),done)
#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies). 
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Symbian Foundation License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.symbianfoundation.org/legal/sfl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description:
# Actions that can be executed
#
TOOLS_INCLUDE=done

test_makefiles:
	$(foreach makefile,$(MAKEFILE_LIST),\
		$(call println,$(makefile)))



EPOC32      := $(subst \,/,$(EPOCROOT))epoc32
E32TOOLS    := $(EPOC32)/tools
E32MAKEFILES:= $(EPOC32)/tools/cmaker


include $(E32MAKEFILES)/utils.mk
include $(E32MAKEFILES)/env.mk
include $(E32MAKEFILES)/settings.mk
include $(E32MAKEFILES)/functions.mk

endif
