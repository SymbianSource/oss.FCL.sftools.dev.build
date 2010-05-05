# Copyright (c) 2009-2010 Nokia Corporation and/or its subsidiary(-ies).
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

# Expected inputs:
# TARGETEXT

# Set project name as <mmp_name>
TRACE_PRJNAME:=$(basename $(notdir $(PROJECT_META)))
OLDTC_TRACE_PRJNAME:=$(TRACE_PRJNAME)
TRACE_RELEASABLE_ID:=$(TARGET)_$(TARGETEXT)

define get_trace_path
$(firstword $(filter %$1, $(USERINCLUDE) $(SYSTEMINCLUDE)))
endef

$(if $(FLMDEBUG),$(info <debug>INCLUDES=$(USERINCLUDE) $(SYSTEMINCLUDE)</debug>))
$(if $(FLMDEBUG),$(info <debug>TARGET=$(TARGET) TARGETEXT=$(TARGETEXT)</debug>))

# Find out TRACE_PATH  by looking for the trace folder in SYSTEMINCLUDE and USERINCLUDES
# traces/traces_<target_name>_<target_extension>
TRACE_PATH:=$(call get_trace_path,/traces/traces_$(TRACE_RELEASABLE_ID))
ifneq ($(TRACE_PATH),)
  TRACE_PRJNAME:=$(TRACE_RELEASABLE_ID)
else # obsolete forms for compatibility
  # traces_<target_name>_<target_ext>
  TRACE_PATH:=$(call get_trace_path,/traces_$(TARGET)_$(TARGETEXT))
  ifneq ($(TRACE_PATH),)
    # set project name as <target_name>_<target_ext> instead of <mmp_name>
    # to trick old TCom into finding the path.
    OLDTC_TRACE_PRJNAME:=$(TARGET)_$(TARGETEXT)
  else
    # traces_<target_name>_<target_type>
    TRACE_PATH:=$(call get_trace_path,/traces_$(TARGET)_$(TARGETTYPE))
    ifneq ($(TRACE_PATH),)
      # set project name as <target_name>_<target_type> instead of <mmp_name>
      # to trick old TCom into finding the path.
      OLDTC_TRACE_PRJNAME:=$(TARGET)_$(TARGETTYPE)
    else
      # traces_<mmp_name>
      TRACE_PATH:=$(call get_trace_path,/traces_$(TRACE_PRJNAME))
   
      # traces
      ifeq ($(TRACE_PATH),)
       TRACE_PATH:=$(call get_trace_path,/traces)
      endif
    endif
  endif
endif


# initialise (so what output will be correct if we don't actually run the TC)
TRACE_DICTIONARY:=
AUTOGEN_HEADER:=
$(if $(FLMDEBUG),$(info <debug>TRACE_PATH='$(TRACE_PATH)'   TRACE_RELEASABLE_ID='$(TRACE_RELEASABLE_ID)'</debug>))

# Run trace compiler only if TRACE_PATH exists
ifneq ($(TRACE_PATH),)
TRACE_MARKER:=$(TRACE_MARKER_PATH)/tracecompile_$(TRACE_RELEASABLE_ID)_$(UID_TC).done
TRACE_HEADERS:=

TRACE_SOURCE_LIST:=$(TRACE_MARKER_PATH)/tracecompile_$(TRACE_RELEASABLE_ID)_$(UID_TC).sourcelist

# 1. Append to or create the list of source files for trace compiler to process
# 2. Check if the hash in trace marker remain unchanged. If not, remove marker so trace compiler will run again. 
X:=$(shell set -x ; $(GNUMKDIR) -p $(TRACE_MARKER_PATH) ; $(GNUTOUCH) $(TRACE_SOURCE_LIST) ; echo -e "$(subst $(CHAR_SPACE),\\n,$(SOURCE))" | $(GNUSORT) -u $(TRACE_SOURCE_LIST) - > $(TRACE_SOURCE_LIST).tmp && $(GNUMV) $(TRACE_SOURCE_LIST).tmp $(TRACE_SOURCE_LIST) ; $(GNUMD5SUM) -c $(TRACE_MARKER) || $(GNURM) $(TRACE_MARKER))

$(if $(FLMDEBUG),$(info <debug>Trace Compiler sourcelist generation output: $(X)</debug>))

$(TRACE_MARKER) : $(SOURCE)

TRACE_HEADERS:=$(foreach SRC,$(SOURCE),$(TRACE_PATH)/$(basename $(notdir $(SRC)))Traces.h)

$(TRACE_HEADERS): $(TRACE_MARKER)

ifeq ($(GUARD_$(call sanitise,$(TRACE_MARKER))),)
GUARD_$(call sanitise,$(TRACE_MARKER)):=1

$(if $(FLMDEBUG),$(info <debug>PAST MARKER='$(TRACE_RELEASABLE_ID)'</debug>))
# The trace compiler likes to change . into _ so we must do the same in the case of mmps with a name like
# fred.prd.mmp we want fred_prd
TRACE_PRJNAME_SANITISED:=$(subst .,_,$(TRACE_PRJNAME))
OLDTC_TRACE_PRJNAME_SANITISED:=$(subst .,_,$(OLDTC_TRACE_PRJNAME))


