#
# Copyright (c) 2004-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Generate some source files
# Note that the YACC and LEX tools used expect to see Unix-style
# path names and will hang horribly if given DOS pathnames
#


YACC=bison
LEX= flex

GENERATED_FILES= \
	$(EPOCROOT)epoc32\build\generatedcpp\rcomp\rcomp.cpp \
	$(EPOCROOT)epoc32\build\generatedcpp\rcomp\rcomp.hpp \
	$(EPOCROOT)epoc32\build\generatedcpp\rcomp\rcompl.cpp

$(EPOCROOT)epoc32\build\generatedcpp\rcomp\rcompl.cpp : ..\src\rcomp.l
	perl -w -S emkdir.pl "$(EPOCROOT)epoc32\build\generatedcpp\rcomp"
	$(LEX) -t $< > $@

$(EPOCROOT)epoc32\build\generatedcpp\rcomp\rcomp.cpp $(EPOCROOT)epoc32\build\generatedcpp\rcomp\rcomp.hpp : ..\src\rcomp.y
	perl -w -S emkdir.pl "$(EPOCROOT)epoc32\build\generatedcpp\rcomp"
	$(YACC) -d -o $@ $<

do_nothing:
	@rem do nothing

#
# The targets invoked by bld...
#

# Do the work in the MAKMAKE target, in the hope of getting the files
# created in time to scan them in the processing of RCOMP.MMP

MAKMAKE : $(GENERATED_FILES)

BLD : MAKMAKE

SAVESPACE : MAKMAKE

CLEAN : 
	erase $(GENERATED_FILES)

FREEZE : do_nothing

LIB : do_nothing

CLEANLIB : do_nothing

RESOURCE : do_nothing

FINAL : do_nothing

RELEASABLES : do_nothing

