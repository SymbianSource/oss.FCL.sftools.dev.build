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
# A step to generate udeb file list. e.g: my_tracefiles.txt
# CORE_UDEBFILE_LIST is a space separated list of file to be loaded as udeb.
# It automatically enable traces if any files are defined.
CORE_UDEBFILE_LIST?=
ifneq ("$(strip $(CORE_UDEBFILE_LIST))","")
CORE_UDEBFILE=$(CORE_NAME)_my_tracefiles.txt

CLEAN_CREATE_TRACE_FILE = del | $(CORE_UDEBFILE)
BUILD_CREATE_TRACE_FILE = \
  echo  | Generating trace file: $(CORE_UDEBFILE)\n | \
  write | $(CORE_UDEBFILE) | $(foreach file,$(CORE_UDEBFILE_LIST),$(strip $(file))\n)

CLEAN_AUTOTRACES += | $(CLEAN_CREATE_TRACE_FILE)
BUILD_AUTOTRACES += | $(BUILD_CREATE_TRACE_FILE)

## Integration to iMaker
CLEAN_COREPRE += $(CLEAN_AUTOTRACES)
BUILD_COREPRE += $(BUILD_AUTOTRACES)
USE_UDEB=1
endif
###############################################################################
