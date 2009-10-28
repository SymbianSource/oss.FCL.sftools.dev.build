#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Symbian Foundation License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.symbianfoundation.org/legal/sfl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description:
# Example version of a product-specific configuration makefile.
# Calling: imaker -f /epoc32/rom/config/platform/product/image_conf_product.mk ...
#


# Include platform-level configuration
include $(CONFIGROOT)/platform/image_conf_platform.mk

PRODUCT_NAME  = product
PRODUCT_TYPE  = product_type
PRODUCT_MODEL = product_model

# Definitions and options for Buildrom tool
PRODUCT_OPT =
