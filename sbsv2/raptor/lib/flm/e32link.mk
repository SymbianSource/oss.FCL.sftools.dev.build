# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
# Linking support macros for supported e32 base architectures
#
#

define e32link_genlibexpfile

  # $(1): generation type - 'exports' or 'deffile'
  #
  # 'exports' generation involves taking a list of the known exports, passing them to
  # gendef.pl to create a temporary .def file, prepdef-ing this .def file and then
  # passing this along to the import library generation tool to create the .lib.exp.
  # This is invoked for components with known interfaces that aren't making use of a .mmp
  # listed .def file
  #
  # 'deffile' generation takes the .def file used in the component build, for components
  # that either require a .def file or where a .def file is used to override default behaviour.
  # The .def file will already have been prepdef-ed during initial .def file processing, so it's
  # just a matter of running the import library generation tool on the temporary .def file to
  # create the .lib.exp
  #
  # The resultant .lib.exp is then available for use in the final link.

  ifeq ($(1),exports)  
    $(INTERMEDIATEPATH)/$(TARGET).gen.def:
	  $(call startrule,e32link_gendeffile) \
	    $(DEFGENTOOL) $(call dblquote,$$@) $(subst $(CHAR_COMMA)1$(CHAR_SEMIC),,$(AUTOEXPORTS)) \
	  $(call endrule,e32link_gendeffile)
	
    CLEANTARGETS:=$$(CLEANTARGETS) $(INTERMEDIATEPATH)/$(TARGET).gen.def
  
    $(INTERMEDIATEPATH)/$(TARGET).prep: $(INTERMEDIATEPATH)/$(TARGET).gen.def
	  $(call startrule,e32link_prepdef) \
	    $(PREPDEF) $(call dblquote,$$<) $(call dblquote,$$@) nodatasizes $(PREPDEF_ENTRYPOINT_PREFIX)$(ENTRYPOINT) \
	  $(call endrule,e32link_prepdef)

    CLEANTARGETS:=$$(CLEANTARGETS) $(INTERMEDIATEPATH)/$(TARGET).prep   
  endif

  $(INTERMEDIATEPATH)/$(TARGET).lib.exp: $(INTERMEDIATEPATH)/$(TARGET).prep
	$(call startrule,e32link_genlibexpfile) \
	  $(IMPLIBTOOL) \
	    -m i386 \
	    --input-def $(call dblquote,$$<) \
	    --dllname $(call dblquote,$(LINKASVERSIONED)) \
		-e $$(call dblquote,$$@) \
	$(call endrule,e32link_genlibexpfile)
	
  CLEANTARGETS:=$$(CLEANTARGETS) $(INTERMEDIATEPATH)/$(TARGET).lib.exp

endef
