#
# Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# taggedrules.mk
# Tools for use in FLMs - enabling the output from
# rules to be logged with start and end tags.
# This is a place where one might to permit various information to
# be logged, such as timestamps and host names or process ids
#

ifndef _TAGGEDRULES_FLM_
_TAGGEDRULES_FLM_:=1

# only run recipes once by default
RECIPETRIES?=1

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
  while (( $$$$ATTEMPT <= $(RECIPETRIES) )); do \
    echo -e "<recipe name='$(1)' \
    target='$$@' host='$$$$HOSTNAME' \
    layer='$(COMPONENT_LAYER)' component='$(COMPONENT_NAME)' \
    bldinf='$(COMPONENT_META)' mmp='$(PROJECT_META)' \
    config='$(SBS_CONFIGURATION)' platform='$(PLATFORM)' \
    phase='$(MAKEFILE_GROUP)' \
    source='$(3)'>\n<![CDATA["; \
    FLM_FORCESUCCESS=$(2); \
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
         if [ "$$$$FLM_FORCESUCCESS" == "FORCESUCCESS" ]; then \
             echo "<status exit='failed' code='$$$$RV' attempt='$$$$ATTEMPT' forcesuccess='FORCESUCCESS' />"; \
             RV=0; \
         else \
             echo "<status exit='failed' code='$$$$RV' attempt='$$$$ATTEMPT' />"; \
         fi; \
       fi; \
    fi; \
    echo "</recipe>"; \
    (( ATTEMPT=$$$$ATTEMPT + 1 )); \
  done $(if $(DESCRAMBLE),2>&1 | $(DESCRAMBLE) -k $$$$$$$$); exit $$$$RV 
endef

endif
