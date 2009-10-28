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
# Example version of image_conf_naming.mk.
# If this file exists in build area, it is read by iMaker and can be used for
# image naming, setting directories and version info generation.
#


ROFS2_DIR  = $(WORKDIR)/$(TYPE)/langpack/$(LANGPACK_NAME)
ROFS2_NAME = $(PRODUCT_TYPE).$(BUILD_NUMBER)_$(LANGPACK_ID)_$(TYPE)

LANGPACK_SWVERINFO = $(CORE_VERSION).$(LANGPACK_ID)\\\n$(DAY)-$(MONTH)-$(YEAR2)\\\n(c) $(PRODUCT_MANUFACT)
