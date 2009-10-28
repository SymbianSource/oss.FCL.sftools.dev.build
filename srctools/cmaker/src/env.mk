#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies). 
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Symbian Foundation License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.symbianfoundation.org/legal/sfl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description:
# environent specific variable settings
#

CPP         ?= cpp
PERL        ?= perl
BPLATWIN    := $(call iif,$(findstring cmd.exe,$(call lcase,$(SHELL))),1,$(findstring mingw,$(call lcase,$(MAKE))))
EXCLCYGWIN  := $(BPLATWIN)
NULL        := $(call iif,$(BPLATWIN),nul,/dev/null)
DONOTHING   := @$(call iif,$(BPLATWIN),rem,\#)

# Set shell; cmd.exe for Windows, otherwise use /bin/sh
SHELL       := $(call iif,$(BPLATWIN),cmd.exe,/bin/sh)
COPY	    := copy
ERASE	    := del
PRINT	    := @echo
SHELL       := cmd.exe
RMDIR       := rmdir /S /Q

# returns the filename specific to this environment 
# Replaces / \\ if needed :)
define getFile
  $(subst /,\\,$1)
endef

