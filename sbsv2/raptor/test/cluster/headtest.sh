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

(
echo "Date and time check:"
echo "    The numbers following each hostname are the date and time in seconds"
echo "    They should all be the same otherwise make errors may occur during builds."
echo "    "`hostname`' '`date +%s`
for i in $NODELIST; do
	ssh $i 'echo "    "`hostname`' '`date +%s`'&
done
)



for i in $NODELIST; do
	ssh $i "NODELIST=\"$NODELIST\" $SBS_HOME/test/cluster/nodetest.sh"
done


