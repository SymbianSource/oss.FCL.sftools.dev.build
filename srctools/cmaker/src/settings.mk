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
# 
#

TIMESTAMP   ?= $(shell $(PERL) -e 'use POSIX "strftime"; print(strftime("%Y%m%d%H%M%S", localtime))')

E32ROM      := $(EPOC32)/rom
E32ROMCFG   := $(E32ROM)/config
E32ROMBLD   := $(EPOC32)/rombuild
VERBOSE     := 1

SPP_TOOLS   = \TOOLS
CENREP_TOOLS=$(SPP_TOOLS)\cenrep_scripts
