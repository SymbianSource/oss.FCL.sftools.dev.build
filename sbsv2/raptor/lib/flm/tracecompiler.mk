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
TRACE_VARIANT_SOURCE_LIST:=$(OUTPUTPATH)/$(VARIANTPLATFORM)/$(VARIANTTYPE)/tracecompile_$(TRACE_RELEASABLE_ID)_$(UID_TC).sourcelist

# The sourcelist_grouped_write macro allows us to construct a source list file, 10 objects at a time
# to avoid limits on argument lengths and sizes on Windows.
# $1 = list of source files
# $2 = ">" or ">>" i.e. for creating the file.
define sourcelist_grouped_write
	$(call startrule,sourcelist_write) \
	$(if $1,echo -en '$(subst $(CHAR_SPACE),\n,$(strip $(wordlist 1,10,$1)))\n' $2 $$@,true) \
	$(call endrule,sourcelist_write) 
	$(if $1,$(call sourcelist_grouped_write,$(wordlist 11,$(words $1),$1),>>),)
endef

# Write the list of sources for this variant to a file
# Make the combined sourcelist for this target depend on it
# It's all to do with how make treats this file when it 
# does exist. We are forcing it evaluate the target rule here 
# even if the file is in place by making it PHONY. In other 
# words, this is forcing the variant source list to always 
# be written but later on we might not write to the combined 
# source list if it isn't going to change.
define sourcelist_write
$(TRACE_SOURCE_LIST): $(TRACE_VARIANT_SOURCE_LIST)

.PHONY:: $(TRACE_VARIANT_SOURCE_LIST)

$(TRACE_VARIANT_SOURCE_LIST): $(SOURCE) 
	$(call sourcelist_grouped_write,$(SOURCE),>)

endef

$(eval $(sourcelist_write))
$(eval $(call GenerateStandardCleanTarget,$(TRACE_VARIANT_SOURCE_LIST),,))


$(if $(FLMDEBUG),$(info <debug>Trace Compiler SOURCES: $(SOURCE)</debug>))

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


# 0. Generate a combined sourcelist from all variants. 
# 0.1 Write the combined list to a temporary file
# 0.2 Check if there are new files since the last build
#      md5 stored in the trace marker.
# 0.3 Rewrite the combined sourcelist if new sourcefiles have appeared
#      since the last build
# 1. Use pipe to send inputs to trace compiler to process
# 2. Create a hash regarding to source names and put it in marker.
# 3. Show source names that are processed by trace compiler

ifeq ($(TRACE_VER),new)
define trace_compile

$(TRACE_SOURCE_LIST):
	$(call startrule,sourcelist_combine) \
	$(GNUCAT) $(TRACE_SOURCE_LIST) $$^ 2>/dev/null | $(GNUSORT) -u > $$@.new && \
	$(GNUMD5SUM) -c $(TRACE_MARKER) 2>/dev/null ||  \
	  $(GNUCP) $$@.new $$@ \
	$(call endrule,sourcelist_combine)

$(TRACE_MARKER) : $(PROJECT_META) $(TRACE_SOURCE_LIST)
	$(call startrule,tracecompile) \
	( $(GNUCAT) $(TRACE_SOURCE_LIST); \
	  echo -en "*ENDOFSOURCEFILES*\n" ) | \
	$(JAVA_COMMAND) $(TRACE_COMPILER_START) $(if $(FLMDEBUG),-d,) --uid=$(UID_TC) --project=$(TRACE_PRJNAME) --mmp=$(PROJECT_META) --traces=$(TRACE_PATH) &&  \
	$(GNUMD5SUM) $(TRACE_SOURCE_LIST).new > $$@ 2>/dev/null && \
	{ $(GNUTOUCH) $(TRACE_DICTIONARY) $(AUTOGEN_HEADER); \
	 $(GNUCAT) $(TRACE_SOURCE_LIST) ; true ; } \
	$(call endrule,tracecompile)
endef

else # Old inteface
TRACE_COMPILER_START:=-classpath $(TRACE_COMPILER_PATH)/tracecompiler com.nokia.tracecompiler.TraceCompiler

define trace_compile

$(TRACE_SOURCE_LIST):
	$(call startrule,sourcelist_combine) \
	$(GNUCAT) $(TRACE_SOURCE_LIST) $$^ 2>/dev/null | $(GNUSORT) -u > $$@.new && \
	$(GNUMD5SUM) -c $(TRACE_MARKER) 2>/dev/null ||  \
	  $(GNUCP) $$@.new $$@ \
	$(call endrule,sourcelist_combine)

$(TRACE_MARKER) : $(PROJECT_META) $(TRACE_SOURCE_LIST)
	$(call startrule,tracecompile) \
	( echo -en "$(OLDTC_TRACE_PRJNAME)\n$(PROJECT_META)\n"; \
	  $(GNUCAT) $(TRACE_SOURCE_LIST); \
	  echo -en "*ENDOFSOURCEFILES*\n" ) | \
	$(JAVA_COMMAND) $(TRACE_COMPILER_START) $(UID_TC) &&  \
	$(GNUMD5SUM) $(TRACE_SOURCE_LIST).new > $$@ 2>/dev/null && \
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

