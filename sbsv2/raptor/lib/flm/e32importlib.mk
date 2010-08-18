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
# Import library generation macros for supported e32 base architectures
#
#


# ARM-specific Macros

define importlibtarget_prepfile_arm
  $(PREPPEDDEFFILE): $(DEFFILE)
	$(call startrule,importlibtarget_prepfile,FORCESUCCESS) \
	  $(PREPDEF) $(call dblquote,$(DEFFILE)) $(call dblquote,$(PREPPEDDEFFILE)) \
	$(call endrule,importlibtarget_prepfile)
endef

define importlibtargetversioned_arm
  $(IMPORTLIBTARGETVERSIONED_DSO): $(IMPLIBTOOL) $(PREPPEDDEFFILE)
	$(call startrule,importlibversioned,FORCESUCCESS) \
	  $(IMPLIBTOOL) \
	    --sid=0x$(if $(SID),$(SID),$(if $(UID3),$(UID3),0)) \
	    --version=$(VERSION) \
		--definput="$(PREPPEDDEFFILE)" \
		--dso=$$(call dblquote,$$@) \
		--linkas=$(call dblquote,$(LINKASVERSIONED)) \
	$(call endrule,importlibversioned)
endef

define importlibtarget_prepfile_x86
  # In x86 builds, x86-specific .def files take priority.  However, if they aren't present,
  # the build falls-back to using ARM EABI .def files.
  # In the case of the latter, further processing is required before they can be used:
  # 1: ZTI and ZTV exports are ABSENT-ed
  # 2: "St9__va_list" entries are replaced with "Pc"
  # The primary/seconday status of the .def file is deduced in the front-end - we just need
  # to react to RESOLVED_DEFFILE_SECONDARY appropriately. 

  ifneq ($(RESOLVED_DEFFILE_SECONDARY),)
    $$(eval INPUTDEFFILE:=$(INTERMEDIATEPATH)/$(TARGET).def.x86)
  
    $(INTERMEDIATEPATH)/$(TARGET).def.x86: $(DEFFILE)
	  $(call startrule,importlibtarget_prepfile_process,FORCESUCCESS) \
	    $(GNUSED) -r 's%(^\s*_ZT[I|V].*NONAME).*$$$$%\1 ABSENT%;s%St9__va_list%Pc%' < $$< > $$@ \
	  $(call endrule,importlibtarget_prepfile_process)
    
    CLEANTARGETS:=$$(CLEANTARGETS) $(INTERMEDIATEPATH)/$(TARGET).def.x86
  else
    $$(eval INPUTDEFFILE:=$(DEFFILE))
  endif

  $(PREPPEDDEFFILE): $$(INPUTDEFFILE)
	$(call startrule,importlibtarget_prepfile,FORCESUCCESS) \
	  $(PREPDEF) $(call dblquote,$$<) $(call dblquote,$$@) nodatasizes $(PREPDEF_ENTRYPOINT_PREFIX)$(ENTRYPOINT) \
	$(call endrule,importlibtarget_prepfile)
endef

define importlibtargetversioned_x86
  $(IMPORTLIBTARGETVERSIONED_DSO): $(IMPLIBTOOL) $(PREPPEDDEFFILE)
	$(call startrule,importlibversioned,FORCESUCCESS) \
	  $(IMPLIBTOOL) \
	    -m i386 \
	    --input-def "$(PREPPEDDEFFILE)"	\
	    --dllname $(call dblquote,$(LINKASVERSIONED)) \
		--output-lib $$(call dblquote,$$@) \
	$(call endrule,importlibversioned)
endef
