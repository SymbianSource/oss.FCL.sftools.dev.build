#!/bin/sh

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

if [ -f ~/.bashrc ] ; then
    . ~/.bashrc
fi

export PATH=$PATH:.
export OLDANT_ARGS="-lib ../lib -lib ../../lib -lib ../../core/lib -lib ../../bin/helium-core.jar -lib ../../bin/helium-imaker.jar -lib ../../antlibs"
ant $*
