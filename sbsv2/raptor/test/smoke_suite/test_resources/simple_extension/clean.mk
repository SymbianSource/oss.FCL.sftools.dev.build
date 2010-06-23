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
# SBSv2 test TEM that creates a file and cleans it
# This helps to test the REALLYCLEAN mechanism 

blah:


MAKMAKE:

RESOURCE:
	
SAVESPACE: BLD

BLD:
	echo "HI" > $(EPOCROOT)/epoc32/build/tem_export_test

FREEZE:

LIB:

CLEANLIB:

FINAL:

CLEAN:
	rm -f $(EPOCROOT)/epoc32/build/tem_export_test

RELEASABLES:
