#!/bin/bash

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



module load java/1.6.0
module load mercurial
export OLDANT_ARGS="-lib ../lib -lib ../../lib -lib ../../bin/helium-core.jar -lib ../../bin/helium-sysdef.jar -lib ../../antlibs"
ant -Dant.executor.class="com.nokia.helium.core.ant.HeliumExecutor" $*
