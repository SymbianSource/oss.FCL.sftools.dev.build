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
# Build bash 3.2 for SBSv2
#


RAPTOR_BASH_VER:=4.0

BASH_SOURCEDIR:=$(OUTPUTPATH)/bash-$(RAPTOR_BASH_VER)
BASH_TAR:=$(SBS_HOME)/util/ext/bash-$(RAPTOR_BASH_VER).tar.gz
BASH_PATCHES_TAR:=$(SBS_HOME)/util/ext/bash-$(RAPTOR_BASH_VER)-patches.tar.gz

define b_bash
.PHONY:: bash

all:: bash 

bash: $(INSTALLROOT)/bin/bash

$(INSTALLROOT)/bin/bash: $(BASH_TAR) $(BASH_PATCHES_TAR)
	rm -rf $(BASH_SOURCEDIR) && \
	cd $(OUTPUTPATH) && \
	tar -xzf $(BASH_TAR) &&  \
	(  \
	cd $(BASH_SOURCEDIR) && \
	mkdir patches && (cd patches && tar -xzf $(BASH_PATCHES_TAR)) && \
	for p in patches/*; do if [ -f $p ]; then patch -p0 < $$$$p; fi; done && \
	CFLAGS="-O2 $(GCCTUNE) -s" ./configure --prefix=$(INSTALLROOT) --enable-arith-for-command --enable-multibyte --enable-job-control --enable-progcomp --enable-process-substitution  --enable-readline --disable-rpath && \
	$(MAKE) && $(MAKE) install \
	) ; \
	cp $$@ $$(dir $$@)/sh
	
endef

$(eval $(b_bash))
