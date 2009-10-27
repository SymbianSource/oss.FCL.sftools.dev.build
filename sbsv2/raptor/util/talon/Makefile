# Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Utility makefile 
#
#


SHELL:=bash

include $(SBS_HOME:\=/)/util/gccprogram.mk

ifeq ($(filter win,$(HOSTPLATFORM)),win)
PROCESS_C:=process_win.c
CFLAGS:=-DHOST_WIN
LDFLAGS:=$(subst \,/,$(SBS_HOME:\=/)\win32\mingw\lib\libiberty.a)
else
PROCESS_C:=process.c
CFLAGS:=-g
linux_PTHREADLIBS:=-lpthread
LDFLAGS:=$(linux_PTHREADLIBS) -lrt
endif


SOURCEDIR:=$(subst \,/,$(SBS_HOME))/util/talon


# remember how to clean up:
MANIFEST:=$(SOURCEDIR)/manifest

TARGET:=talon
SOURCES:=$(addprefix $(SOURCEDIR)/,talon.c buffer.c sema.c log.c $(PROCESS_C))
#$(info $(cprogram))
$(eval $(cprogram))

TARGET:=talonctl
SOURCES:=$(addprefix $(SOURCEDIR)/,talonctl.c sema.c log.c)
$(eval $(cprogram))

TARGET:=testbuffer
SOURCES:=$(addprefix $(SOURCEDIR)/,testbuffer.c buffer.c log.c)
$(eval $(cprogram))

TARGET:=testprocess
SOURCES:=$(addprefix $(SOURCEDIR)/,testprocess.c buffer.c log.c  $(PROCESS_C))
$(eval $(cprogram))

TARGET:=talonlock
SOURCES:=$(addprefix $(SOURCEDIR)/,lock.c sema.c log.c)
$(eval $(cprogram))

