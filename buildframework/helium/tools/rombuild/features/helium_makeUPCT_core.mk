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
#################################################################################
# MakeUPCT .fota.conf files iMaker integration
#################################################################################

MAKEUPCT_PLATFORM=
UPCT_SOS_ISASW=
UPCT_RAMSIZE=
UPCT_SECTORSIZE=
UPCT_NUMBER_BACKUP_BUFFERS=
UPCT_EXTRA_PARAMETERS=
MAKEUPCT_PACKAGE_SIZE_MAX=
MAKEUPCT_SW_RELEASE_VERSION=

CLEAN_MAKEUPCT_CONF_CORE= echo | Deleting MakeUPCT $(WORKDIR)/$(NAME) config file\n\
	| del | $(WORKDIR)/$(NAME) 
BUILD_MAKEUPCT_CONF_CORE=echo | Creating MakeUPCT $(WORKDIR)/$(NAME) config file\n \
	| write | $(WORKDIR)/$(NAME) | SW_PLATFORM :=$(MAKEUPCT_PLATFORM)\n\
	$(if $(UPCT_SOS_ISASW),SW_MCUSW :=$(UPCT_SOS_ISASW)\n)\
	$(if $(UPCT_RAMSIZE),SW_APE_RAMSIZE :=$(UPCT_RAMSIZE)\n)\
	$(if $(UPCT_SECTORSIZE),SW_APE_SIZE_OF_BACKUP_BUFFER :=$(UPCT_SECTORSIZE)\n)\
	$(if $(UPCT_NUMBER_BACKUP_BUFFERS),SW_APE_NUMBER_BACKUP_BUFFERS :=$(UPCT_NUMBER_BACKUP_BUFFERS)\n)\
	$(if $(KEYCERT_INDEX),SW_APE_KEY_CERTIFICATE_INDEX :=$(KEYCERT_INDEX)\n)\
	$(if $(UPCT_APE_RAM_SIZE),SW_APE_RAMSIZE :=$(UPCT_APE_RAM_SIZE)\n)\
	$(if $(UPCT_CMT_RAM_SIZE),SW_CMT_RAMSIZE :=$(UPCT_CMT_RAM_SIZE)\n)\
	$(if $(UPCT_APE_SECTOR_SIZE),SW_APE_SIZE_OF_BACKUP_BUFFER :=$(UPCT_APE_SECTOR_SIZE)\n)\
	$(if $(UPCT_CMT_SECTOR_SIZE),SW_CMT_SIZE_OF_BACKUP_BUFFER :=$(UPCT_CMT_SECTOR_SIZE)\n)\
	$(if $(UPCT_APE_PRODUCT_KEY_INDEX),SW_APE_KEY_CERTIFICATE_INDEX :=$(UPCT_APE_PRODUCT_KEY_INDEX)\n)\
	$(if $(UPCT_CMT_PRODUCT_KEY_INDEX),SW_CMT_KEY_CERTIFICATE_INDEX :=$(UPCT_CMT_PRODUCT_KEY_INDEX)\n)\
	$(if $(UPCT_APE_NUMBER_BACKUP_BUFFERS),SW_APE_NUMBER_BACKUP_BUFFERS :=$(UPCT_APE_NUMBER_BACKUP_BUFFERS)\n)\
	$(if $(UPCT_CMT_NUMBER_BACKUP_BUFFERS),SW_CMT_NUMBER_BACKUP_BUFFERS :=$(UPCT_CMT_NUMBER_BACKUP_BUFFERS)\n)\
	SW_UPCT_PARAMS :=$(if $(UPCT_EXTRA_PARAMETERS), $(UPCT_EXTRA_PARAMETERS))$(if $(UPCT_GENERATOR_VERSION),\ndebug_force_generator $(UPCT_GENERATOR_VERSION))\n\
	SW_LIMIT_UPDATE_PACKAGE_SIZE :=$(MAKEUPCT_PACKAGE_SIZE_MAX)\n\
	SW_RELEASE_VERSION :=$(MAKEUPCT_SW_RELEASE_VERSION)\n\
	SW_TYPE_DESIGNATOR :=$(PRODUCT_TYPE)\n
