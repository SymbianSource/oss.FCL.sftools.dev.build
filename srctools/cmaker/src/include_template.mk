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
# The file defines a include template for cmaker project makefiles.
# Includes automatically 
#   - config/export.mk
#   - anysubdir/makefile
#   - ../makefile
# However the template is built so that it will include subdir makefiles only from current 
# level downwards and upwards. 
# I.e. The included childs will not inlcude its parent, which would create an infinite include loop.
#

ifeq ($(DEBUG_INCLUDES),1)
  $(warning Entering include_template.mk for $(MAKEFILE))
endif

# Each makefile is pushed to a MAKFILE_STACK so that we know in which 
# makefile we are in. I.e. The last one is the current! 
# The current makefile is of course popped out in the end of the makefile
$(call push,MAKEFILE_STACK,$(MAKEFILE))

# Define the childs to be included if we are at the top most makefile
# I.e. the first makefile
ifeq ($(call length,MAKEFILE_STACK),1)
  INCLUDE_CHILD = 1
  INCLUDE_PARENT = 0
endif

include $(wildcard $(MAKEFILEDIR)config/export.mk)

# include the child configuration file 
ifeq ($(INCLUDE_CHILD),1)
  ifeq ($(DEBUG_INCLUDES),1)
    $(warning including childs $(MAKEFILEDIR))
  endif  
  include $(wildcard $(MAKEFILEDIR)*/makefile)
endif

# Define the parents to be included if we are at the top most makefile
# I.e. the first makefile
ifeq ($(call length,MAKEFILE_STACK),1)
  INCLUDE_CHILD = 0
  INCLUDE_PARENT = 1
endif

# include the parent configuration file 
ifeq ($(INCLUDE_PARENT),1)
  ifeq ($(DEBUG_INCLUDES),1)
    $(warning including parents $(MAKEFILEDIR))
  endif  
  include $(wildcard $(MAKEFILEDIR)../makefile)
endif

$(call popout,MAKEFILE_STACK)
