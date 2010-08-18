#
# Copyright (c) 2006-2010 Nokia Corporation and/or its subsidiary(-ies).
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

define cpp2obj
OBJECTFILE:=$(OUTPUTPATH)/$(TARGET)/$(notdir $(SOURCEFILE:.cpp=.o))
$$(OBJECTFILE): $(SOURCEFILE)
	g++ $(HOSTMACROS) $(CFLAGS) -c $(SOURCEFILE) -o $$@
	
OBJECTS:=$$(OBJECTS) $$(OBJECTFILE)

endef 

define cppprogram

all:: $(BINDIR)/$(TARGET)$(PROGRAMEXT)

$(foreach SOURCEFILE,$(SOURCES),$(cpp2obj))

$(BINDIR)/$(TARGET)$(PROGRAMEXT): $$(OBJECTS)
	g++ $(LDFLAGS) $$^ -o $$@
	
$$(shell mkdir -p $(OUTPUTPATH)/$(TARGET) $(BINDIR))

CLEANFILES:=$$(OBJECTS)
$(cleanlog)

endef

define c2obj
OBJECTFILE:=$(OUTPUTPATH)/$(TARGET)/$(notdir $(SOURCEFILE:.c=.o))
$$(OBJECTFILE): $(SOURCEFILE)
	gcc $(HOSTMACROS) $(CFLAGS) -c $(SOURCEFILE) -o $$@
	
OBJECTS:=$$(OBJECTS) $$(OBJECTFILE)

endef 


define cprogram

OBJECTS:=

all:: $(BINDIR)/$(TARGET)$(PROGRAMEXT)
	
.PHONY:: $(TARGET)
$(TARGET):: $(BINDIR)/$(TARGET)$(PROGRAMEXT)

$(foreach SOURCEFILE,$(SOURCES),$(c2obj))

$(BINDIR)/$(TARGET)$(PROGRAMEXT): $$(OBJECTS)
	gcc  $$^ $(LDFLAGS) -o $$@
	
$$(shell mkdir -p $(OUTPUTPATH)/$(TARGET))

CLEANFILES:=$$(OBJECTS)
$(cleanlog)

endef
