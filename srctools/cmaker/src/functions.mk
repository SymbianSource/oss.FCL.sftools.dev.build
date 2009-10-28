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
# Actions that can be executed
#

# default action 
ACTION=export

ifeq ($(ACTION),what)
  PHONY_ACT = 1
  FUNCTION  = $(PRINT) "$@" 
endif
ifeq ($(ACTION),what_deps)
  PHONY_ACT = 1
  FUNCTION  = $(PRINT) "$<" "$@" 
endif
ifeq ($(ACTION),export)
  FUNCTION = $(COPY) "$<" "$@"
endif
ifeq ($(ACTION),clean)
  PHONY_ACT = 1
  FUNCTION = $(ERASE) "$@"
endif