JAVA_COMMAND:=$(SBS_JAVATC)
TRACE_COMPILER_PATH:=$(EPOCROOT)/epoc32/tools

# declare the trace_compile macro but only do it once in the build
ifeq ($(trace_compile),)

# Find out which macro to declare - the one supporting the new CLI 
# or the old one.  First try to find TraceCompilerMain.class 
# If it is there then it might be the new posix-like interface
TRACE_VER:=
TRACE_VSTR:=

TCClass:=$(wildcard  $(TRACE_COMPILER_PATH)/tracecompiler/com/nokia/tracecompiler/TraceCompilerMain.class)
ifneq ($(TCClass),) 
# Get the version string from the TC (assume it's the new one)
TRACE_COMPILER_START:=-classpath $(TRACE_COMPILER_PATH)/tracecompiler com.nokia.tracecompiler.TraceCompilerMain
TRACE_VSTR:=$(firstword $(subst TraceCompiler version ,,$(shell $(JAVA_COMMAND) $(TRACE_COMPILER_START) --version)))
# check if it looks like a version that supports the new cli interface: supporting up to verion 9 in the future.
TRACE_VER:=$(findstring new,$(foreach version,2 3 4 5 6 7 8 9,$(patsubst $(version).%,new,$(TRACE_VSTR))))
endif
$(if $(FLMDEBUG),$(info <debug>TRACE_VSTR=$(TRACE_VSTR) TRACE_VER=$(TRACE_VER)</debug>))

ifeq ($(TRACE_VER),new)
define trace_compile
$(TRACE_MARKER) : $(PROJECT_META)
	$(call startrule,tracecompile) \
	( $(GNUCAT) $(TRACE_SOURCE_LIST); \
	  echo -en "*ENDOFSOURCEFILES*\n" ) | \
	$(JAVA_COMMAND) $(TRACE_COMPILER_START) $(if $(FLMDEBUG),-d,) --uid=$(UID_TC) --project=$(TRACE_PRJNAME) --mmp=$(PROJECT_META) --traces=$(TRACE_PATH) &&  \
	$(GNUMD5SUM) $(TRACE_SOURCE_LIST) > $(TRACE_MARKER) && \
	{ $(GNUTOUCH) $(TRACE_DICTIONARY) $(AUTOGEN_HEADER); \
	 $(GNUCAT) $(TRACE_SOURCE_LIST) ; true ; } \
	$(call endrule,tracecompile)
endef

else # Old inteface
TRACE_COMPILER_START:=-classpath $(TRACE_COMPILER_PATH)/tracecompiler com.nokia.tracecompiler.TraceCompiler
# 1. Use pipe to send inputs to trace compiler to process
# 2. Create a hash regarding to source names and put it in marker.
# 3. Show source names that are processed by trace compiler
define trace_compile
$(TRACE_MARKER) : $(PROJECT_META)
	$(call startrule,tracecompile) \
	( echo -en "$(OLDTC_TRACE_PRJNAME)\n$(PROJECT_META)\n"; \
	  $(GNUCAT) $(TRACE_SOURCE_LIST); \
	  echo -en "*ENDOFSOURCEFILES*\n" ) | \
	$(JAVA_COMMAND) $(TRACE_COMPILER_START) $(UID_TC) &&  \
	$(GNUMD5SUM) $(TRACE_SOURCE_LIST) > $(TRACE_MARKER) && \
	{ $(GNUTOUCH) $(TRACE_DICTIONARY) $(AUTOGEN_HEADER); \
	 $(GNUCAT) $(TRACE_SOURCE_LIST) ; true ; } \
	$(call endrule,tracecompile)
endef

# End - new/old trace compiler
endif

# End - tracecompile is defined
endif

ifeq ($(TRACE_VER),new)
TRACE_DICTIONARY:=$(EPOCROOT)/epoc32/ost_dictionaries/$(TRACE_PRJNAME_SANITISED)_0x$(UID_TC)_Dictionary.xml
AUTOGEN_HEADER:=$(EPOCROOT)/epoc32/include/platform/symbiantraces/autogen/$(TRACE_PRJNAME_SANITISED)_0x$(UID_TC)_TraceDefinitions.h
else
TRACE_DICTIONARY:=$(EPOCROOT)/epoc32/ost_dictionaries/$(OLDTC_TRACE_PRJNAME_SANITISED)_0x$(UID_TC)_Dictionary.xml
AUTOGEN_HEADER:=$(EPOCROOT)/epoc32/include/internal/symbiantraces/autogen/$(OLDTC_TRACE_PRJNAME_SANITISED)_0x$(UID_TC)_TraceDefinitions.h
endif

$(eval $(trace_compile))

$(eval $(call GenerateStandardCleanTarget, $(TRACE_PATH)/tracebuilder.cache $(TRACE_MARKER) $(TRACE_SOURCE_LIST),,))

$(call makepath,$(TRACE_PATH) $(dir $(TRACE_DICTIONARY) $(AUTOGEN_HEADER)))
# End  - guard that prevents repeated calls to TCom
endif

$(eval $(call GenerateStandardCleanTarget,$(TRACE_HEADERS),,))

# End - Nothing to trace (not trace path in include)
else
# Indicate to following parts of the FLM that we actually won't run
# trace compiler so they can set dependencies accordingly.
USE_TRACE_COMPILER:=
endif

