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

GCCXML_TAR:=$(SBS_HOME)/util/ext/gccxml.tar.gz


define b_gccxml

.PHONY:: gccxml

all:: gccxml

gccxml: $(INSTALLROOT)/bin/gccxml_cc1plus
	
$(INSTALLROOT)/bin/gccxml_cc1plus: $(GCCXML_TAR)
	cd $(INSTALLROOT) && \
	tar -xzf $(GCCXML_TAR) 

endef

$(eval $(b_gccxml))




