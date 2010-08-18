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
# Description: iMaker generic ROFS image configuration
#



###############################################################################
#  ___  ___  ___ ___
# | _ \/ _ \| __/ __|
# |   / (_) | _|\__ \
# |_|_\\___/|_| |___/
#

ROFS_MAXSIZE = 0x10000000

define ROFS_EVAL
USE_$1        = $$(call userofs,$3)

$1_TITLE      = $1
$1_DRIVE      = Z
$1_ROOT       = $$(OUTDIR)/$2
$1_DIR        = $$($1_ROOT)
$1_NAME       = $$(NAME)
$1_PREFIX     = $$($1_DIR)/$$($1_NAME)
$1_IDIR       =
$1_HBY        =
$1_OBY        =
$1_OPT        =
$1_MAXSIZE    = $$(ROFS_MAXSIZE)
$1_MSTOBY     = $$($1_PREFIX)_$2_master.oby
$1_HEADER     =
$1_INLINE     =
$1_FOOTER     =
$1_TIME       = $$(DAY)/$$(MONTH)/$$(YEAR)

$1_DEFHRH     = $$($1_PREFIX)_$2_define.hrh
$1_FEAXML     =
$1_FEAIBY     =

$1_ROMVER     = $$(CORE_ROMVER)
$1_ID         = $$(if $$(filter $2_%,$$(TARGETNAME)),$$(TARGETID1),00)
$1_REVISION   = 01
$1_VERSION    = $$(CORE_VERSION).$$($1_ID).$$($1_REVISION)
$1_SWVERFILE  = $$($1_PREFIX)_$2_sw.txt
$1_SWVERTGT   = $$(IMAGE_VERSDIR)\$2sw.txt
$1_SWVERINFO  = $$($1_VERSION)\n$$(BUILD_YEAR)-$$(BUILD_MONTH)-$$(BUILD_DAY)
$1_FWIDFILE   = $$($1_PREFIX)_$2_fwid.txt
$1_FWID       = $2
$1_FWIDVER    = $$($1_VERSION)$$(SW_TYPEINFO)
$1_FWIDINFO   = id=$$($1_FWID)\nversion=$$($1_FWIDVER)\n

$1_IMG        = $$($1_PREFIX).$2.img
$1_LOG        = $$($1_PREFIX).$2.log
$1_OUTOBY     = $$($1_PREFIX).$2.oby
$1_SYM        = $$($1_PREFIX).$2.symbol

$1_PLUGINLOG  = $$($1_PREFIX)_$2_bldromplugin.log
$1_PAGEFILE   = $$(ODP_PAGEFILE)
$1_UDEBFILE   = $$(TRACE_UDEBFILE)

$1_OBYGEN     =
$1_ORIDEIBY   = $$($1_PREFIX)_$2_override.iby
$1_ORIDEFILES = $$(IMAGE_ORIDEFILES)
$1_ORIDECONF  = $$(IMAGE_ORIDECONF)

$1_ICHKLOG    = $$($1_PREFIX)_$2_imgcheck.log
$1_ICHKOPT    = $$(IMGCHK_OPT)
$1_ICHKIMG    = $$($1_IMG)

$1_I2FDIR     = $$($1_DIR)/img2file

$1_CONECONF   = $$(PRODUCT_NAME)_$2_$$($1_ID)$$(addprefix _,$$($1_VARNAME))_root.confml
$1_CONEOPT    = --all-layers --impl-tag=target:$2

$1_VARNAME    = $$(if $$(filter $2_%,$$(TARGETNAME)),$$(TARGETID2-))
$1_VARROOT    = $$(or $$(wildcard $$(PRODUCT_DIR)/$2),$$(or $$(if $$(PRODUCT_MSTNAME),$$(wildcard $$(PRODUCT_MSTDIR)/$2)),$$(PRODUCT_DIR)/$2))
$1_VARDIR     = $$(if $$(and $$(call true,$$(USE_CONE)),$$(call true,$$(IMAKER_MKRESTARTS))),$$(CONE_OUTDIR),$$($1_VARROOT)/$2_$$($1_ID)$$(addprefix _,$$($1_VARNAME))$$(call iif,$$(USE_CONE),/content))

#==============================================================================

