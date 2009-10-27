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

.PHONY: all one two

all: one two

one:
	@echo ARCH=`$(PVM_ROOT)/lib/pvmgetarch`/`hostname`; hostname; /usr/local/ARM/RVCT/Programs/2.2/308/linux-pentium/armcc 

two:
	@echo ARCH=`$(PVM_ROOT)/lib/pvmgetarch`/`hostname`; hostname; /usr/local/ARM/RVCT/Programs/2.2/308/linux-pentium/armcc
