#!/bin/bash

# Add environment settings to user's 
# .bashrc
# .bash_profile

# Add a .pvmrc

. `dirname $0`/user.bash_profile


echo "Configuring user account $USER for sbsv2 in: $SBS_HOME"

if [ ! -d "$SBS_HOME" ]; then
	echo "SBS_HOME appears to not be set correctly: $SBS_HOME" 1>&2
	exit 1
fi

patchfile()
{
echo "Adding '$2' to $1"
grep -q '# SBS_SETTINGS' "$1"
if [ $? -eq 0 ]; then 
	sed "s%.* # SBS_SETTINGS (do not edit this line).*%$2 # SBS_SETTINGS (do not edit this line)%"  "$1" > "$1.sbsv2" &&
	mv "$1" "$1.orig" &&
	mv "$1.sbsv2" "$1"
else
	cp "$1" "$1.orig" &&
	echo "$2 # SBS_SETTINGS (do not edit this line)" >> "$1"
fi
}

# Patch the bash profile
patchfile ~/.bash_profile ". $SBS_HOME/bin/user.bash_profile"
patchfile ~/.bashrc ". $SBS_HOME/bin/user.bashrc"

if [ -f ~/.pvmrc ]; then
       cp ~/.pvmrc ~/.pvmrc.orig
fi

cp $SBS_HOME/util/install-linux/linux_pvmrc ~/.pvmrc
