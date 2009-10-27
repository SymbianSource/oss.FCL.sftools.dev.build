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
# Run Trace Compiler on source files to generate trace headers and decode files
#

TRACE_PRJNAME:=$(basename $(notdir $(PROJECT_META)))
# Find out TRACE_PATH
TRACE_PATH:=$(strip $(foreach DIR,$(USERINCLUDE),$(filter %/traces_$(TRACE_PRJNAME),$(DIR))))
ifeq ($(TRACE_PATH),)
TRACE_PATH:=$(strip $(foreach DIR,$(USERINCLUDE),$(filter %/traces,$(DIR))))
endif

# Run trace compiler only if TRACE_PATH exists
ifneq ($(TRACE_PATH),)
TRACE_MARKER:=$(TRACE_MARKER_PATH)/tracecompile_$(TRACE_PRJNAME)_$(UID_TC).done
TRACE_HEADERS:=

TRACE_SOURCE_LIST:=$(TRACE_MARKER_PATH)/tracecompile_$(TRACE_PRJNAME)_$(UID_TC).sourcelist

# 1. Append to or create the list of source files for trace compiler to process
# 2. Check if the hash in trace marker remain unchanged. If not, remove marker so trace compiler will run again. 
X:=$(shell set -x ; $(GNUMKDIR) -p $(TRACE_MARKER_PATH) ; $(GNUTOUCH) $(TRACE_SOURCE_LIST) ; echo -e "$(subst $(CHAR_SPACE),\\n,$(SOURCE))" | $(GNUSORT) -u $(TRACE_SOURCE_LIST) - > $(TRACE_SOURCE_LIST).tmp && $(GNUMV) $(TRACE_SOURCE_LIST).tmp $(TRACE_SOURCE_LIST) ; $(GNUMD5SUM) -c $(TRACE_MARKER) || $(GNURM) $(TRACE_MARKER))

$(if $(FLMDEBUG),$(info <debug>Trace Compiler sourcelist generation output: $(X)</debug>))

$(TRACE_MARKER) : $(SOURCE)

ifeq ($(GUARD_$(call sanitise,$(TRACE_MARKER))),)
GUARD_$(call sanitise,$(TRACE_MARKER)):=1

JAVA_COMMAND:=$(SBS_JAVATC)
TRACE_COMPILER_PATH:=$(EPOCROOT)/epoc32/tools
TRACE_COMPILER_START:=-classpath $(TRACE_COMPILER_PATH)/tracecompiler com.nokia.tracecompiler.TraceCompiler

TRACE_HEADERS:=$(foreach SRC,$(SOURCE),$(TRACE_PATH)/$(basename $(notdir $(SRC)))Traces.h)

# 1. Use pipe to send inputs to trace compiler to process
# 2. Create a hash regarding to source names and put it in marker.
# 3. Show source names that are processed by trace compiler
define trace_compile
$(TRACE_MARKER) : $(PROJECT_META)
	$(call startrule,tracecompile) \
	( echo -en "$(TRACE_PRJNAME)\n$(PROJECT_META)\n"; \
	  $(GNUCAT) $(TRACE_SOURCE_LIST); \
	  echo -en "*ENDOFSOURCEFILES*\n" ) | \
	$(JAVA_COMMAND) $(TRACE_COMPILER_START) $(UID_TC) && \
	$(GNUMD5SUM) $(TRACE_SOURCE_LIST) > $(TRACE_MARKER) ; \
	$(GNUCAT) $(TRACE_SOURCE_LIST) \
	$(call endrule,tracecompile)
endef

$(eval $(trace_compile))

$(eval $(call GenerateStandardCleanTarget,$(TRACE_HEADERS) $(TRACE_PATH)/tracebuilder.cache $(TRACE_MARKER) $(TRACE_SOURCE_LIST),,))

# End sanity guard
endif

else
# Indicate to following parts of the FLM that we actually won't run
# trace compiler so they can set dependencies accordingly.
USE_TRACE_COMPILER:=
endif

