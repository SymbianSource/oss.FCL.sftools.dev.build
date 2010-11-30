#!/bin/bash


# Copyright (c) 2006-2010 Nokia Corporation and/or its subsidiary(-ies).
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
# Determine hosttype
#
#

# Print out a list of host information in order of significance.
# for use within Makefiles and other scripts.
# The idea is that it should be possible to use it for simple decisions
# e.g. windows/linux and more complex ones e.g. i386/x86_64

getopts de  OPT

if [[ "${OSTYPE}" =~ "linux" || "${HOSTPLATFORM}" =~ "linux" ]]; then
	ARCH=$(uname -i)
        LIBC=$(echo /lib/libc-* | sed -r 's#.*/libc-([0-9]*)\.([0-9]*)(\.([0-9]*))?.so#libc\1_\2#')
        HOSTPLATFORM="linux ${ARCH} ${LIBC}"

	# The 32-bit platform is often compatible in the sense that
	# a) 32-bit programs can run on the 64-bit OS.
	# b) a 64-bit OS can tell the compiler to create 32-bit executables.

       	ARCH32="i386"

	# deal with ubuntu/debian:
	if [ "$ARCH" == "unknown" ]; then
		ARCH32="${ARCH}"
	fi

       	HOSTPLATFORM_DIR="linux-${ARCH}-${LIBC}"
       	HOSTPLATFORM32_DIR="linux-${ARCH32}-${LIBC}"
	
elif [[ "$OS" == "Windows_NT" ]]; then
	HOSTPLATFORM="win 32"
	HOSTPLATFORM_DIR="win32"
	HOSTPLATFORM32_DIR="win32"
else
	HOSTPLATFORM=unknown
	HOSTPLATFORM_DIR=unknown
fi

if [ "$OPT" == "e" ]; then 
	echo "export HOSTPLATFORM_DIR=$HOSTPLATFORM_DIR"
	echo "export HOSTPLATFORM32_DIR=$HOSTPLATFORM32_DIR"
	echo "export HOSTPLATFORM='$HOSTPLATFORM'"
elif [ "$OPT" == "d" ]; then 
	echo "$HOSTPLATFORM_DIR"
else
	echo "$HOSTPLATFORM"
fi
