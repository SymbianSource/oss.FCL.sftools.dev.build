#!/bin/bash
# raptor script

# install sbsv2

chmod a+x "${PWD}/bin/gethost.sh"
export HOSTPLATFORM=$("$PWD/bin/gethost.sh")
export HOSTPLATFORM_DIR=$("$PWD/bin/gethost.sh" -d)

export build_utils=no
if [[ ! -d "$PWD/$HOSTPLATFORM_DIR" ]]; then
cat << MSG

The Raptor installer has determined that this computer is running:
	$HOSTPLATFORM_DIR
This platform is not directly supported by the installer.

If you proceed then the installation will attempt to build the Raptor tools for your platform.

Your system must have some tools installed:
MSG

if [ "$(which gcc)" ]; then
   echo "You appear to have gcc"
else
   echo "You DON'T appear to have gcc - please install it"
fi

if [ "$(which g++)" ]; then
   echo "You appear to have gcc-c++"
else
   echo "You DON'T appear to have gcc-c++ (also called g++) - please install it"
fi

if [ "$(which make)" ]; then
   echo "You appear to have GNU make"
else
   echo "You DON'T appear to have GNU make - please install it (version 3.81)"
fi

if [ "$(which bison)" ]; then
   echo "You appear to have GNU bison"
else
   echo "You DON'T appear to have GNU bison - please install it "
fi

if [ -f "/usr/include/ncurses.h" ]; then
   echo "You appear to have the ncurses dev libraries"
else
   echo "You DON'T appear to have the ncurses dev libraries - please install them (ncurses-dev or ncurses-devel)"
fi

echo "Do you wish to continue (Y or y for 'yes' anything else for no)?"

read X
if [[  "$X" != "y" && "$X" != "Y" ]]; then
	exit 1
else
	build_utils=yes
fi


# Build the dialog utility so that we can get started
(export SBS_HOME=$PWD;cd "$SBS_HOME/util" && echo "Building dialog utility..." && (make -k -j2 dialog> dialog_util_build.log 2>&1 && echo -e "\nBuild Complete") || (echo "Dialog utility build failed, see $PWD/dialog_util_build.log for more details"; read X; exit 1)) || exit 1

fi


export DIALOG="$PWD/$HOSTPLATFORM_DIR/bin/dialog"
chmod a+x "$DIALOG"

export SYMBIANHOME=/opt/symbian

test -w "$SYMBIANHOME"
if [[ $? -ne 0 ]]; then
SYMBIANHOME=$(echo ~)
fi

export TMPSBSDIR="$PWD"

errorexit() {
        echo -e "\nRaptor installation aborted: $1" 1>&2
	echo -e "\nInstall tmp dir is $TMPSBSDIR" 1>&2
	exit 1
	}
	

# get FULLVERSION and VERSION
export FULLVERSION=""
export VERSION=""
eval $(cat .version)


if [[ "$FULLVERSION" == "" || "$VERSION" == "" ]]; then
	errorexit "Bad install package - no version found." 
fi


export RESPONSEFILE=$PWD/.installdir
export MANIFEST=$PWD/.manifest
export SBS_HOME=$SYMBIANHOME/raptor-$(echo "$VERSION" | sed 's#\.##g')

DIALOGVER=$($DIALOG --version)

if  ! expr match "$DIALOGVER" "Version:" 2>&1 >/dev/null; then
	errorexit "Could not run the installation user interface on this version of Linux.\nPlease install the compat-glibc and compat-ncurses packages (RedHat) or the equivalent for your distribution and then try again.\n\nYou may also simply 'untar' raptor using the ' --target NewDirectory --noexec' options to this installer.\n"
fi
	

export DIALOGSBS=$DIALOG "--backtitle 'Installing $FULLVERSION'"

$DIALOGSBS --msgbox "Symbian Build System Installer\n\n$FULLVERSION" 0 0

# check what SBS_HOME
$DIALOGSBS --title "Select Symbian Home Directory" --fselect  "$SBS_HOME"  10 50   2> "$RESPONSEFILE"
SBS_HOME=$(cat "$RESPONSEFILE")


if [[ ! -d "$SBS_HOME" ]]; then
	$DIALOGSBS --yesno  "$SBS_HOME does not exist - should it be created?" 0 0; YESNO=$?
	if [[ "$YESNO" -eq 0 ]]; then
		mkdir -p "$SBS_HOME" || 
		(
			errorexit "Could not create directory $SBS_HOME"
		)
	else
		errorexit "SBSv2 Installation aborted: User chose not to create installation directory $SBS_HOME" 
	fi
else
	# check if there's a previous install and give an option to stop
	$DIALOGSBS --defaultno --yesno  "$SBS_HOME already exists - should the installation be overwritten?" 0 0; YESNO=$?
	if [[ "$YESNO" -eq 1 ]]; then
		errorexit "Not replacing existing installation." 
	fi
fi

# Install the software
echo "" >"$MANIFEST"
(tar -cf - *) | (cd $SBS_HOME && tar -xvf - > "$MANIFEST" && echo -e "\nCopying complete - press RETURN" >> "$MANIFEST") &
(
$DIALOGSBS --title "Copying SBS files" --tailbox "$MANIFEST" 20 60 
)

# Build the utilities if needed 
if [[ "$build_utils" == "yes" ]]; then
BUILDLOG=$SBS_HOME/util/util_build.log
(cd "$SBS_HOME/util" && echo "Building utilities ..." && make -k -j2  
if [[ $? -eq 0 ]]; then
	echo -e "\nBuild Complete" 
else
	echo -e "\nUtility build failed, see $BUILDLOG for more details"
	exit 1
fi
) > "$BUILDLOG" 2>&1  & (
$DIALOGSBS --title "Building utilities for $HOSTPLATFORM_DIR" --tailbox "$BUILDLOG" 20 60 
)
fi


# Force sbs to be executable:
chmod a+x "${SBS_HOME}/bin/sbs"
chmod a+x "${SBS_HOME}/bin/gethost.sh"
chmod a+x "${SBS_HOME}/bin/setup_user.sh"
chmod -R a+r "${SBS_HOME}"
chmod a+x "${SBS_HOME}/$HOSTPLATFORM_DIR/bin/"*
chmod a+x "${SBS_HOME}/$HOSTPLATFORM_DIR/bv/bin/"* 
chmod a+x "${SBS_HOME}/$HOSTPLATFORM_DIR/bv/libexec/"*/*/*


# Prepare user scripts for bashrc and bash_profile
INSTALLER="${SBS_HOME}/util/install-linux"
sed "s#__SBS_HOME__#${SBS_HOME}#" < "${INSTALLER}/linux_bash_profile" > "${SBS_HOME}/bin/user.bash_profile"
sed "s#__SBS_HOME__#${SBS_HOME}#" < "${INSTALLER}/linux_bashrc" > "${SBS_HOME}/bin/user.bashrc"

# Set symbolic Link
if [[ -L "$SYMBIANHOME/raptor" ]]; then
	rm "$SYMBIANHOME/raptor"
fi

if [[ ! -e "$SYMBIANHOME/raptor" ]]; then
	ln -s  "$SBS_HOME" "$SYMBIANHOME/raptor"
fi


$DIALOGSBS --msgbox "Raptor $VERSION\ninstallation complete" 0 0


