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
#

include settings.mk

HOSTNAME:=fred
COMPONENT_LAYER:=base
COMPONENT:=compsupp
COMPONENT_META:=compsupp.inf
PROJECT_META:=simpledll
SBS_CONFIGURATION:=armv5.fred
PLATFORM:=armv5
MAKEFILE_GROUP:=phasenone
FLM_FORCESUCCESS:=FORCESUCCESS

#HOSTNAME:=fred; COMPONENT_LAYER:=base; COMPONENT:=compsupp; COMPONENT_META:=compsupp.inf; PROJECT_META:=simpledll; SBS_CONFIGURATION:=armv5.fred; PLATFORM:=armv5; MAKEFILE_GROUP:=phasenone; FLM_FORCESUCCESS:=FORCESUCCESS


TALON_RECIPEATTRIBUTES:="target='$$@' host='$$$$HOSTNAME' layer='$(COMPONENT_LAYER)' component='$(COMPONENT_NAME)' bldinf='$(COMPONENT_META)' mmp='$(PROJECT_META)' config='$(SBS_CONFIGURATION)' platform='$(PLATFORM)' phase='$(MAKEFILE_GROUP)' FLM_FORCESUCCESS=$(FLM_FORCESUCCESS)"

.PHONY: target
	
define flm
target:
	HOSTNAME:=fred; COMPONENT_LAYER:=base; COMPONENT:=compsupp; COMPONENT_META:=compsupp.inf; PROJECT_META:=simpledll; SBS_CONFIGURATION:=armv5.fred; PLATFORM:=armv5; MAKEFILE_GROUP:=phasenone; FLM_FORCESUCCESS:=FORCESUCCESS ; echo "<recipe $(TALON_RECIPEATTRIBUTES) >"; echo;
endef


$(eval $(flm))
