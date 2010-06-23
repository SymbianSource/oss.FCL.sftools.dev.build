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
# Simple TEM that generates trivial release tree files

BLD:
	echo "simple_extension $(PLATFORM) $(CFG) $(CONTENT)" > $(EPOCROOT)/epoc32/release/$(PLATFORM_PATH)/$(CFG_PATH)/simple_extension.txt
	
CLEAN:
	rm -f $(EPOCROOT)/epoc32/release/$(PLATFORM_PATH)/$(CFG_PATH)/simple_extension.txt

RELEASABLES:
	@echo $(EPOCROOT)/epoc32/release/$(PLATFORM_PATH)/$(CFG_PATH)/simple_extension.txt

SAVESPACE: BLD

MAKMAKE RESOURCE LIB CLEANLIB FINAL FREEZE:
