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
# Helium additional support for UDA creation.
###############################################################################
# Customisable variables.
HELIUM_UDA=0
UDA_CONTENT_DIRS=
UDA_CONTENT_SIS=
UDA_EXCLUDE_FILE=$(UDA_CPDIR)/private/100059C9/excludelist.txt
UDA_SW_STRING_FILE="$(UDA_CPDIR)/Resource/Versions/User Content Package_UDA.txt"
UDA_SW_STRING=my version

7ZIP_TOOL=$(call iif,$(USE_UNIX),7za,7za.exe)
INTERPRETSIS_TOOL=/epoc32/tools/$(call iif,$(USE_UNIX),interpretsis,interpretsis.exe)
INTERPRETSIS_HAL_CONFIG=

###############################################################################
# 
helium_grab_content=$(shell perl -e "use File::Find; use File::Spec; File::Find::find(\&wanted, $$ARGV[0]); sub wanted(){my $$name = File::Spec->abs2rel($$File::Find::name, $$ARGV[0]); $$name =~ s/ /?/g; print $$name.' ';}" $1)
helium_abs2rel=$(shell perl -e "use File::Spec; print File::Spec->abs2rel($$ARGV[0], $$ARGV[1]);" "$1" "$2")
###############################################################################
#
ifeq ($(HELIUM_UDA),1)

CLEAN_CREATE_UDA_DIR = echo | Deleting $(UDA_CPDIR)\n | del | $(UDA_CPDIR)
BUILD_CREATE_UDA_DIR = echo | Creating $(UDA_CPDIR)\n | mkdir | $(UDA_CPDIR)

CLEAN_UDA_GATHER_CONTENT = 
BUILD_UDA_GATHER_CONTENT = $(foreach content,$(UDA_CONTENT_DIRS),\
	| echo | Adding $(content)/*.zip\n | cmd | if exist $(content)/*.zip unzip -o $(content)/*.zip -d $(UDA_CPDIR)\
	| echo | Adding $(content)/*.rar\n | cmd | if exist $(content)/*.rar $(7ZIP_TOOL) x -y -o$(UDA_CPDIR) $(content)/*.rar)

###############################################################################
# interpretsis integration
CLEAN_UDA_GATHER_SIS_CONTENT = 
BUILD_UDA_GATHER_SIS_CONTENT = $(foreach content,$(UDA_CONTENT_SIS), | echo | Adding $(content)\n | cmd | \
 $(INTERPRETSIS_TOOL) -z / -c $(UDA_CPDIR) $(if $(INTERPRETSIS_HAL_CONFIG), -i $(INTERPRETSIS_HAL_CONFIG)) -s $(content))


# using xcopy.
#cmd | xcopy /E /R /F /Y $(subst /,\,$(content)) $(subst /,\,$(UDA_CPDIR)))

###############################################################################
#
CLEAN_UDA_CREATE_EXCLUDE_FILE =
BUILD_UDA_CREATE_EXCLUDE_FILE = echo | Creating $(UDA_EXCLUDE_FILE)\n \
 	| mkdir | $(dir $(UDA_EXCLUDE_FILE)) \
 	| write | $(UDA_EXCLUDE_FILE) | | \
 	| write | $(UDA_EXCLUDE_FILE) \
 	| $(call peval,use File::Find; my $$append= ""; File::Find::find(\&wanted, $(call pquote,$(UDA_CPDIR))); \
 	    return $$append; sub wanted(){$$append .= "C:\\\".File::Spec->abs2rel($$File::Find::name, $(call pquote,$(UDA_CPDIR)))."\n";})
 	  
###############################################################################
#
CLEAN_UDA_CREATE_SW_STRING =
BUILD_UDA_CREATE_SW_STRING = echo | Creating $(UDA_SW_STRING_FILE)\n \
 | mkdir | $(dir "$(UDA_SW_STRING_FILE)") | writeu | $(UDA_SW_STRING_FILE) | $(call quote,$(UDA_SW_STRING))


# Prepending Helium UDA specific functionalities
SOS.UDA.STEPS := CREATE_UDA_DIR UDA_GATHER_SIS_CONTENT UDA_GATHER_CONTENT UDA_CREATE_SW_STRING UDA_CREATE_EXCLUDE_FILE $(SOS.UDA.STEPS)
endif
###############################################################################
