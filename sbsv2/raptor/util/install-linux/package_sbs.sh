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
# Package into a linux .run file
#
#

getopts 's' packopt


export packtype=binary
if [[ "$packopt" == "s" ]]; then
packtype=source
fi

echo "Raptor packager for Linux"
export PACKAGER_HOME="$PWD"

echo "SBS_HOME is $SBS_HOME - this is the version that will be packaged."

export FULLVERSION=`$SBS_HOME/bin/sbs -v` # this also generates all the pyc files
export VERSION=`echo "$FULLVERSION" | sed 's#.*sbs version *\([^ ]*\).*#\1#'`

if [ -z "$VERSION" ]; then
	echo "Version could not be automatically determined - check that SBS_HOME is set correctly" 1>&2
	exit 1
else
	echo "Packaging version $FULLVERSION"
fi

HOSTPLATFORM_DIR=$($SBS_HOME/bin/gethost.sh -d)

if [[ "$packtype" == "source" ]]; then
HOSTPLATFORM_DIR="linux_source"
fi


export DIRNAME=sbs-$VERSION-$HOSTPLATFORM_DIR
export TMPSBS=/tmp/$DIRNAME
if [ -d  "$TMPSBS" ]; then
	rm -rf "$TMPSBS"
fi
set -x
mkdir -p "$TMPSBS" &&
(
BINARIES="$HOSTPLATFORM_DIR"
if [[ "$packtype" == "source" ]]; then
BINARIES=""
fi


   cd $SBS_HOME && find license.txt RELEASE-NOTES.html bin lib notes $BINARIES python test schema util |
	grep -v "$TMPSBS"'/python/\.py$' |
	grep -v 'flm/test'  |
	grep -v 'util/build'  | 
	grep -v 'test/epocroot/epoc32/build'  | 
	grep -v '~$'  |  cpio -o --quiet  2>/dev/null 
) | ( cd "$TMPSBS" && cpio -i --make-directories  --quiet >/dev/null 2>&1)

# store the version number
echo "FULLVERSION=\"$FULLVERSION\"" > $TMPSBS/.version
echo "VERSION=\"$VERSION\"" >> $TMPSBS/.version

if [[ "$packtype" == "binary" ]]; then
chmod a+x $TMPSBS/bin/* $TMPSBS/util/$HOSTPLATFORM_DIR/bin/* $TMPSBS/util/$HOSTPLATFORM_DIR/python262/bin/* 
chmod a+x $TMPSBS/util/pvm3/bin/LINUX/*
chmod a+x $TMPSBS/util/$HOSTPLATFORM_DIR/cw_build470msl19/release/Symbian_Tools/Command_Line_Tools/*
fi

cd $TMPSBS/.. && bash "$PACKAGER_HOME"/makeself.sh $DIRNAME $DIRNAME.run "$FULLVERSION\n" ./bin/install_raptor.sh

