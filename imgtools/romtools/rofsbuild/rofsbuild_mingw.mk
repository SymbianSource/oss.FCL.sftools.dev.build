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
#------------------------------------------------------------------------
# Directory 
#------------------------------------------------------------------------
BASE_DIR = .\romtools\rofsbuild
BUILD_DIR = $(BASE_DIR)\build\romtools\rofsbuild
RELEASE_DIR = $(BASE_DIR)\build
SOURCE_DIR = $(BASE_DIR)
IMGLIB_DIR = ..\..\imglib
HOST_DIR = $(IMGLIB_DIR)\host
E32UID_DIR = $(IMGLIB_DIR)\e32uid
E32IMAGE_DIR = $(IMGLIB_DIR)\e32image
COMPRESS_DIR = $(IMGLIB_DIR)\compress
#------------------------------------------------------------------------
# Target and Source File Specifiers
#------------------------------------------------------------------------
TARGET = rofsbuild.exe
SOURCE = r_obey.cpp \
         r_build.cpp \
         r_rofs.cpp \
         r_driveimage.cpp \
         r_driveutl.cpp \
         rofsbuild.cpp \
         r_coreimage.cpp \
         r_smrimage.cpp \
         $(HOST_DIR)\h_utl.cpp \
         $(HOST_DIR)\h_file.cpp \
         $(HOST_DIR)\h_mem.cpp \
         $(E32UID_DIR)\e32uid.cpp \
         $(E32IMAGE_DIR)\e32image.cpp \
         $(E32IMAGE_DIR)\deflate\decode.cpp \
         $(E32IMAGE_DIR)\deflate\encode.cpp \
         $(E32IMAGE_DIR)\deflate\deflate.cpp \
         $(E32IMAGE_DIR)\deflate\inflate.cpp \
         $(E32IMAGE_DIR)\deflate\panic.cpp \
         $(E32IMAGE_DIR)\deflate\compress.cpp \
         $(COMPRESS_DIR)\byte_pair.cpp \
         $(COMPRESS_DIR)\pagedcompress.cpp \
         
#------------------------------------------------------------------------
# C++ Compiler Options
#------------------------------------------------------------------------
CC = \epoc32\gcc_mingw\bin\g++
CC_DEFINES  = __SYMBIAN32__ __TOOLS2__ __MINGW32__ _STLP_LITTLE_ENDIAN __EXE__ WIN32 _WINDOWS __TOOLS__ __TOOLS2_WINDOWS__ __SUPPORT_CPP_EXCEPTIONS__ __PRODUCT_INCLUDE__=\"${EPOCROOT}epoc32\include\variant\Symbian_OS.hrh\"
#CC_FLAGS =-g3 -O0 -w -Wall -c -mthreads
CC_FLAGS=-g -fdefer-pop -fmerge-constants -fthread-jumps -floop-optimize -fif-conversion -fif-conversion2 -fguess-branch-probability -fcprop-registers -fforce-mem -foptimize-sibling-calls -fstrength-reduce -fcse-follow-jumps  -fcse-skip-blocks -frerun-cse-after-loop  -frerun-loop-opt -fgcse  -fgcse-lm  -fgcse-sm  -fgcse-las -fdelete-null-pointer-checks -fexpensive-optimizations -fregmove -fschedule-insns  -fschedule-insns2 -fsched-interblock  -fsched-spec -fcaller-saves -fpeephole2 -freorder-blocks  -freorder-functions -fstrict-aliasing -funit-at-a-time -falign-functions  -falign-jumps -falign-loops  -falign-labels -fcrossjumping -pipe -c -Wall -W -Wno-ctor-dtor-privacy -Wno-unknown-pragmas -mthreads -O2 -Wno-uninitialized
USER_INCLUDE_DIR = $(BASE_DIR)\$(IMGLIB_DIR)\inc $(BASE_DIR)\$(COMPRESS_DIR) \
              $(BASE_DIR)\$(IMGLIB_DIR)\filesystem\include \
              $(BASE_DIR)\$(IMGLIB_DIR)\patchdataprocessor\include \
              $(BASE_DIR)\$(IMGLIB_DIR)\parameterfileprocessor\include \
              $(BASE_DIR)\$(IMGLIB_DIR)\memmap\include \
              $(BASE_DIR)\$(IMGLIB_DIR)\boostlibrary \
              
