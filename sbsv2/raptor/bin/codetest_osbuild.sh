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
# Build automation for Symbian OS with Raptor
# Author: Timothy N Murphy
# 
#

# You can edit these:
H=/home/tmurphy
export H

export TESTBASE="$H/baselineos/codetest"


export LOGBASEDIR=~/public_html/buildlogs
export BUILDROOT="$H/baselineos"
export SOURCEROOT="$H/baselineos/fsupdate"
export SYSDEF="$H/baselineos/system_definition_fsupdate.xml"
export PREEXPORTSYSDEF="$SBS_HOME/test/envelope/preexport.xml"
export PARALLEL=28

genstats() { 
if [ "$1.stats"  -ot "$1.log" ]; then
python "$SBS_HOME/bin/buildstats.py"  "$1.log" >  "$1.stats" && 
#python "$SBS_HOME/bin/failedstats.py" -m  "$1.log" >  "$1.failed"; 
(
	cd $EPOCROOT/epoc32 && find "release" > "$1.release_files" && find "build" > "$1.build_files" && find include > "$1.include_files"
)
fi;
}

cd $BUILDROOT


# Don't edit the rest:
###################################################
export KEY=`date +%d_%m_%y`
export DAILYDIR="$LOGBASEDIR/$KEY"
export BUILDNAME="`basename \"$SYSDEF\" | sed 's#\.[^.][^.]*$##'`"
export LOGNAME="${BUILDNAME}_${KEY}"
export PLATFORM=armv5
export TESTLOG="$DAILYDIR/parallel_codetest.log"

for BUILDNUM in {1..50}; do
	if [ ! -d "$DAILYDIR/$BUILDNUM" ]; then
		break
	fi
	if [ ! -f "$DAILYDIR/$BUILDNUM/${LOGNAME}_$BUILDNUM.log" ]; then
		break
	fi
done

# make the day's directory
mkdir -p "$DAILYDIR"

echo "testrun: $TESTLOG, build $BUILDNUM of the day:"
echo '<testrun>' > "$TESTLOG"


# Loop through different cluster loads
for CODEFACTOR in 1 2 3 4 5; do
export CODEFACTOR
echo "CODEFACTOR: $CODEFACTOR"
(

export EPOCROOTS=""
j=1;
while [ $j -le $CODEFACTOR ]; do
	EPOCROOTS=${EPOCROOTS}" $TESTBASE/epocroot$j"
	j=$[ $j + 1 ]
done
MAKEFILE=$TESTBASE/test$CODEFACTOR.mk


echo "<test type='performance' name='codetest' >"
echo "	<parameters codefactor='$CODEFACTOR' start='`date`' />"
echo "	<logfile>$DAILYDIR/$BUILDNUM/${LOGNAME}_$BUILDNUM.log</logfile>"
echo "	<epocroots>$EPOCROOTS</epocroots>"
echo "	<makefile>$MAKEFILE</makefile>"
echo ""

OUTDIR="$DAILYDIR/$BUILDNUM"
TIMELOG="$OUTDIR/${LOGNAME}_$BUILDNUM.time"

echo "	<build number='$BUILDNUM' of='$KEY' output='$OUTDIR'><![CDATA["
if [ ! -d "$OUTDIR" ]; then
	mkdir -p "$OUTDIR" || exit 1
fi
set -x

# Make sure that our "stop signal" is clear
SIGNALTOSTOPFILE="$OUTDIR/${LOGNAME}_$BUILDNUM.stop"
rm -f "$SIGNALTOSTOPFILE"


export PATH="$TESTBASE/epocroot1/epoc32/tools":$PATH

(
echo "Annihilating epoc32 tree(s)"
# wipe the epoc32 directory first
for e in $EPOCROOTS; do
	chmod -R u+rw "$e/epoc32" &&
	rm -rf "$e/epoc32" &&
	echo "epoc32 tree $e/epoc32 withered" 
done
) 
(
for EPOCROOT in $EPOCROOTS; do
	export EPOCROOT
	# unzip the pre-prepared epoc32 trees
	cd $EPOCROOT && 	
	unzip -o $BUILDROOT/epoc32.zip  | grep "epoc32/" | sed 's#.* \(epoc32/.*\)#\1#' | xargs touch && 
	unzip -o $BUILDROOT/variant.zip  | grep "epoc32/" | sed 's#.* \(epoc32/.*\)#\1#' | xargs touch &&
	chmod -R u+rw "$EPOCROOT/epoc32" &&
	echo "unzipped skeleton epoc32 tree" 

	echo "Pre-export"
	$SBS_HOME/bin/sbs  -d -k -s "$PREEXPORTSYSDEF" -a "$SOURCEROOT" -c $PLATFORM EXPORT > $OUTDIR/${LOGNAME}_$BUILDNUM.preexport 2>&1 || {
		echo "Pre-export failed";
		exit 1
	}
done
)

echo "Running Make"
(
	set -x
	echo "Running Make"
	# The build process

	time /usr/local/raptor/make-pvm-381/pvmgmake -j$PARALLEL --debug=j -k -f $MAKEFILE  > "$OUTDIR/${LOGNAME}_$BUILDNUM.log" 2>&1 
	touch "$SIGNALTOSTOPFILE"
) > "$TIMELOG" 2>&1 & 
(
	set +x
	# Concurrent process to continuously update statistics
	echo ""

	while [ 1 -eq 1 ]; do
		sleep 20 
		echo -n "."

		if [ -e "$SIGNALTOSTOPFILE" ]; then
			rm -f "$SIGNALTOSTOPFILE"
			break
		fi
	done
	echo ""
)
set +x
genstats "$OUTDIR/${LOGNAME}_$BUILDNUM"

echo "	]]></build>"
echo "</test>"
) >> "$TESTLOG" 2>&1

BUILDNUM=$[ $BUILDNUM + 1 ]
# use a new output directory
done # CODEFACTOR
echo -e "<testrun_stat endtime='`date`'\n />" >> "$TESTLOG"
echo "</testrun>" >> "$TESTLOG"
