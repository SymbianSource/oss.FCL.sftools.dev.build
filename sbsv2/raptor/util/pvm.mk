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

RAPTOR_PVM_VER:=3.4.5

PVM_TAR:=$(SBS_HOME)/util/ext/pvm$(RAPTOR_PVM_VER).tgz
PVM_SOURCEDIR:=$(INSTALLROOT)/pvm3

define b_pvm
.PHONY:: pvm

all:: pvm

pvm: $(INSTALLROOT)/pvm3/console/LINUX/pvm
	
$(INSTALLROOT)/pvm3/console/LINUX/pvm: $(PVM_TAR) 
	rm -rf $(PVM_SOURCEDIR) && \
	cd $(INSTALLROOT) && \
	tar -xzf $(PVM_TAR) && \
	(  \
	cd $(PVM_SOURCEDIR) && \
	PVM_ROOT=$(PVM_SOURCEDIR) && \
	PVM_ARCH=LINUX && \
	PVM_RSH=/usr/bin/ssh && \
	export PVM_ROOT PVM_RSH PVM_ARCH && \
	$(MAKE) && $(MAKE) install \
	)
endef

$(eval $(b_pvm))
