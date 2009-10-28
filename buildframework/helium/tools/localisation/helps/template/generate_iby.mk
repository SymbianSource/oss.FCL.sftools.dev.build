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
# Include Helium helpers to support iby generation for helps
PRODUCT_VARIANTS=PRODUCT PRODUCT_edge

# PRODUCT config
PRODUCT_IBYFILE=\epoc32\rom\config\PLATFORM\PRODUCT\help.iby 
PRODUCT_TAG=_3g 

# PRODUCT edge config
PRODUCT_edge_IBYFILE=\epoc32\rom\config\PLATFORM\PRODUCT_edge\help.iby
PRODUCT_edge_TAG=_2g

# Includes tools part.
include $(HELIUM_HOME)/tools/localisation/helps/generate_iby_32.mk

