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
# Example version of imaker_extension.mk.
# To extend/change default configuration set in imaker.mk.
#


###############################################################################
#

ifndef __IMAKER_EXTENSION_MK__
__IMAKER_EXTENSION_MK__ := 1

# This part is run from imaker.mk BEFORE user makefiles are read

PRODUCT_MANUFACT = manufacturer


###############################################################################

else
ifeq ($(__IMAKER_EXTENSION_MK__),1)
__IMAKER_EXTENSION_MK__ := 2

# This part is run from imaker.mk AFTER user makefiles are read

endif
endif # __IMAKER_EXTENSION_MK__

# END OF IMAKER_EXTENSION.MK
