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
# Clean up any output files from temex.mk
# prior to it being executed.
# no other way to do this!


#find works properly on Samba in case insensitive mode 
# with -iname whereas shell globbing doesn't  
# i.e. rm TARGETNAME* doesn't work but this does

#find  $(EPOCROOT)/epoc32/build/ -iname 'TEMTEST_*.out' -exec rm \{\} \; ; true
define clean
rm $(EPOCROOT)/epoc32/build/TEMTEST_*  $(EPOCROOT)/epoc32/build/temtest_* $(EPOCROOT)/epoc32/raptor_smoketest_tem_failed $(EPOCROOT)/epoc32/raptor_smoketest_tem_succeeded ; true
endef

DO_NOTHING: 
	@echo "DO_NOTHING"


MAKMAKE:
	@echo "MAKMAKE"
	$(clean)

BLD:
	@echo "BLD"
	$(clean)


SAVESPACE:
	@echo "SAVESPACE"
	$(clean)


FREEZE:
	@echo "FREEZE"
	$(clean)


LIB:
	@echo "LIB"
	$(clean)


CLEANLIB :
	@echo "CLEANLIB"
	$(clean)


RESOURCE :
	@echo "RESOURCE"
	$(clean)


CLEAN :
	@echo "CLEAN"
	$(clean)


RELEASABLES :
	@echo "RELEASABLES"
	$(clean)


FINAL :
	@echo "FINAL"
	$(clean)


