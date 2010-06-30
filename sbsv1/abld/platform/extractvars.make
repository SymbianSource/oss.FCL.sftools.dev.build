# Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
# 
# Contributors:
#

include $(CONFIG_FILE)

all:
	echo PREFIXFILE=$(PREFIXFILE)
	echo VFP2MODE_OPTION=$(VFP2MODE_OPTION)
	echo UNDEFINED_SYMBOL_REF_OPTION=$(UNDEFINED_SYMBOL_REF_OPTION)
	echo PREINCLUDE_OPTION=$(PREINCLUDE_OPTION)
	echo PREINCLUDE_OPTION_FCLOGGER=$(PREINCLUDE_OPTION_FCLOGGER)
	echo VFP2MODE_OPTION=$(VFP2MODE_OPTION)
	echo TRANASM=$(TRANASM)
	echo RUNTIME_LIBS_LIST=$(RUNTIME_LIBS_LIST)
	echo COMPILER_INCLUDE_PATH=$(COMPILER_INCLUDE_PATH)
	echo VERSION=$(VERSION)
	echo VERSION_INFO=$(VERSION_INFO)
	echo COMPILER_PLAT=$(COMPILER_PLAT)
	echo FC_LOGGER_INCLUDE_OPTION=$(FC_LOGGER_INCLUDE_OPTION)
	echo FC_LOGGER_DICTIONARY_FILE_NAME=$(FC_LOGGER_DICTIONARY_FILE_NAME)
	echo FC_LOGGER_GENERATED_C_FILE_NAME=$(FC_LOGGER_GENERATED_C_FILE_NAME)
	echo COMMANDFILE_OPTION=$(COMMANDFILE_OPTION)
	echo VIA_FILE_PREFIX=$(VIA_FILE_PREFIX)
	echo VIA_FILE_SUFFIX=$(VIA_FILE_SUFFIX)
	echo STATIC_LIBS_LIST=$(STATIC_LIBS_LIST)
	echo STATIC_LIBRARY_PATH=$(STATIC_LIBRARY_PATH)
	echo STATIC_LIBS=$(STATIC_LIBS)
	echo OE_EXE_LIBS=$(OE_EXE_LIBS)
	echo OE_EXE_LIBS_WCHAR=$(OE_EXE_LIBS_WCHAR)
	echo OE_IMPORT_LIBS=$(OE_IMPORT_LIBS)
	echo OPTION_PREFIX=$(OPTION_PREFIX)
	echo CCFLAGS=$(CCFLAGS)
	echo SYM_NEW_LIB=$(SYM_NEW_LIB)
	echo OE_NEW_LIB=$(OE_NEW_LIB)
