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
# Function Like Makefile (FLM): Shared macros for resource.flm
#
#
###############################################################################

###############################################################################
# $1 is the name of the intermediate RESOURCEFILE that is to be produced
# $2 is the LANGUAGE		(eg. sc or 01 or 02 ...)
# $3 is the name of the dependency file
define resource.deps

    $(if $(FLMDEBUG),$$(info <debug>resource.deps: $1 LANG:$2 dep $3 </debug>))

    RESOURCE_DEPS:: $3
    
    # could  force deps to be generated always - debatable.
    # .PHONY: $3

    $3: $(SOURCE)
	$(call startrule,resourcedependencies,FORCESUCCESS) \
	$(GNUCPP) -DLANGUAGE_$(2) -DLANGUAGE_$(subst sc,SC,$2) $(call makemacrodef,-D,$(MMPDEFS))\
	$(CPPOPT) $(SOURCE) -M -MG -MT"$1" | \
	$$(DEPENDENCY_CORRECTOR) >$3 \
	$(call endrule,resourcedependencies)

    SOURCETARGET_$(call sanitise,$(SOURCE)): $3

    CLEANTARGETS:=$$(CLEANTARGETS) $3

endef # resource.deps #

###############################################################################

# Must be a separate macro since we 
define resource.decideheader
      DOHEADER:=
      ifeq ($(HEADLANG),$2)
        ifneq ($(RESOURCEHEADER),)
          RESOURCE:: $(RESOURCEHEADER)

          DOHEADER:=-h$(RESOURCEHEADER)

          # we will add the resourceheader to RELEASABLES globally
        endif

      else
        # Use the headlang resource (in primaryfile) as the dependency 
        # "leader" for this resource
        $1: $(PRIMARYFILE)
      endif
endef

# $1 is the name of the intermediate RESOURCEFILE
# $2 is the LANGUAGE		(eg. sc or 01 or 02 ...)
# Uses $(RESOURCEHEADER),$(SOURCE),$(HEADLANG),$(MMPDEFS) apart from some tools
define resource.build
    $(if $(FLMDEBUG),$$(info <debug>resource.build: $1 LANG:$2 </debug>))

    $(eval $(resource.decideheader))

    ifneq ($(DOHEADER),)
        # Strictly speaking if $1 is made then the header file should be there too
        # but suppose someone adds a header statement to their MMP after doing a build?
        # so here we recreate the resource header if its missing even if the intermediate resource
        # has actually been built.  The problem is: what if the rpp file is not there (oops)? 
        # So this is not perfect but I think that the situation is fairly unlikely.
        # We can afford to put in an if statement for the rsg file - it's not a race condition because
        # $1 is done and the build engine guarantees that it's there so no resource header
        # can be attempted while we're trying to test.
        $(RESOURCEHEADER) : $1
	    $(call startrule,resourcecompile.headerfill,FORCESUCCESS) \
	    if [ ! -f "$(RESOURCEHEADER)" ]; then $(GNUCPP)  -DLANGUAGE_$2 \
	      -DLANGUAGE_$(subst sc,SC,$(2)) $(call makemacrodef,-D,$(MMPDEFS))\
	      $(CPPOPT) $(SOURCE) -o $1.rpp; fi && \
	    if [ ! -f "$(RESOURCEHEADER)" ]; then $(RCOMP) -m045,046,047 -u -h$$@ -s$1.rpp; fi \
	    $(call endrule,resourcecompile.headerfill)
    endif



    RESOURCE:: $1
    
    $1: $(SOURCE)
	$(call startrule,resourcecompile,FORCESUCCESS) \
	$(GNUCPP)  -DLANGUAGE_$2 -DLANGUAGE_$(subst sc,SC,$(2)) $(call makemacrodef,-D,$(MMPDEFS))\
	$(CPPOPT) $(SOURCE) -o $1.rpp && \
	$(RCOMP) -m045,046,047 -u $(DOHEADER) -o$$@ -s$1.rpp \
	$(call endrule,resourcecompile)

    SOURCETARGET_$(call sanitise,$(SOURCE)): $1
    CLEANTARGETS:=$$(CLEANTARGETS) $1 $1.rpp 
endef # resource.build

###############################################################################
# $1 is the name of the intermediate RESOURCEFILE
# $2 is the target name (without path) of the final resource file
define resource.makecopies
  
  $(call copyresource,$1,$(sort $(addsuffix /$2,$(RSCCOPYDIRS))))
endef


###############################################################################
# $1 is the intermediate filename base (eg. /epoc32/build/xxx/b_)
# $2 is the LANGUAGE		(eg. sc or 01 or 02 ...)
define resource.headeronly
  ifeq "$(MAKEFILE_GROUP)" "RESOURCE_DEPS"
    # generate the resource header dependency files
    $(eval DEPENDFILENAME:=$1_$2.rsg.d)

    RESOURCE_DEPS:: $(DEPENDFILENAME)
        
    # could  force deps to be generated always - debatable.
    # .PHONY: $(DEPENDFILENAME)
   
    $(DEPENDFILENAME): $(SOURCE)
	$(call startrule,resource.headeronly.deps,FORCESUCCESS) \
	$(GNUCPP) -DLANGUAGE_$2 -DLANGUAGE_$(subst sc,SC,$2) $(call makemacrodef,-D,$(MMPDEFS))\
	$(CPPOPT) $(SOURCE) -M -MG -MT"$(RESOURCEHEADER)" | \
	$$(DEPENDENCY_CORRECTOR) > $$@ \
	$(call endrule,resource.headeronly.deps)
   
    SOURCETARGET_$(call sanitise,$(SOURCE)): $(DEPENDFILENAME)
   
    CLEANTARGETS:=$$(CLEANTARGETS) $(DEPENDFILENAME)
  else # generate the resource header

    RESOURCE:: $(RESOURCEHEADER)
    
    $(RESOURCEHEADER): $(SOURCE)
	$(call startrule,resource.headeronly,FORCESUCCESS) \
	$(GNUCPP)  -DLANGUAGE_$2 -DLANGUAGE_$(subst sc,SC,$(3)) $(call makemacrodef,-D,$(MMPDEFS))\
	$(CPPOPT) $(SOURCE) -o $1_$2.rsg.rpp && \
	$(RCOMP) -m045,046,047 -u -h$$@ -s$1_$2.rsg.rpp \
	$(call endrule,resource.headeronly)

    CLEANTARGETS:=$$(CLEANTARGETS) $1_$2.rsg.rpp
    # we will add the resourceheader to RELEASABLES globally
    # individual source file compilation
    
    SOURCETARGET_$(call sanitise,$(SOURCE)): $(RESOURCEHEADER)
    
    $(eval DEPENDFILE:=$(wildcard $(DEPENDFILENAME)))
    
    ifneq "$(DEPENDFILE)" ""
      ifeq "$(filter %CLEAN,$(call uppercase,$(MAKECMDGOALS)))" ""
         -include $(DEPENDFILE)
      endif
    endif
  endif
endef # resource.headeronly #


###############################################################################
define copyresource
# $(1) is the source
# $(2) is the space separated list of destinations which must be filenames

   RELEASABLES:=$$(RELEASABLES) $(2)

   $(info <finalcopy source='$1'>$2</finalcopy>)
 
endef # copyresource #
