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

# Default settings.  You may override these by specifying a setup script
# as the first commandline argument
#
H=$HOME
export H
export EPOCROOT="$H/baselineos"
export LOGBASEDIR=~/public_html/buildlogs
export BUILDROOT="$H/baselineos"
export SOURCEROOT="$H/baselineos/fsupdate"
export SYSDEF="$H/baselineos/system_definition_fsupdate.xml"
export PREEXPORTSYSDEF="$SBS_HOME/test/envelope/preexport.xml"
export PLATFORMS="-c armv5"
export PARALLEL=46
export SYNCSBSSOURCE=""
export UNSPLITDIRS="$SBS_HOME/unsplitdirs.py"

# Do we want to attempt to build a ROM?
export DOROMBUILD=""
export ROMFILLIN_EPOCROOT=$BUILDROOT/rom_fillin
#  We need to specify the OBY file (must be generated on windows)
export ROMOBYFILE="$BUILDROOT/h4hrp_001.techview.oby" 

# Do you have server that runs evalid automatically?
export SENDTOEVALIDSERVER=""
#  The following should be mounted:
export EVALIDSERVERMOUNT="/mnt/evalidserver"
export USERBUILDID=""


# Allow overrides to this default config
if [ ! -z $1 ]; then 
	if [ -f "$1" ]; then
		. $1
	else
		echo "You must supply a build type as the first parameter - this should be a setup script"
		exit 1
	fi
fi


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
if [ ! -z "$USERBUILDID" ]; then
	BUILDNAME="$USERBUILDID-$BUILDNAME"
fi
export LOGNAME="${BUILDNAME}_${KEY}"

for BUILDNUM in {1..50}; do
	if [ ! -d "$DAILYDIR/$BUILDNUM" ]; then
		break
	fi
	if [ -z "`echo $DAILYDIR/$BUILDNUM/*_BUILDNUM.log*`" ]; then
		break
	fi
done

OUTDIR="$DAILYDIR/$BUILDNUM"
export TESTLOG="$OUTDIR/test.log"

# make the day's directory
mkdir -p "$OUTDIR"

echo "testrun: $TESTLOG, build $BUILDNUM of the day:"
echo '<testrun>' > "$TESTLOG"

echo "Parallel: $PARALLEL"
(
echo "<test type='performance' name='speedtest' >"
echo "	<parameters parallel='$PARALLEL' start='`date`' />"
echo "	<logfile>$DAILYDIR/$BUILDNUM/${LOGNAME}_$BUILDNUM.log</logfile>"
MAKEFILE=$EPOCROOT/epoc32/build/Makefile
echo ""

TIMELOG="$OUTDIR/${LOGNAME}_$BUILDNUM.time"

echo "	<build number='$BUILDNUM' of='$KEY' output='$OUTDIR'><![CDATA["
if [ ! -d "$OUTDIR" ]; then
	mkdir -p "$OUTDIR" || exit 1
fi
set -x

(
if [ ! -z "$SYNCSBSSOURCE" ]; then
	echo "Checking out Raptor source to $SBS_HOME"
	p4 -u timothymurphy sync $SBS_HOME/...
else
	echo "NOT Checking out Raptor source"
fi
chmod a+x $SBS_HOME/bin/* # ensure permissions were set
)


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
	set -x
	unzip -o $BUILDROOT/epoc32.zip  | grep "epoc32/" | sed 's#.* \(epoc32/.*\)#\1#' |  xargs -n 1 --replace bash -c "if [ -f '{}' ]; then touch '{}'; fi" && 
	unzip -o $BUILDROOT/variant.zip  | grep "epoc32/" | sed 's#.* \(epoc32/.*\)#\1#' |  xargs -n 1 --replace bash -c "if [ -f '{}' ]; then touch '{}'; fi" &&
	set +x
) > "$OUTDIR/unzip" &&
chmod -R u+rw "$EPOCROOT/epoc32" &&
echo "unzipped skeleton epoc32 tree" 
)


# (re)Initialise the cluster if required.
(
if [ ! -z "$PARALLEL" ]; then
	echo "Setting up cluster"
	echo "Parallel: $PARALLEL"
	set -x
	echo -e "halt\n" | pvm >/dev/null
	echo -e "quit\n" | pvm $BUILDROOT/pvmhosts.$PARALLEL >/dev/null
	set +x
else
	echo "Parallel: 0 - no cluster setup"
	set -x
	echo -e "halt\n" | pvm >/dev/null
	set +x
fi
)


set +x
echo "Prepping makefiles"
(
	echo "<times>\n"
	export TIMEFORMAT="<time stage='prepmake'>%3R</time>\n"
	time $SBS_HOME/bin/sbs -d -k -s "$SYSDEF" -a "$SOURCEROOT" $PLATFORMS -n > $OUTDIR/${LOGNAME}_$BUILDNUM.meta 2>&1 
	#time cp performance_Makefile $MAKEFILE
)  > "$TIMELOG" 2>&1
echo "Running Make"
(
	# The build process
	export TIMEFORMAT="<time stage='make' parallel='$PARALLEL'>%3R</time>\n"

	time /opt/symbian/make-pvm-381/pvmgmake -j$PARALLEL -k -f $MAKEFILE  > "$OUTDIR/${LOGNAME}_$BUILDNUM.log"  2>&1 
	touch "$SIGNALTOSTOPFILE"
	echo "</times>\n"
) >> "$TIMELOG" 2>&1 & 
(
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
#set +x
#genstats "$OUTDIR/${LOGNAME}_$BUILDNUM"
(
	echo "UNSPLITTING DIRECTORIES"
        set -x
        cd $EPOCROOT/epoc32 &&
        python $UNSPLITDIRS -l . &&
        set +x

) && (
	if [ ! -z "$DOROMBUILD" ]; then
		echo "Building ROM"
		set -x
		cd $EPOCROOT &&
        	unzip -o $BUILDROOT/data.zip >/dev/null &&
		python $BUILDROOT/oby_tolinux.py < "$ROMOBYFILE" >PROCESSED_H4HRP_001.TECHVIEW.OBY
		$EPOCROOT/epoc32/tools/rombuild -type-safe-link PROCESSED_H4HRP_001.TECHVIEW.OBY
		cp
		set +x
	else
		echo "NOT Building ROM"
	fi
)

(
	if [ ! -z "$SENDTOEVALIDSERVER" ]; then
        	echo "Sending epoc32/release and epoc32/data to the evalidserver"
		set -x
		ZIPFILE="$DAILYDIR/$BUILDNUM/${LOGNAME}_$BUILDNUM.zip"
		cd $EPOCROOT &&
		find epoc32/release epoc32/data | zip "$ZIPFILE" -@ >/dev/null 2>&1 &&
		cp "$ZIPFILE" /mnt/evalidserver 
		set +x
	else
        	echo "NOT sending epoc32/release and epoc32/data to the evalidserver"
	fi
)

# Zip the logs - note that test.log should not be zipped since the output from the zip goes into it
(
	echo "Zipping logs..."
	set -x
	cd $OUTDIR &&
	zip ${LOGNAME}_${BUILDNUM}_logs.zip *.time *.meta *.log *.preexport -x test.log
	set +x
)


echo "	]]></build>"
echo "</test>"
) >> "$TESTLOG" 2>&1

BUILDNUM=$[ $BUILDNUM + 1 ]
# use a new output directory
echo -e "<testrun_stat endtime='`date`'\n />" >> "$TESTLOG"
echo "</testrun>" >> "$TESTLOG"