define $1_MSTOBYINFO
  $$(call BLDROM_HDRINFO,$1)

  ROM_IMAGE 0        non-xip size=0x00000000
  $$(foreach rofs,1 2 3 4 5 6,
    ROM_IMAGE $$(rofs) $$(if $$(filter $$(rofs),$3), rofs,dummy)$$(rofs) non-xip size=$$($1_MAXSIZE))

  $$(call BLDROM_PLUGINFO,$1)

  /* $1 header
  */
  $$($1_HDRINFO)

  ROM_IMAGE[$3] {
    $$(ODP_ROFSINFO)
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

define $1_ORIDEINFO
  // Generated `$$($1_ORIDEIBY)' for $$($1_TITLE) image creation

  $$(if $$($1_SWVERINFO)$$($1_FWIDINFO),
    OVERRIDE_REPLACE/ADD
    $$(if $$($1_SWVERINFO),
      data-override="$$($1_SWVERFILE)"  "$$($1_SWVERTGT)")
    $$(if $$($1_FWIDINFO),
      data-override="$$($1_FWIDFILE)"  "$$(IMAGE_VERSDIR)\fwid$3.txt")
    OVERRIDE_END
  )
endef

#==============================================================================
# ROFS pre-build

CLEAN_$1PRE =\
  $$(if $$(filter $3,$$(USE_VARIANTBLD)),$$(CLEAN_VARIANT) |)\
  $$(CLEAN_$1FILE) | $$(CLEAN_DEFHRH) | $$(CLEAN_FEATMAN)

BUILD_$1PRE =\
  $$(if $$(filter $3,$$(USE_VARIANTBLD)),$$(BUILD_VARIANT) |)\
  mkdir | "$$($1_DIR)" |\
  $$(BUILD_$1FILE) |\
  $$(BUILD_DEFHRH) |\
  $$(BUILD_FEATMAN)

CLEAN_$1FILE =\
  del | "$$($1_MSTOBY)" "$$($1_ORIDEIBY)" "$$($1_SWVERFILE)" "$$($1_FWIDFILE)" |\
  del | $$(call getgenfiles,$$($1_OBYGEN))

BUILD_$1FILE =\
  echo-q  | Generating file(s) for $$($1_TITLE) image creation |\
  write-c | "$$($1_MSTOBY)" | $$(call def2str,$$($1_MSTOBYINFO))\n |\
  $$(if $$($1_SWVERINFO),\
    writeu  | "$$($1_SWVERFILE)" | $$(call quote,$$($1_SWVERINFO)) |)\
  $$(if $$($1_FWIDINFO),\
    writeu  | "$$($1_FWIDFILE)"  | $$($1_FWIDINFO) |)\
  $$(if $$($1_ORIDEINFO),\
    write-c | "$$($1_ORIDEIBY)"  | $$(call def2str,$$($1_ORIDEINFO)) |)\
  $$(if $$($1_ORIDECONF),\
    genorideiby | >>$$($1_ORIDEIBY) | $$(call def2str,$$($1_ORIDEFILES) | $$($1_ORIDECONF)) |)\
  $$($1_OBYGEN)

#==============================================================================
# ROFS build

$1_DUMMY     = $$(call rofsdummy,$1)

BLR.$1.BUILD = $$(if $$(filter d%,$$(USE_$1)),echo-q | Creating dummy $$($1_TITLE) SOS image | write-q | "$$($1_IMG)" | $$($1_DUMMY))
BLR.$1.IDIR  = $$(call dir2inc,$$($1_IDIR) $$(call iif,$$(USE_FEATVAR),,$$(FEATVAR_IDIR)))
BLR.$1.HBY   = $$(call includeiby,$$(IMAGE_HBY) $$($1_HBY))
BLR.$1.OBY   = $$(call includeiby,$$($1_OBY))\
  $$(and $$(call true,$$(SYMBIAN_FEATURE_MANAGER)),$$($1_FEAIBY),$$(call mac2cppdef,-U__FEATURE_IBY__)$$(call includeiby,$$($1_FEAIBY)))\
  $$(call includeiby,$$(if $$(filter $3,$$(USE_VARIANTBLD)),$$(VARIANT_OBY)) $$($1_ORIDEIBY))
BLR.$1.OPT   = $$($1_OPT) $$(if $$(filter $3,$$(USE_PAGEDCODE)),$$(if $$(ODP_CODECOMP),-c$$(ODP_CODECOMP))) -o$$(call pathconv,$$($1_PREFIX)).img $$(BLDROPT)
BLR.$1.POST  = $$(call iif,$$(KEEPTEMP),,del | "$$($1_PREFIX).???")

CLEAN_$1 = $$(call CLEAN_BLDROM,$1)
BUILD_$1 = $$(call BUILD_BLDROM,$1)

REPORT_$1 =\
  $$($1_TITLE) dir   | $$($1_DIR) | d |\
  $$($1_TITLE) image | $$($1_IMG) | f\
  $$(call iif,$$(USE_SYMGEN),| $$(REPORT_MAKSYMROFS))

#==============================================================================
# ROFS post-build

CLEAN_$1POST  = $$(CLEAN_IMGCHK)
BUILD_$1POST  = $$(call iif,$$(USE_IMGCHK),$$(BUILD_IMGCHK))
REPORT_$1POST =

#==============================================================================
# ROFS steps

SOS.$1.STEPS = $$(call iif,$$(USE_$1),\
  $$(call iif,$$(SKIPPRE),,$$(and $$(filter $3,$$(USE_VARIANTBLD)),$$(call true,$$(USE_CONE)),CONEGEN RESTART) $1PRE)\
  $$(call iif,$$(SKIPBLD),,$1) $$(call iif,$$(SKIPPOST),,$1POST))

ALL.$1.STEPS  = $$(SOS.$1.STEPS)

#==============================================================================
# Targets

.PHONY: $2 $(addprefix $2-,all check cone i2file image pre symbol) variant$2

$2 $2%: IMAGE_TYPE = $1
$2-all: USE_SYMGEN = 1

$2 $2-all: ;@$$(call IMAKER,$$$$(ALL.$1.STEPS))
$2-image : ;@$$(call IMAKER,$$$$(SOS.$1.STEPS))

$2-cone  : ;@$$(call IMAKER,CONEGEN)
$2-pre   : ;@$$(call IMAKER,$1PRE)
$2-check : ;@$$(call IMAKER,IMGCHK)
$2-symbol: ;@$$(call IMAKER,MAKSYMROFS)
$2-i2file: ;@$$(call IMAKER,I2FILE)

variant$2 variant$2%     : USE_CONE = 0
variant$2 variant$2% $2_%: USE_VARIANTBLD = $3
variant$2 variant$2% $2_%: $2$$(TARGETEXT) ;

#==============================================================================
# Helps

$(call add_help,$2,t,Create $$($1_TITLE) image.)
$(call add_help,$2-dir,t,Create directory structure for $$($1_TITLE) creation.)
$(call add_help,$2-i2file,t,Extract all files from $$($1_TITLE) image.)
$(call add_help,$2-image,t,Create $$($1_TITLE) image (.img) file.)
$(call add_help,$2-pre,t,Run pre-step, create files etc. for $$($1_TITLE) creation.)
$(call add_help,$2-symbol,t,Create $$($1_TITLE) symbol file.)
$(call add_help,variant$2,t,Create $$($1_TITLE) image from a variant directory. Be sure to define the VARIANT_DIR.)

endef # ROFS_EVAL


###############################################################################
#

userofs = $(eval __i_rofs := $(filter-out :%,$(subst :, :,$(subst $(,), ,$(USE_ROFS)))))$(if\
  $(filter $1,$(__i_rofs)),1,$(if $(filter d$1 D$1,$(__i_rofs)),dummy,0))

rofsdummy = $(if $(filter d%,$(USE_$1)),$(call prepeat,\
  $(call peval,$(call pquote,$(USE_ROFS)) =~ /d$1:(\d*)/i && $$1 || 100),X))

$(foreach rofs,1 2 3 4 5 6,$(eval $(call ROFS_EVAL,ROFS$(rofs),rofs$(rofs),$(rofs))))

$(call includechk,$(addprefix $(IMAKER_DIR)/imaker_rofs,2.mk 3.mk 4.mk))


# END OF IMAKER_ROFS.MK
