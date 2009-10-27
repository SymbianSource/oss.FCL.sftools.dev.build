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

RAPTOR_PVMGMAKE_VER:=0.9.4-rpt

PVMGMAKE_SOURCEDIR:=$(OUTPUTPATH)/pvmgmake-$(RAPTOR_PVMGMAKE_VER)
PVMGMAKE_TAR:=$(SBS_HOME)/util/ext/pvmgmake-$(RAPTOR_PVMGMAKE_VER).tgz


define b_pvmgmake
.PHONY:: pvmgmake

all:: pvmgmake

pvmgmake: $(INSTALLROOT)/bin/pvmgmake pvm
	
$(INSTALLROOT)/bin/pvmgmake: $(PVMGMAKE_TAR) 
	rm -rf $(PVMGMAKE_SOURCEDIR) && \
	cd $(OUTPUTPATH) && \
	tar -xzf $(PVMGMAKE_TAR) && \
	(  \
	cd $(PVMGMAKE_SOURCEDIR) && \
	PVM_ROOT=$(INSTALLROOT)/pvm3 && \
	PVM_ARCH=LINUX && \
	PVM_RSH=/usr/bin/ssh && \
	export PVM_ROOT PVM_RSH PVM_ARCH && \
	./configure --program-prefix=pvmg --prefix=$(INSTALLROOT) --libexecdir=$$$$PVM_ROOT/bin/LINUX --with-pvm --disable-job-server --enable-case-insensitive-file-system && \
	$(MAKE) -j8 && $(MAKE) install \
	)
endef

$(eval $(b_pvmgmake))
