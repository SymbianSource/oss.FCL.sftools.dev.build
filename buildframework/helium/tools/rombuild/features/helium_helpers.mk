#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
###############################################################################
# Helium additional helpers for iMaker.
###############################################################################

# helper to remove the drive letter on the absolute path.
# e.g $(call removedrive,Z:\epoc32\tools) => \epoc32\tools
removedrive=$(shell perl -e "$$v = '$(strip $(subst \,/,$1))'; $$v =~ s/^.:\//\//; print $$v;")

# Get current drive letter
getdrive=$(shell perl -e "use Cwd; $$v = getcwd();  if ($$v =~ /^(.:)/) {print $$1;}")
# update drive letter in the path
updatedrive=$(shell perl -e "$$v = '$(strip $(subst \,/,$1))'; $$v =~ s/^.:/$$ARGV[0]/; print $$v;" $(call getdrive))

hasdrive=$(shell perl -e "if ($$v =~ /^.:/) {print qq(1);} else {print qq(0);}")
# Only update the drive if it doesn't exist
# e.g. $(call addmissingdrive,\epoc32\tools) => Z:\epoc32\tools
#      $(call addmissingdrive,K:\epoc32\tools) => K:\epoc32\tools even if the current drive is Z
addmissingdrive=$(call iif,$(call hasdrive,$1),$1,$(call updatedrive,$1))

###############################################################################
