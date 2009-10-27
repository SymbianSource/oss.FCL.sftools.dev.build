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
##
# A grouping glue makefile that runs all tests

## Purpose: Run test makefiles in parallel to ensure that they all work
## Postconditions: All postconditions for all the makefiles are satisfied

include $(FLMHOME)/flmtools.mk

$(call vsave,ALLTARGET OUTPUTPATH)
COMPONENT_ALLTARGETS:=$(RELEASEPATH)/$(FULLVARIANTPATH)/dllabiv2_1.dll
COMPONENT_GLUEMAKEFILES:=dllabiv2_1/dllabiv2_1.mk 
$(ALLTARGET):: dllbasictests
ALLTARGET:=dllbasictests

include $(FLMHOME)/grouping.flm
$(call vrestore)
