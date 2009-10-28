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
# Description: iMaker On-Demand Paging configuration
#



USE_PAGING = 0

USE_PAGEDROM  = $(if $(filter rom code code:%,$(call lcase,$(USE_PAGING))),1,0)
USE_PAGEDCODE = $(call _getcodedp)

ODP_CONFDIR  = $(E32ROM)/configpaging
ODP_PAGEFILE = configpaging.cfg
ODP_CODECOMP = bytepair

#             Min    Max    Young/Old   NAND page read  NAND page read
#             live   live   page ratio  delay           CPU overhead
#             pages  pages              (microseconds)  (microseconds)
ODP_ROMCONF = 1024   2048     3           0               0

# Section for Rombuild phase on all Demand Paging builds
#
define ODP_ROMINFO
  $(call iif,$(USE_PAGEDROM),
    #define PAGED_ROM
    ROMBUILD_OPTION -geninc
    demandpagingconfig $(strip $(ODP_ROMCONF))
    pagingoverride defaultpaged
    pagedrom
    compress
  )
  $(if $(filter 1,$(USE_PAGEDCODE)),
    #define PAGED_CODE
    pagingpolicy defaultpaged
  )
  $(if $(CORE_PAGEFILE),$(call iif,$(USE_PAGEDROM)$(filter 1,$(USE_PAGEDCODE)),
    externaltool=configpaging:$(CORE_PAGEFILE))
  )
endef

# Section for Rofsbuild phase on Code DP enabled builds
#
define ODP_CODEINFO
  $(if $(filter $1,$(USE_PAGEDCODE)),
    #define PAGED_CODE
    $(if $(ROFS$1_PAGEFILE),
      externaltool=configpaging:$(ROFS$1_PAGEFILE))
    pagingoverride defaultpaged
  )
endef


###############################################################################
# Internal stuff

_getcodedp = $(or $(strip\
  $(if $(filter code code:,$(eval __i_paging := $(call lcase,$(call sstrip,$(USE_PAGING))))$(__i_paging)),\
    $(foreach rofs,1 2 3 4 5 6,$(call iif,$(USE_ROFS$(rofs)),$(rofs))),\
    $(if $(filter code:%,$(__i_paging)),\
      $(foreach rofs,1 2 3 4 5 6,$(findstring $(rofs),$(__i_paging)))))),0)


# END OF IMAKER_ODP.MK