CC_INCLUDES = $(SOURCE_DIR) $(USER_INCLUDE_DIR) 
SYSTEM_INCLUDE_DIR = "${EPOCROOT}epoc32\include\tools\stlport" \
                  "${EPOCROOT}epoc32\include" \
                  "${EPOCROOT}epoc32\include\variant" \
                  "${EPOCROOT}epoc32\include\tools\stlport"
CC_FLAGS_INCLUDES_SYSTEM = $(addprefix -isystem, $(SYSTEM_INCLUDE_DIR))  
CC_FLAGS_INCLUDES_FILE = -include "${EPOCROOT}epoc32\include\gcc_mingw\gcc_mingw.h" 
CC_OPTIONS = $(addprefix -D, $(CC_DEFINES)) \
	     $(addprefix -I, $(CC_INCLUDES)) \
		 $(CC_FLAGS) \
		 $(CC_FLAGS_INCLUDES_SYSTEM) \
		 $(CC_FLAGS_INCLUDES_FILE)  

#------------------------------------------------------------------------
# Object Files, derived from source
#------------------------------------------------------------------------
BUILD_TARGET = $(addprefix $(RELEASE_DIR)\,$(TARGET))
OBJECT_FILES = $(addprefix $(BUILD_DIR)\,$(SOURCE:.cpp=.o))
SOURCE_FILES = $(addprefix $(SOURCE_DIR)\,$(SOURCE))

#------------------------------------------------------------------------
# Principal and default target
#------------------------------------------------------------------------
all: $(BUILD_DIR) $(BUILD_TARGET)

#------------------------------------------------------------------------
# Link Stage
#------------------------------------------------------------------------
LINK_LIB_DIR = $(EPOCROOT)epoc32\release\tools2\deb
LINK_OPTIONS = -L$(LINK_LIB_DIR) -L$(BASE_DIR) 
LINK_STATIC_LIB = filesystem patchdataprocessor parameterfileprocessor memmap
LINK_SYSTEM_LIB = stlport.5.1 boost_thread-mgw34-mt-1_39_win32 
LINK_LIB_OPTIONS = $(addprefix -l, $(LINK_STATIC_LIB)) $(addprefix -l, $(LINK_SYSTEM_LIB)) 
	
$(BUILD_TARGET) : $(OBJECT_FILES)
	$(CC) $(LINK_OPTIONS) -o$@ $^ -Wl,-Bstatic  $(LINK_LIB_OPTIONS)  

#------------------------------------------------------------------------
# Object File Compilation
#------------------------------------------------------------------------
$(OBJECT_FILES): $(BUILD_DIR)\\%.o: $(SOURCE_DIR)\\%.cpp
	$(CC) $(CC_OPTIONS) $< -o $@

#------------------------------------------------------------------------
# CLEAN
#------------------------------------------------------------------------
clean: 
	del $(BUILD_DIR)\*.o
	del $(BUILD_TARGET)
	del $(BUILD_DIR)\$(E32UID_DIR)\*.o
	del $(BUILD_DIR)\$(HOST_DIR)\*.o
	del $(BUILD_DIR)\$(E32IMAGE_DIR)\*.o
	del $(BUILD_DIR)\$(E32IMAGE_DIR)\deflate\*.o
	del $(BUILD_DIR)\$(COMPRESS_DIR)\*.o
	
#------------------------------------------------------------------------
# .PHONY
#------------------------------------------------------------------------
.PHONY: all clean test

$(BUILD_DIR):
	mkdir $(BUILD_DIR) 
	mkdir $(BUILD_DIR)\$(E32UID_DIR)
	mkdir $(BUILD_DIR)\$(HOST_DIR)
	mkdir $(BUILD_DIR)\$(E32IMAGE_DIR)\deflate
	mkdir $(BUILD_DIR)\$(COMPRESS_DIR)
