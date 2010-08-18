#!/bin/sh
# Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Count the release binaries produced by a build
# armv5 only for the moment
#

TYPES='agt ani cpm csy dll drv esy exe fsy fxt hlp jar ldd lib loc msy nif pdd pdl prt sc tsy wsy [0-9]+'

echo "Countbinaries"
echo  ""

PATTERN='\.(('`echo "$TYPES" |sed 's# #)|(#g'`'))$'
echo "Searching for: $PATTERN"


echo -n "ARMv5 Binaries: "
find $EPOCROOT/epoc32/release/armv5 | egrep "$PATTERN" | wc
