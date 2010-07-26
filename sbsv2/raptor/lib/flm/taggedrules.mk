#
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
# Tools for use in FLMs - enabling the output from
# rules to be logged with start and end tags.
# This is a place where one might to permit various information to
# be logged, such as timestamps and host names or process ids
#

ifndef _TAGGEDRULES_FLM_
_TAGGEDRULES_FLM_:=1

# only run recipes once by default
RECIPETRIES?=1

ifeq ($(USE_TALON),)

##
##  Example usage:
##
#   define func
#	auto_ok:
#		$(call startrule,auto) \
#		true && \
#		true && \
#		true    \
#		$(call endrule,auto)
#	
#	auto_fail:
#		$(call startrule,auto) \
#		find /usr >/dev/null 2>&1 && \
#		false && \
#		true    \
#		$(call endrule,auto)
#   endef
#   $(eval $(func))

# $(1) is the name of the FLM function
# $(2) indicates whether the failure of this rule should be ignored (but still logged)
#      FORCESUCCESS indicates "on"
define startrule
  @set -o pipefail; RV=0; ATTEMPT=1; \
  { while (( $$$$ATTEMPT <= $(RECIPETRIES) )); do \
    echo -e "<recipe name='$(1)' \
    target='$$@' host='$$$$HOSTNAME' \
    layer='$(COMPONENT_LAYER)' component='$(COMPONENT_NAME)' \
    bldinf='$(COMPONENT_META)' mmp='$(PROJECT_META)' \
    config='$(SBS_CONFIGURATION)' platform='$(PLATFORM)' \
    phase='$(MAKEFILE_GROUP)' \
    source='$(3)'>\n<![CDATA["; \
    FLM_RECIPE_FLAGS='$(2)'; \
    export TIMEFORMAT="]]><time start='$$$$($(DATE) +%s.%N)' elapsed='%6R' />"; \
    { time { set -x;
endef

define endrule
    ; }  } 2>&1  ; RV=$$$$?; set +x; \
    if (( $$$$RV==0  )); then \
       echo "<status exit='ok' attempt='$$$$ATTEMPT' />";  \
       echo "</recipe>"; \
       break; \
    else  \
       if (( $$$$ATTEMPT < $(RECIPETRIES) )); then \
         echo "<status exit='retry' code='$$$$RV' attempt='$$$$ATTEMPT' />"; \
         sleep 1; \
       else \
         if [ ! "$$$${FLM_RECIPE_FLAGS//FORCESUCCESS/}" == "$$$${FLM_RECIPE_FLAGS}" ]; then \
             echo "<status exit='failed' code='$$$$RV' attempt='$$$$ATTEMPT' forcesuccess='FORCESUCCESS' />"; \
             RV=0; \
         else \
             echo "<status exit='failed' code='$$$$RV' attempt='$$$$ATTEMPT' />"; \
         fi; \
       fi; \
    fi; \
    echo "</recipe>"; \
    (( ATTEMPT=$$$$ATTEMPT + 1 )); \
  done ; exit $$$${RV}; } $(if $(DESCRAMBLE),2>&1 | $(DESCRAMBLE) -k $$$$$$$$) 
endef


define startrawoutput
  @ set -o pipefail; { 
endef

define endrawoutput
  ; exit 0; } $(if $(DESCRAMBLE),2>&1 | $(DESCRAMBLE) -k $$$$$$$$) 
endef


else
TALON_RECIPEATTRIBUTES:=\
 name='$$RECIPE'\
 target='$$TARGET'\
 host='$$HOSTNAME'\
 layer='$$COMPONENT_LAYER'\
 component='$$COMPONENT_NAME'\
 bldinf='$$COMPONENT_META' mmp='$$PROJECT_META'\
 config='$$SBS_CONFIGURATION' platform='$$PLATFORM'\
 phase='$$MAKEFILE_GROUP' source='$$SOURCE' $(if i$(FLMDEBUG),prereqs='$$RECIPE_PREREQS',)

export TALON_RECIPEATTRIBUTES
export TALON_RETRIES
export TALON_DESCRAMBLE

define startrule
	@|RECIPE=$1;TARGET=$$@;COMPONENT_LAYER=$(COMPONENT_LAYER);COMPONENT_NAME=$(COMPONENT_NAME);COMPONENT_META=$(COMPONENT_META);PROJECT_META=$(PROJECT_META);SBS_CONFIGURATION=$(SBS_CONFIGURATION);PLATFORM=$(PLATFORM);MAKEFILE_GROUP=$(MAKEFILE_GROUP);SOURCE=$3;TALON_FLAGS=$2;$(if $(FLMDEBUG),RECIPE_PREREQS=$$^;,)|
endef

define endrule
endef


define startrawoutput
	@|TALON_FLAGS=forcesuccess rawoutput;|
endef

define endrawoutput
endef



endif




endif
