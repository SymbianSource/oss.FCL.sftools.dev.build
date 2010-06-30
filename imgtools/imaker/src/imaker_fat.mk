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
# Description: iMaker FAT (File Allocation Table) image configuration
#



###############################################################################
#  ___  _  _____
# | __|/_\|_   _|
# | _|/ _ \ | |
# |_|/_/ \_\|_|
#

USE_FILEDISK = 0
USE_FSIMAGE  = 0
USE_SOSUDA   = 1

FATEMPTY_CMD =


###############################################################################
#

define FAT_EVAL
$1_TITLE       = $1
$1_ROOT        = $$(OUTDIR)/$2
$1_DIR         = $$($1_ROOT)
$1_NAME        = $$(NAME)
$1_PREFIX      = $$($1_DIR)/$$($1_NAME)
$1_IDIR        =
$1_HBY         =
$1_OBY         =
$1_OPT         = $$(BLDROM_OPT) -D_EABI=$$(ARM_VERSION)
$1_MSTOBY      = $$($1_PREFIX)_$2_master.oby
$1_HEADER      =
$1_INLINE      =
$1_FOOTER      =
$1_TIME        = $$(DAY)/$$(MONTH)/$$(YEAR)

$1_DEFHRH      = $$($1_PREFIX)_$2_define.hrh
$1_FEAXML      =
$1_FEAIBY      =

$1_ROMVER      = $$(CORE_ROMVER)
$1_ID          = $$(if $$(filter $2_%,$$(TARGETNAME)),$$(TARGETID1),00)
$1_REVISION    = 01
$1_VERSION     = $$(CORE_VERSION).$$($1_ID).$$($1_REVISION)
$1_SWVERFILE   = $$($1_DATADIR)/Resource/Versions/User Content Package_$1.txt
$1_SWVERINFO   = $$($1_VERSION)

$1_IMG         = $$($1_PREFIX).$2.img
$1_LOG         = $$($1_PREFIX).$2.log
$1_OUTOBY      = $$($1_PREFIX).$2.oby

$1_PLUGINLOG   = $$($1_PREFIX)_$2_bldromplugin.log
$1_UDEBFILE    = $$(TRACE_UDEBFILE)

$1_OBYGEN      =
$1_ORIDEIBY    = $$($1_PREFIX)_$2_override.iby
$1_ORIDEFILES  = $$(IMAGE_ORIDEFILES)
$1_ORIDECONF   = $$(IMAGE_ORIDECONF)

$1_CONECONF    = $$(PRODUCT_NAME)_$2_$$($1_ID)$$(addprefix _,$$($1_VARNAME))_root.confml
$1_CONEOPT     = --all-layers --impl-tag=target:$2

$1_DRIVE       = C
$1_FATTYPE     = 16# FAT16
$1_SIZE        = 20480# kB
$1_SIZEB       = $$(call peval,$$($1_SIZE) * 1024)# B
$1_DISKSIZE    = $$($1_SIZE)# kB
$1_SECTORSIZE  = 512# B
$1_CLUSTERSIZE = 4# kB
$1_FATTABLE    = 1
$1_VOLUME      =

$1_TOUCH       = 0#$$(YEAR)$$(MONTH)$$(DAY)000000
$1_CPDIR       =
$1_ZIP         =
$1_DATADIR     = $$($1_DIR)/datadrive

$1_VARNAME     = $$(if $$(filter $2_%,$$(TARGETNAME)),$$(TARGETID2-))
$1_VARROOT     = $$(or $$(wildcard $$(PRODUCT_DIR)/$2),$$(or $$(if $$(PRODUCT_MSTNAME),$$(wildcard $$(PRODUCT_MSTDIR)/$2)),$$(PRODUCT_DIR)/$2))
$1_VARDIR      = $$(if $$(and $$(call true,$$(USE_CONE)),$$(call true,$$(IMAKER_MKRESTARTS))),$$(CONE_OUTDIR),$$($1_VARROOT)/$2_$$($1_ID)$$(addprefix _,$$($1_VARNAME))$$(call iif,$$(USE_CONE),/content))

$1_EXCLFILE    = $$($1_DATADIR)/private/100059C9/excludelist.txt

define $1_EXCLADD
*
endef

define $1_EXCLRM
endef

$1EMPTY_TITLE  = $$($1_TITLE) Empty
$1EMPTY_IMG    = $$($1_PREFIX).$2empty.img
$1EMPTY_CMD    = $$(FATEMPTY_CMD)

#==============================================================================

define $1_MSTOBYINFO
  $$(call BLDROM_HDRINFO,$1)

  ROM_IMAGE  0 non-xip size=0x00000000

  DATA_IMAGE 0 $$(basename $$($1_IMG)) size=$$(call peval,$$($1_DISKSIZE) * 1024) fat$$(if $$(filter %32,$$($1_FATTYPE)),32,16)

  $$(call BLDROM_PLUGINFO,$1)

  /* $1 header
  */
  $$($1_HDRINFO)

  DATA_IMAGE[0] {
    $$(if $$($1_VOLUME),volume=$$($1_VOLUME))
    fattable=$$($1_FATTABLE)
  #ifndef _IMAGE_INCLUDE_HEADER_ONLY
    $$(BLR.$1.OBY)
    $$($1_INLINE)
    $$($1_FOOTERINFO)
  }
  #endif // _IMAGE_INCLUDE_HEADER_ONLY
