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
# Description: iMaker User Data image configuration
#



###############################################################################
#  _   _ ___   _
# | | | |   \ /_\
# | |_| | |) / _ \
#  \___/|___/_/ \_\
#

USE_FILEDISK = 0
USE_SOSUDA   = 0
USE_UDAFGEN  = 0

UDA_TITLE       = UDA
UDA_DIR         = $(WORKDIR)/uda
UDA_NAME        = $(NAME)
UDA_PREFIX      = $(UDA_DIR)/$(UDA_NAME)
UDA_IDIR        =
UDA_HBY         =
UDA_OBY         =
UDA_OPT         = $(BLDROM_OPT) -D_EABI=$(ARM_VERSION)
UDA_MSTOBY      = $(UDA_PREFIX)_uda_master.oby
UDA_HEADER      =
UDA_INLINE      =
UDA_FOOTER      =
UDA_TIME        = $(DAY)/$(MONTH)/$(YEAR)

UDA_CPDIR       =
UDA_ZIP         =
UDA_DATADIR     = $(UDA_DIR)/datadrive
UDA_SISCONFFILE = $(UDA_PREFIX)_uda_sisconf.txt
UDA_SISCONF     =\
  -d $(UDA_DRIVE): -c $(UDA_DATADIR) $(if $(SISINST_SISDIR),-s $(SISINST_SISDIR))\
  -z $(SISINST_ZDIR) $(if $(SISINST_HALINI),-i $(SISINST_HALINI)) -w info

UDA_VERSION     = $(CORE_VERSION)
UDA_SWVERFILE   = "$(UDA_DATADIR)/Resource/Versions/User Content Package_UDA.txt"
UDA_SWVERINFO   = $(UDA_VERSION)
UDA_EXCLFILE    = $(UDA_DATADIR)/private/100059C9/excludelist.txt
UDA_TOUCH       = $(call iif,$(USE_SOSUDA),,$(YEAR)$(MONTH)$(DAY)000000)

UDA_IMG         = $(UDA_PREFIX).uda.img
UDA_LOG         = $(UDA_PREFIX).uda.log
UDA_OUTOBY      = $(UDA_PREFIX).uda.oby
UDA_EMPTYIMG    = $(UDA_PREFIX).udaempty.img

UDA_PLUGINLOG   = $(UDA_PREFIX)_uda_bldromplugin.log
UDA_UDEBFILE    = $(TRACE_UDEBFILE)

UDA_DRIVE       = C
UDA_FATTYPE     = fat16
UDA_FATSIZE     = 20480

define UDA_EXCLADD
*
endef

define UDA_EXCLRM
endef

#==============================================================================

