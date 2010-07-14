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

# Test all nodes in a cluster
# arguments are the list of nodes.

NODELIST="$@"

for i in $NODELIST; do
	ssh $i "ls -l /tmp/pvm.$UID"
done

for i in $NODELIST; do
	(
	echo "spawn -($i) -> /bin/hostname"
	echo "spawn -($i) -> $PVM_ROOT/bin/LINUX/pvmgmake_pvm"
	echo "quit"
	) | pvm
done



