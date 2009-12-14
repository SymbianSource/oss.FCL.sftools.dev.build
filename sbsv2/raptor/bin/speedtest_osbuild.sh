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
export EPOCROOT="$H/baselineos"
export LOGBASEDIR=~/public_html/buildlogs
export BUILDROOT="$H/baselineos"
export SOURCEROOT="$H/baselineos/fsupdate"
export SYSDEF="$H/baselineos/system_definition_fsupdate.xml"
export PREEXPORTSYSDEF="$SBS_HOME/test/envelope/preexport.xml"
#export PARALLEL=0

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
export TESTLOG="$DAILYDIR/parallel_speedtest.log"

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
#for PARALLEL in 52 48 44 40 36 32 28 24 20 16 8 4; do
for PARALLEL in 44 40 36 32 28 24 20 16 8 4; do
export PARALLEL  i
echo "Parallel: $PARALLEL"
(
echo "<test type='performance' name='speedtest' >"
echo "	<parameters parallel='$PARALLEL' start='`date`' />"
echo "	<logfile>$DAILYDIR/$BUILDNUM/${LOGNAME}_$BUILDNUM.log</logfile>"
MAKEFILE=$TESTBASE/test$CODEFACTOR.mk
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


echo "EPOCROOT is $EPOCROOT"
export PATH=$EPOCROOT/epoc32/tools:$PATH

(
echo "Annihilating epoc32 tree(s)"
# wipe the epoc32 directory first
chmod -R u+rw "$EPOCROOT/epoc32" &&
rm -rf "$EPOCROOT/epoc32" &&
echo "epoc32 tree withered" 
) 
(
# unzip the pre-prepared epoc32 trees
cd $EPOCROOT && 	
(
	unzip -o $BUILDROOT/epoc32.zip  | grep "epoc32/" | sed 's#.* \(epoc32/.*\)#\1#' | xargs touch && 
	unzip -o $BUILDROOT/variant.zip  | grep "epoc32/" | sed 's#.* \(epoc32/.*\)#\1#' | xargs touch
) > "$OUTDIR/unzip" &&
chmod -R u+rw "$EPOCROOT/epoc32" &&
echo "unzipped skeleton epoc32 tree" 
) && (
echo "Pre-export"
$SBS_HOME/bin/sbs  -d -k -s "$PREEXPORTSYSDEF" -a "$SOURCEROOT" -c $PLATFORM EXPORT > $OUTDIR/${LOGNAME}_$BUILDNUM.preexport 2>&1 || {
	echo "Pre-export failed";
	exit 1
}
)

echo "Prepping makefiles"
(
	echo "<times>\n"
	export TIMEFORMAT=$'<time stage='prepmake'>%3R</time>\n'
	time cp performance_Makefile $EPOCROOT/epoc32/build/Makefile
)  > "$TIMELOG" 2>&1

echo "Running Make"
(
	# The build process
	 export TIMEFORMAT=$'<time stage='make' parallel='$PARALLEL'>%3R</time>\n'

	time /usr/local/raptor/make-pvm-381/pvmgmake -j$PARALLEL --debug=j -k -f $MAKEFILE  > "$OUTDIR/${LOGNAME}_$BUILDNUM.log" 2>&1 
	touch "$SIGNALTOSTOPFILE"
	echo "</times>\n"
) >> "$TIMELOG" 2>&1 & 
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
done # PARALLEL
echo -e "<testrun_stat endtime='`date`'\n />" >> "$TESTLOG"
echo "</testrun>" >> "$TESTLOG"