endef

define $1_HDRINFO
  $$(DEFINE) _IMAGE_WORKDIR $$($1_DIR)
  $$(call mac2cppdef,$$(BLR.$1.OPT))
  $$(BLR.$1.HBY)
  $$($1_HEADER)
  $$(if $$(filter $3,$$(USE_VARIANTBLD)),$$(VARIANT_HEADER))
endef

define $1_FOOTERINFO
  $$(if $$($1_TIME),time=$$($1_TIME))
  $$(if $$($1_ROMVER),version=$$($1_ROMVER))
  $$($1_FOOTER)
endef

$1_ORIDEINFO =

#==============================================================================
# FAT pre-build

CLEAN_$1PRE =\
  $$(if $$(filter $3,$$(USE_VARIANTBLD)),$$(CLEAN_VARIANT),deldir | "$$($1_DATADIR)") |\
  $$(CLEAN_$1FILE) | $$(CLEAN_DEFHRH) | $$(CLEAN_FEATMAN)

BUILD_$1PRE =\
  echo-q | Preparing $$($1_TITLE) FAT image creation |\
  $$(if $$(filter $3,$$(USE_VARIANTBLD)),$$(BUILD_VARIANT) |,\
    mkdir | "$$($1_DATADIR)" |\
    $$(if $$($1_ZIP),\
      $$(eval __i_zip := $$(foreach zip,$$($1_ZIP),$$(zip)$$(if $$(filter %.zip,$$(call lcase,$$(zip))),,/*.zip)))\
      echo-q | Extracting `$$(__i_zip)' to `$$($1_DATADIR)' |\
      unzip  | "$$(__i_zip)" | $$($1_DATADIR) |)\
    $$(if $$($1_CPDIR),\
      copydir | "$$($1_CPDIR)" | $$($1_DATADIR) |))\
  mkdir | "$$($1_DIR)" |\
  $$(BUILD_$1FILE) |\
  $$(call iif,$$(BLR.$1.OBY),$$(BUILD_DEFHRH) |)\
  $$(BUILD_FEATMAN)

CLEAN_$1FILE =\
  del | "$$($1_MSTOBY)" "$$($1_ORIDEIBY)" "$$($1_SWVERFILE)" |\
  del | $$(call getgenfiles,$$($1_OBYGEN))

BUILD_$1FILE =\
  echo-q  | Generating file(s) for $$($1_TITLE) FAT image creation |\
  $$(call iif,$$(BLR.$1.OBY),\
    write-c | "$$($1_MSTOBY)"    | $$(call def2str,$$($1_MSTOBYINFO))\n |)\
  $$(if $$($1_SWVERINFO),\
    writeu  | "$$($1_SWVERFILE)" | $$(call quote,$$($1_SWVERINFO)) |)\
  $$(if $$($1_ORIDEINFO),\
    write-c | "$$($1_ORIDEIBY)"  | $$(call def2str,$$($1_ORIDEINFO)) |)\
  $$(if $$($1_ORIDECONF),\
    genorideiby | >>$$($1_ORIDEIBY) | $$(call def2str,$$($1_ORIDEFILES) | $$($1_ORIDECONF)) |)\
  $$($1_OBYGEN)

#==============================================================================
# FAT build

BLR.$1.IDIR = $$(call dir2inc,$$($1_IDIR) $$(call iif,$$(USE_FEATVAR),,$$(FEATVAR_IDIR)))
BLR.$1.HBY  = $$(call includeiby,$$(IMAGE_HBY) $$($1_HBY))
BLR.$1.OBY  = $$(call includeiby,$$($1_OBY))\
  $$(and $$(call true,$$(SYMBIAN_FEATURE_MANAGER)),$$($1_FEAIBY),$$(call mac2cppdef,-U__FEATURE_IBY__)$$(call includeiby,$$($1_FEAIBY)))\
  $$(call includeiby,$$(and $$(filter $3,$$(USE_VARIANTBLD)),$$(call true,$$(VARIANT_INCDIR)$$(USE_SOSUDA)),$$(VARIANT_OBY))\
    $$(if $$(strip $$($1_ORIDEINFO)$$($1_ORIDECONF)),$$($1_ORIDEIBY)))
BLR.$1.OPT  = $$($1_OPT) -noimage -o$$(call pathconv,$$($1_PREFIX)).dummy0.img $$(BLDROPT)
BLR.$1.POST = $$(call iif,$$(USE_SOSUDA),,copyiby | "$$($1_OUTOBY)" | $$($1_DATADIR))

CLEAN_$1 = $$(call CLEAN_BLDROM,$1) | $$(CLEAN_FILEDISK) | $$(CLEAN_WINIMAGE) | $$(CLEAN_FSIMAGE)
BUILD_$1 =\
  $$(call iif,$$(BLR.$1.OBY),$$(call BUILD_BLDROM,$1) |)\
  $$(if $$($1_EXCLFILE),\
    genexclst | $$($1_EXCLFILE) | $$($1_DATADIR) | $$($1_DRIVE): |\
      $$(call def2str,$$($1_EXCLADD) | $$($1_EXCLRM)) |)\
  $$(call iif,$$($1_TOUCH),\
    finddir-r | "$$($1_DATADIR)" | * ||\
    find-ar   | "$$($1_DATADIR)" | * ||\
    touch     | __find__ | $$($1_TOUCH) |)\
  echo-q | Creating $$($1_TITLE) FAT image |\
  $$(call iif,$$(USE_SOSUDA),$$(BUILD_ROFSBLDFAT),\
    $$(call iif,$$(USE_FSIMAGE),$$(BUILD_FSIMAGE),\
      $$(call iif,$$(USE_FILEDISK),$$(BUILD_FILEDISK),$$(BUILD_WINIMAGE))))

REPORT_$1 =\
  $$($1_TITLE) dir   | $$($1_DIR) | d |\
  $$($1_TITLE) image | $$($1_IMG) | f

#==============================================================================
# FAT post-build

CLEAN_$1POST  =
BUILD_$1POST  =
REPORT_$1POST =

#==============================================================================
# Empty FAT

CLEAN_$1EMPTY = del | "$$($1EMPTY_IMG)"
BUILD_$1EMPTY = $$(if $$($1EMPTY_CMD),\
  echo-q | Creating $$($1EMPTY_TITLE) FAT image |\
  mkdir  | "$$($1_DIR)" |\
  cmd    | $$($1EMPTY_CMD))

REPORT_$1EMPTY = $$($1EMPTY_TITLE) image | $$($1EMPTY_IMG) | f

#==============================================================================
# FAT steps

SOS.$1.STEPS =\
  $$(call iif,$$(SKIPPRE),,$$(and $$(filter $3,$$(USE_VARIANTBLD)),$$(call true,$$(USE_CONE)),CONEGEN RESTART) $1PRE)\
  $$(call iif,$$(SKIPBLD),,$1) $$(call iif,$$(SKIPPOST),,$1POST)

SOS.$1EMPTY.STEPS = $$(if $$(BUILD_$1EMPTY),$1EMPTY)

ALL.$1.STEPS      = $$(SOS.$1.STEPS)
ALL.$1EMPTY.STEPS = $$(SOS.$1EMPTY.STEPS)

#==============================================================================
# Targets

.PHONY: $2 $2-cone $2-image $2-pre $2empty $2empty-image variant$2

$2 $2%  : IMAGE_TYPE = $1

$2      : ;@$$(call IMAKER,$$$$(ALL.$1.STEPS))
$2-image: ;@$$(call IMAKER,$$$$(SOS.$1.STEPS))
$2-cone : ;@$$(call IMAKER,CONEGEN)
$2-pre  : ;@$$(call IMAKER,$1PRE)

$2empty      : ;@$$(call IMAKER,$$$$(ALL.$1EMPTY.STEPS))
$2empty-image: ;@$$(call IMAKER,$$$$(SOS.$1EMPTY.STEPS))

variant$2 variant$2%     : USE_CONE = 0
variant$2 variant$2% $2_%: USE_VARIANTBLD = $3
variant$2 variant$2% $2_%: $2$$(TARGETEXT) ;

#==============================================================================
# Helps

$(call add_help,$2,t,Create $$($1_TITLE) image.)
$(call add_help,$2-dir,t,Create directory structure for $$($1_TITLE) creation.)
$(call add_help,$2-image,t,Create $$($1_TITLE) image (.img) file.)
$(call add_help,$2-pre,t,Run pre-step, create files etc. for $$($1_TITLE) creation.)
$(call add_help,variant$2,t,Create $$($1_TITLE) image from a variant directory. Be sure to define the VARIANT_DIR.)

BUILD_HELPDYNAMIC +=\
  $$(call add_help,$$(call getlastdir,$$(wildcard $$($1_VARROOT)/$2_*/)),t,$$($1_TITLE) variant target.)\
  $$(eval include $$(wildcard $$($1_VARROOT)/$2_*/$$(VARIANT_MKNAME)))

endef # FAT_EVAL


###############################################################################
#

$(eval $(call FAT_EVAL,EMMC,emmc,e))
$(eval $(call FAT_EVAL,MCARD,mcard,m))
$(eval $(call FAT_EVAL,UDA,uda,u))

$(call includechk,$(addprefix $(IMAKER_DIR)/imaker_,emmc.mk memcard.mk uda.mk))


# END OF IMAKER_FAT.MK
