#!/bin/sh

# Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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

TESTUSER="$@"
LOCALTOOLS_HOME=/opt/symbian


echo 
hostname
echo
ypwhich 
mount | grep home
ls -ld /home/$TESTUSER

ls -l $LOCALTOOLS_HOME/a616/ARM/RVCT/Programs/2.2/308/linux-pentium/armcc 
ls -l $LOCALTOOLS_HOME/make-pvm-381/pvmgmake 
ls -l $LOCALTOOLS_HOME/pvm3/bin/LINUX/pvmgmake_pvm 
ls -l $LOCALTOOLS_HOME/pvm3/bin/LINUX/pvmgmake_avg 

$LOCALTOOLS_HOME/pvm3/bin/LINUX/pvmgmake_pvm 
#$LOCALTOOLS_HOME/pvm3/bin/LINUX/pvmgmake_avg


$LOCALTOOLS_HOME/a616/ARM/RVCT/Programs/2.2/308/linux-pentium/armcc 2>&1 | grep ARM

#connectivity
for i in $NODELIST; do
	echo "Pinging $i"
	ping -c 1  $i| grep "bytes from"
done

echo "---------------------------------------------------------------------------"
