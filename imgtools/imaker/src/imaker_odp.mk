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
# Description: iMaker On-Demand Paging configuration
#



USE_PAGING = 0

USE_PAGEDROM  = $(if $(or $(call true,$(USE_PAGEDCODE)$(USE_PAGEDDATA)),$(filter rom,$(call lcase,$(USE_PAGING)))),1,0)
USE_PAGEDCODE = $(call _getcodedp)
USE_PAGEDDATA = $(if $(filter data,$(call lcase,$(USE_PAGING))),1,0)

ODP_CONFDIR  = $(E32ROM)/configpaging
ODP_PAGEFILE = $(call iif,$(USE_PAGEDDATA),configpaging_wdp.cfg,configpaging.cfg)
ODP_CODECOMP = bytepair

ODP_ROMCONF =\
  $(or $(SYMBIAN_ODP_NUMBER_OF_MIN_LIVE_PAGES),1024)\
  $(or $(SYMBIAN_ODP_NUMBER_OF_MAX_LIVE_PAGES),2048)\
  $(or $(SYMBIAN_ODP_YOUNG_OLD_PAGE_RATIO),3)\
  $(or $(SYMBIAN_ODP_NAND_PAGE_READ_DELAY),0)\
  $(or $(SYMBIAN_ODP_NAND_PAGE_NAND_PAGE_READ_CPU_OVERHEAD),0)

# Section for Rombuild on all Demand Paging builds
#
define ODP_ROMINFO
  $(call iif,$(USE_PAGEDDATA),
    #if defined(FF_WDP_EMMC) && defined(FF_WDP_NAND)
      #error ERROR: Both of the flags FF_WDP_EMMC and FF_WDP_NAND are defined!
    #elif !defined(FF_WDP_EMMC) && !defined(FF_WDP_NAND)
      #error ERROR: One of the flags FF_WDP_EMMC or FF_WDP_NAND should be defined!
    #endif
    ,
    #undef FF_WDP_EMMC
    #undef FF_WDP_NAND
  )
  $(call iif,$(USE_PAGEDROM),
    #define PAGED_ROM
    ROMBUILD_OPTION -geninc
    pagedrom
    compress
    demandpagingconfig $(strip $(ODP_ROMCONF))
    codepagingoverride defaultpaged
    $(call iif,$(USE_PAGEDDATA),
      datapagingoverride defaultunpaged
      ,
      datapagingoverride nopaging)
  )
  $(if $(filter 1,$(USE_PAGEDCODE)),
    #define PAGED_CODE
    codepagingpolicy defaultpaged
    $(call iif,$(USE_PAGEDDATA),
      datapagingpolicy defaultunpaged
      ,
      datapagingpolicy nopaging)
  )
  $(if $(CORE_PAGEFILE),$(call iif,$(USE_PAGEDROM)$(filter 1,$(USE_PAGEDCODE)),
    externaltool=configpaging:$(CORE_PAGEFILE)))
endef

# Section for Rofsbuild on Code/Data DP enabled builds
#
define ODP_ROFSINFO
  $(if $(filter $(IMAGE_ID),$(USE_PAGEDCODE)),
    #define PAGED_CODE
    codepagingoverride defaultpaged
    $(call iif,$(USE_PAGEDDATA),
      datapagingoverride defaultunpaged
      ,
      datapagingoverride nopaging
    )
    $(if $(ROFS$(IMAGE_ID)_PAGEFILE),
      externaltool=configpaging:$(ROFS$(IMAGE_ID)_PAGEFILE))
  )
endef


###############################################################################
# Internal stuff

_getcodedp = $(or $(strip\
  $(eval __i_paging := $(call lcase,$(USE_PAGING)))\
  $(foreach rofs,$(if $(filter code:%,$(__i_paging)),\
    $(foreach rofs,1 2 3 4 5 6,$(findstring $(rofs),$(__i_paging))),\
    $(if $(or $(call true,$(USE_PAGEDDATA)),$(filter code,$(__i_paging))),1 2 3 4 5 6)),\
      $(call iif,$(USE_ROFS$(rofs)),$(rofs)))),0)


# END OF IMAKER_ODP.MK
