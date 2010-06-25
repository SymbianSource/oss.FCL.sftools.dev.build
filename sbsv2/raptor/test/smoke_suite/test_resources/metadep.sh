#!/bin/bash

# Test SBSv2 Metadata dependency generation to see if
# changing a metadata file would trigger a rebuild.

export BASH_EPOCROOT=${EPOCROOT//\\//}
export BASH_SBSHOME=${SBS_HOME//\\//}
export BASH_SBSMINGW=${SBS_MINGW//\\//}
export METAMAKEFILE=${BASH_EPOCROOT}/epoc32/build/metadata_all.mk 
export SBSMAKEFILE=${SBSMAKEFILE:-${BASH_EPOCROOT}/epoc32/build/smoketests/metadep.mk}
export SBSLOGFILE=${SBSLOGFILE:-${BASH_EPOCROOT}/epoc32/build/smoketests/metadep.log}
export SBSCOMMAND="sbs -b smoke_suite/test_resources/simple/bld.inf -n -m $SBSMAKEFILE -f $SBSLOGFILE"

# Ensure that the host type is set for Raptor:
eval $($BASH_SBSHOME/bin/gethost.sh -e)

if [ -z "$HOSTPLATFORM" ]; then
	echo "Error: HOSTPLATFORM could not be determined." 1>&2
	exit 1
fi

# N.B. The use of sleep 1 is required. If I build X, dependent on Y then
# update Y too quickly, a subsequent attempt to make X won't notice the
# change in Y.  It's not clear if this is make's fault or just the way that
# file timestamps are recorded.

if [ "$OSTYPE" = "cygwin" ]
then
export MAKECOMMAND="${BASH_SBSMINGW:-${BASH_SBSHOME}/${HOSTPLATFORM_DIR}/mingw}/bin/make"
else
export MAKECOMMAND="$BASH_SBSHOME/$HOSTPLATFORM_DIR/bin/make"
fi

echo "Step 1 - No changes, so there should be no need to rerun:"
( set -x
$SBSCOMMAND &&
sleep 1 &&
$MAKECOMMAND -rf  ${METAMAKEFILE}
)
echo ""



echo "Step 2 - Run sbs, change a bld inf, see the rerunning message"
#( set -x
$SBSCOMMAND &&
sleep 1 &&
touch smoke_suite/test_resources/simple/bld.inf &&
$MAKECOMMAND -rf  ${METAMAKEFILE}
#)
echo ""

echo "Step 3 - Run sbs, change an mmp, see the rerunning message twice"
( set -x
$SBSCOMMAND &&
sleep 1 &&
touch smoke_suite/test_resources/simple/simple.mmp &&
$MAKECOMMAND -rf  ${METAMAKEFILE}
$MAKECOMMAND -rf  ${METAMAKEFILE}
)
echo ""