UDA_FDISKCONF = /mount 0
UDA_FDISKCMD  =\
  $(FILEDISK_TOOL) $(UDA_FDISKCONF) $(call peval,GetAbsFname($(call pquote,$(UDA_IMG)),1,1)) $(call peval,$$iVar[0] = GetFreeDrive()) |\
  copy  | $(UDA_DATADIR)/* | $(call peval,$$iVar[0])/ |\
  cmd   | $(FILEDISK_TOOL) /status $(call peval,$$iVar[0]) |\
  sleep | 1 |\
  cmd   | $(FILEDISK_TOOL) /umount $(call peval,$$iVar[0])

UDA_WINIMGCMD = $(WINIMAGE_TOOL) $(call pathconv,$(UDA_IMG)) /i $(call pathconv,$(UDA_DATADIR)) /h /q

UDA_CMD       = $(call iif,$(USE_FILEDISK),$(UDA_FDISKCMD),$(UDA_WINIMGCMD))
UDA_EMPTYCMD  =

#==============================================================================

define UDA_MSTOBYINFO
  $(BLDROM_HDRINFO)

  ROM_IMAGE  0 non-xip size=0x00000000

  DATA_IMAGE 0 $(basename $(UDA_IMG)) size=$(call peval,$(UDA_FATSIZE) * 1024) $(UDA_FATTYPE)

  // UDA header
  //
  $(UDA_HDRINFO)

  DATA_IMAGE[0] {
    $(BLR.UDA.OBY)
    $(UDA_INLINE)
    $(UDA_FOOTERINFO)
  }
endef

define UDA_HDRINFO
  $(DEFINE) _IMAGE_WORKDIR $(UDA_DIR)
  $(call mac2cppdef,$(BLR.UDA.OPT))
  $(BLR.UDA.HBY)
  $(UDA_HEADER)
  $(if $(filter u U,$(USE_VARIANTBLD)),$(VARIANT_HEADER))
endef

define UDA_FOOTERINFO
  $(if $(UDA_TIME),time=$(UDA_TIME))
  $(UDA_FOOTER)
endef

#==============================================================================

CLEAN_UDAFILE =\
  del | "$(UDA_MSTOBY)" "$(UDA_SISCONFFILE)" "$(UDA_SWVERFILE)" "$(UDA_EXCLFILE)"

BUILD_UDAFILE =\
  echo-q | Generating file(s) for UDA image creation |\
  $(call iif,$(USE_SOSUDA),\
    write  | $(UDA_MSTOBY) | $(call def2str,$(UDA_MSTOBYINFO)) |\
    write  | $(UDA_SISCONFFILE) | $(call quote,$(UDA_SISCONF)) |)\
  $(call iif,$(USE_UDAFGEN),\
    $(if $(UDA_SWVERINFO),\
      writeu | $(UDA_SWVERFILE) | $(UDA_SWVERINFO) |)\
    $(if $(UDA_EXCLFILE),\
      genexclst | $(UDA_EXCLFILE) | $(UDA_DATADIR) | $(UDA_DRIVE):/ |\
        "$(subst $(\n)," ",$(UDA_EXCLADD))" | "$(subst $(\n)," ",$(UDA_EXCLRM))")\
  )


###############################################################################
# UDA pre

CLEAN_UDAPRE = $(if $(filter u U,$(USE_VARIANTBLD)),$(CLEAN_CUSTVARIANT),deldir | $(UDA_DATADIR)) | $(CLEAN_UDAFILE)

BUILD_UDAPRE =\
  echo-q | Preparing UDA image creation |\
  $(if $(filter u U,$(USE_VARIANTBLD)),$(BUILD_CUSTVARIANT) |,\
    mkdir | $(UDA_DATADIR) |\
    $(if $(UDA_ZIP),\
      $(eval __i_zip := $(foreach zip,$(UDA_ZIP),$(zip)$(if $(filter %.zip,$(call lcase,$(zip))),,/*.zip)))\
      echo-q | Extracting `$(__i_zip)$' to `$(UDA_DATADIR)$' |\
      unzip  | $(__i_zip) | $(UDA_DATADIR) |)\
    $(if $(UDA_CPDIR),\
      copy | $(UDA_CPDIR)/* | $(UDA_DATADIR) |))\
  mkcd | $(UDA_DIR) |\
  $(BUILD_UDAFILE) |\
  $(call iif,$(USE_FILEDISK),\
    cmd | attrib -r -a -s -h $(call pathconv,$(UDA_DATADIR)) /s /d |)\
  $(if $(UDA_TOUCH),\
    finddir-r | $(UDA_DATADIR) | * | |\
    find-ar   | $(UDA_DATADIR) | * | |\
    touch     | __find__ | $(UDA_TOUCH))

#==============================================================================
# UDA build

BLR.UDA.IDIR   = $(call dir2inc,$(UDA_IDIR) $(call iif,$(USE_FEATVAR),,$(FEATVAR_IDIR)))
BLR.UDA.HBY    = $(call includeiby,$(IMAGE_HBY) $(UDA_HBY))
BLR.UDA.OBY    = $(call includeiby,$(UDA_OBY) $(if $(filter u U,$(USE_VARIANTBLD)),$(VARIANT_OBY)))
BLR.UDA.OPT    = $(UDA_OPT) -p -retainfolder -pfile=$(UDA_SISCONFFILE) -o$(UDA_NAME).dummy0.img $(BLDROPT)
BLR.UDA.POST   =\
  move | $(UDA_OUTOBY).log | $(UDA_LOG)

BLR.UDA.CLEAN  = del | "$(UDA_EMPTYIMG)" "$(UDA_IMG)"
BLR.UDA.BUILD  =\
  $(call iif,$(USE_SOSUDA),,\
    echo-q | Creating $(UDA_TITLE) SOS image |\
    $(if $(UDA_EMPTYCMD),\
      cmd  | $(UDA_EMPTYCMD) |\
      move | $(UDA_EMPTYIMG) | $(UDA_IMG) |)\
    cmd | $(UDA_CMD))

CLEAN_UDA = $(CLEAN_BLDROM)
BUILD_UDA = $(BUILD_BLDROM)

# UDA Empty
#
CLEAN_UDAEMPTY = del | $(UDA_EMPTYIMG)
BUILD_UDAEMPTY =\
  echo-q | Creating empty UDA FAT image |\
  mkdir  | $(UDA_DIR) |\
  cmd    | $(UDA_EMPTYCMD)

#==============================================================================
# UDA post

#==============================================================================

SOS.UDA.STEPS      = $(call iif,$(SKIPPRE),,UDAPRE) UDA $(SOS.UDAEMPTY.STEPS)
SOS.UDAEMPTY.STEPS = UDAEMPTY

ALL.UDA.STEPS      = $(SOS.UDA.STEPS)
ALL.UDAEMPTY.STEPS = $(SOS.UDAEMPTY.STEPS)

#==============================================================================

.PHONY: uda uda-image uda-pre uda-empty uda-empty-image variantuda

uda uda-%: IMAGE_TYPE = UDA

uda      : ;@$(call IMAKER,$$(ALL.UDA.STEPS))
uda-image: ;@$(call IMAKER,$$(SOS.UDA.STEPS))
uda-pre  : ;@$(call IMAKER,UDAPRE)

uda-empty:       ;@$(call IMAKER,$$(ALL.UDAEMPTY.STEPS))
uda-empty-image: ;@$(call IMAKER,$$(SOS.UDAEMPTY.STEPS))

variantuda variantuda%: USE_CUSTVARIANTBLD = 1
variantuda variantuda%: USE_VARIANTBLD     = u
variantuda variantuda%: uda$(TARGETEXT) ;


# END OF IMAKER_UDA.MK
