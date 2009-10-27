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

CODEWARRIOR_TAR:=$(SBS_HOME)/util/ext/cw_build470msl19.tgz


define b_codewarrior

.PHONY:: codewarrior

all:: codewarrior

codewarrior: $(INSTALLROOT)/cw_build470msl19/release/Symbian_Tools/Command_Line_Tools/mwccsym2
	
$(INSTALLROOT)/cw_build470msl19/release/Symbian_Tools/Command_Line_Tools/mwccsym2: $(CODEWARRIOR_TAR)
	cd $(INSTALLROOT) && \
	tar -xzf $(CODEWARRIOR_TAR) && touch $$@
endef

$(eval $(b_codewarrior))




