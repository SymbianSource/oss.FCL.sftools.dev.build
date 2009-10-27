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

BVCPP_TAR:=$(SBS_HOME)/util/ext/bv.tgz


define b_bvcpp

.PHONY:: bvcpp

all:: bvcpp

bvcpp: $(INSTALLROOT)/bv/bin/cpp

$(INSTALLROOT)/bv/bin/cpp: $(BVCPP_TAR)
	cd $(INSTALLROOT) && \
	rm -rf bv && \
	tar -xzf $(BVCPP_TAR)&& touch $$@

endef

$(eval $(b_bvcpp))




