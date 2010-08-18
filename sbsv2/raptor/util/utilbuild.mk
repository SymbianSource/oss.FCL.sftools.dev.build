#
# Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Utility makefile 
#

CHAR_BLANK:=
CHAR_SPACE:=$(CHAR_BLANK) $(CHAR_BLANK)

HOSTPLATFORM:=$(shell $(SBS_HOME)/bin/gethost.sh)
HOSTPLATFORM_DIR:=$(shell $(SBS_HOME)/bin/gethost.sh -d)

ifeq ($(filter $(HOSTPLATFORM),win),win)
PROGRAMEXT:=.exe
HOSTMACROS:=-DHOST_WIN -DHOST_DIR=$(HOSTPLATFORM_DIR)
else
PROGRAMEXT:=
HOSTMACROS:=-DHOST_LINUX -DHOST_DIR=$(HOSTPLATFORM_DIR)
endif

GCCTUNE:=
ifeq ($(filter $(HOSTPLATFORM),x86_64),x86_64)
else
GCCTUNE:=-mtune=i686
endif

BUILDDIR:=$(subst \,/,$(SBS_HOME))/util/build
INSTALLROOT:=$(subst \,/,$(SBS_HOME))/$(HOSTPLATFORM_DIR)
BINDIR:=$(INSTALLROOT)/bin
OUTPUTPATH:=$(BUILDDIR)/$(HOSTPLATFORM_DIR)

define cleanlog
ifneq ($(CLEANMODE),)
$$(info <clean>)
$$(foreach O,$$(CLEANFILES),$$(info <file>$$(O)</file>)) 
$$(info </clean>)
endif
endef

