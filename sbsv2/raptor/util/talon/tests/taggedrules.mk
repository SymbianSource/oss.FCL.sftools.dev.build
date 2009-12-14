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
# Tools for use in FLMs - enabling the output from
# rules to be logged with start and end tags.
# This is a place where one might to permit various information to
# be logged, such as timestamps and host names or process ids
#

ifndef _TAGGEDRULES_FLM_
_TAGGEDRULES_FLM_:=1


TALON_RECIPEATTRIBUTES:=\
 name='$$RECIPE'\
 target='$$TARGET'\
 host='$$HOSTNAME'\
 layer='$$COMPONENT_LAYER'\
 component='$$COMPONENT_NAME'\
 bldinf='$$COMPONENT_META' mmp='$$PROJECT_META'\
 config='$$SBS_CONFIGURATION' platform='$$PLATFORM'\
 phase='$$MAKEFILE_GROUP'

export TALON_RECIPEATTRIBUTES

# only run recipes once by default
RECIPETRIES?=1
TALON_RETRIES:=$(RECIPETRIES)
export TALON_RECIPEATTRIBUTES

define startrule
	@|RECIPE=$1;TARGET=$@;COMPONENT_LAYER=$(COMPONENT_LAYER);COMPONENT_NAME=$(COMPONENT_NAME);COMPONENT_META=$(COMPONENT_META);PROJECT_META=$(PROJECT_META);SBS_CONFIGURATION=$(SBS_CONFIGURATION);PLATFORM=$(PLATFORM);MAKEFILE_GROUP=$(MAKEFILE_GROUP);|
endef

define endrule
endef

endif
