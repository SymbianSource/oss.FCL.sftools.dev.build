
# Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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
##


SHELL:=bash

.PHONY:: all
all::

include utilbuild.mk # need general settings e.g. INSTALLROOT

ifeq ($(filter CLEAN,$(MAKECMDGOALS))$(filter clean,$(MAKECMDGOALS)),)

include gccprogram.mk

# Actual programs
include descramble/Makefile

include talon/Makefile

include ransleep/Makefile

# Some tools not built for windows
ifneq ($(filter $(HOSTPLATFORM),win),win)
ifeq ($(CLEANMODE),)
include bash.mk

include make.mk

#  Build pvm and pvmgmake later when they have been corrected
#include pvmgmake.mk

#include pvm.mk

include python.mk

include codewarrior.mk

include bvcpp.mk

include gccxml.mk

include dialog.mk
endif

endif

else


clean:
	@echo "Cleaning"
	make $(MAKEFILE) CLEANMODE:=1 | grep '<file>' |sed -r 's#.*<file>(.*)</file>.*#\1#' | (read F; while [ $$? -eq 0 ]; do rm -f "$$F"; read F; done; true )
endif
