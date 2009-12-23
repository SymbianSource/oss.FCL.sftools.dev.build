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

if [ -f ~/.bashrc ] ; then
	. ~/.bashrc
fi
MODULE_VERSION="$(module --version 2>&1)"
if [ "$?" == "0" ] ; then
    module load "java/1.6.0"
    module load "tww/ant/1.7.1"
fi
export TEMP="/tmp/$USER"

export ANT_ARGS="-lib ../lib -lib ../../lib -lib ../../bin/helium-logging.jar -lib ../../antlibs -listener com.nokia.helium.logger.ant.listener.StatusAndLogListener"
ant $*
