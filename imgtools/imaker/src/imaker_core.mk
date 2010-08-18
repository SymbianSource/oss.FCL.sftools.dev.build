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
# Description: iMaker Core image configuration
#



###############################################################################
#   ___ ___  ___ ___
#  / __/ _ \| _ \ __|
# | (_| (_) |   / _|
#  \___\___/|_|_\___|
#

CORE_TITLE       = Core (ROM$(call iif,$(USE_ROFS1), & ROFS1))
CORE_DRIVE       = Z
CORE_ROOT        = $(OUTDIR)/core
CORE_DIR         = $(CORE_ROOT)
CORE_NAME        = $(NAME)
CORE_PREFIX      = $(CORE_DIR)/$(CORE_NAME)
CORE_IDIR        =
CORE_HBY         =
CORE_OBY         =
CORE_OPT         =
CORE_MSTOBY      = $(CORE_PREFIX)_core_master.oby
CORE_HEADER      =
CORE_INLINE      =
CORE_TIME        = $(DAY)/$(MONTH)/$(YEAR)

CORE_DEFHRH      = $(CORE_PREFIX)_core_define.hrh
CORE_FEAXML      = $(E32ROMINC)/featuredatabase.xml $(E32INC)/s60features.xml $(E32INC)/s60customswfeatures.xml
CORE_FEAIBY      = $(CORE_DIR)/feature.iby $(CORE_DIR)/s60features.iby $(CORE_DIR)/s60customswfeatures.iby

CORE_ROMVER      =
CORE_VERSION     = $(SW_VERSION)
CORE_SWVERFILE   = $(CORE_PREFIX)_core_sw.txt
CORE_SWVERINFO   = $(CORE_VERSION)\n$(BUILD_YEAR)-$(BUILD_MONTH)-$(BUILD_DAY)\n$(PRODUCT_TYPE)\n(c) $(PRODUCT_MANUFACT)
CORE_MODELFILE   = $(CORE_PREFIX)_core_model.txt
CORE_MODELINFO   = S60
CORE_IMEISVFILE  = $(CORE_PREFIX)_core_imeisv.txt
CORE_IMEISVINFO  = 00
CORE_PLATFILE    = $(CORE_PREFIX)_core_platform.txt
CORE_PLATINFO    = SymbianOSMajorVersion=$(word 1,$(subst ., ,$(SOS_VERSION)))\nSymbianOSMinorVersion=$(word 2,$(subst ., ,$(SOS_VERSION)))\n
CORE_PRODFILE    = $(CORE_PREFIX)_core_product.txt
CORE_PRODINFO    = Manufacturer=$(PRODUCT_MANUFACT)\nModel=$(PRODUCT_MODEL)\nProduct=$(PRODUCT_TYPE)\nRevision=$(PRODUCT_REVISION)
CORE_ID          = general
CORE_FWIDFILE    = $(CORE_PREFIX)_core_fwid.txt
CORE_FWID        = core
CORE_FWIDVER     = $(subst -,,$(PRODUCT_TYPE))_$(CORE_VERSION)_$(CORE_ID)$(SW_TYPEINFO)
CORE_FWIDINFO    = id=$(CORE_FWID)\nversion=$(CORE_FWIDVER)\n
CORE_PURPFILE    = $(CORE_PREFIX)_core_purpose.txt
CORE_PURPINFO    = MCL
CORE_DEVATTRFILE = $(CORE_PREFIX)_core_deviceattrib.ini

define CORE_DEVATTRINFO
  [Device]
  0x10286358 = $(PRODUCT_MANUFACT)
  0x10286359 = $(PRODUCT_MODEL)
  0x1028635A = $(PRODUCT_TYPE)
  0x1028635B = $(PRODUCT_REVISION)

  [UI]
  0x1028635D = S60
  0x1028635E = $(word 1,$(subst ., ,$(S60_VERSION)))
  0x1028635F = $(word 2,$(subst ., ,$(S60_VERSION)))
  0x10286360 = $(S60_VERSION)

  [OS]
  0x10286361 = $(word 1,$(subst ., ,$(SOS_VERSION)))
  0x10286362 = $(word 2,$(subst ., ,$(SOS_VERSION)))
  0x10286363 = $(SOS_VERSION)
endef

CORE_IMG         = $(ROM_IMG) $(call iif,$(USE_ROFS1),$(ROFS1_IMG))

CORE_PLUGINLOG   = $(CORE_PREFIX)_core_bldromplugin.log
CORE_NDPROMFILE  = $(E32ROMBLD)/romfiles.txt
CORE_ODPROMFILE  = $(E32ROMBLD)/odpromfiles.txt
CORE_CDPROMFILE  = $(E32ROMBLD)/odpcoderomfiles.txt
CORE_ROMFILE     = $(call iif,$(USE_PAGING),$(if $(filter 1,$(USE_PAGEDCODE)),$(CORE_CDPROMFILE),$(CORE_ODPROMFILE)),$(CORE_NDPROMFILE))
CORE_NDPROFSFILE = $(E32ROMBLD)/rofsfiles.txt
CORE_ODPROFSFILE = $(E32ROMBLD)/odprofsfiles.txt
CORE_CDPROFSFILE = $(E32ROMBLD)/odpcoderofsfiles.txt
CORE_ROFSFILE    = $(call iif,$(USE_PAGING),$(if $(filter 1,$(USE_PAGEDCODE)),$(CORE_CDPROFSFILE),$(CORE_ODPROFSFILE)),$(CORE_NDPROFSFILE))
CORE_PAGEFILE    = $(ODP_PAGEFILE)
CORE_UDEBFILE    = $(TRACE_UDEBFILE)

CORE_OBYGEN      =
CORE_ORIDEIBY    = $(CORE_PREFIX)_core_override.iby
CORE_ORIDEFILES  = $(IMAGE_ORIDEFILES)
CORE_ORIDECONF   = $(IMAGE_ORIDECONF)

CORE_ICHKLOG     = $(CORE_PREFIX)_core_imgcheck.log
CORE_ICHKOPT     = $(IMGCHK_OPT)
CORE_ICHKIMG     = $(CORE_IMG)

CORE_I2FDIR      = $(CORE_DIR)/img2file

CORE_CONECONF    =
CORE_CONEOPT     = --all-layers --impl-tag=target:core

#==============================================================================

ROM_BUILDOPT   = $(call iif,$(USE_NOROMHDR),-no-header)
ROM_IMGHDRSIZE = 256
ROM_HEADER     =
ROM_FOOTER     =

ROM_PREFIX     = $(CORE_PREFIX).rom
ROM_IMG        = $(ROM_PREFIX).img
ROM_INC        = $(ROM_PREFIX).inc
ROM_LOG        = $(ROM_PREFIX).log
ROM_OUTOBY     = $(ROM_PREFIX).oby
ROM_SYM        = $(ROM_PREFIX).symbol

ROFS1_PREFIX   = $(CORE_PREFIX)
ROFS1_PAGEFILE =

#==============================================================================

define CORE_MSTOBYINFO
  $(call BLDROM_HDRINFO,CORE)

  $(call BLDROM_PLUGINFO,CORE)

  /* Core header
  */
  $(CORE_HDRINFO)

  /* Core ROM
  */
  ROM_IMAGE[0] {
    $(ROM_HDRINFO)
  #ifndef _IMAGE_INCLUDE_HEADER_ONLY
    $(BLR.CORE.OBY)
    $(CORE_INLINE)
    $(ROM_FOOTERINFO)
  }
  $(call iif,$(USE_ROFS1),

    /* Core ROFS1
    */
    ROM_IMAGE 1 rofs1 non-xip size=$(ROFS1_MAXSIZE)

    ROM_IMAGE[1] {
      $(ROFS1_HDRINFO)
      /* Content to be moved from ROM to ROFS1 */
    }
  )
  #endif // _IMAGE_INCLUDE_HEADER_ONLY
endef

define CORE_HDRINFO
  $(DEFINE) _IMAGE_WORKDIR $(CORE_DIR)
  $(call mac2cppdef,$(BLR.CORE.OPT))
  $(BLR.CORE.HBY)
  $(CORE_HEADER)
  $(if $(filter 1,$(USE_VARIANTBLD)),$(VARIANT_HEADER))
endef

define ROM_HDRINFO
  $(ODP_ROMINFO)
  $(ROM_HEADER)
endef

define ROM_FOOTERINFO
  $(if $(ROM_BUILDOPT),ROMBUILD_OPTION $(ROM_BUILDOPT))
  $(if $(CORE_TIME),time=$(CORE_TIME))
  $(if $(CORE_ROMVER),version=$(CORE_ROMVER))
  $(ROM_FOOTER)
endef

define ROFS1_HDRINFO
  $(ODP_ROFSINFO)
  $(ROFS1_HEADER)
  $(if $(CORE_TIME),time=$(CORE_TIME))
endef

define CORE_ORIDEINFO
  // Generated `$(CORE_ORIDEIBY)' for $(CORE_TITLE) image creation

  $(call iif,$(USE_ROFS1),\
    OVERRIDE_REPLACE/ADD
    $(if $(CORE_SWVERINFO),
      data-override="$(CORE_SWVERFILE)"  "$(IMAGE_VERSDIR)\sw.txt")
    $(if $(CORE_MODELINFO),
      data-override="$(CORE_MODELFILE)"  "$(IMAGE_VERSDIR)\model.txt")
    $(if $(CORE_IMEISVINFO),
      data-override="$(CORE_IMEISVFILE)"  "$(IMAGE_VERSDIR)\imeisv.txt")
    $(if $(CORE_PLATINFO),
      data-override="$(CORE_PLATFILE)"  "$(IMAGE_VERSDIR)\platform.txt")
    $(if $(CORE_PRODINFO),
      data-override="$(CORE_PRODFILE)"  "$(IMAGE_VERSDIR)\product.txt")
    $(if $(CORE_PURPINFO),
      data-override="$(CORE_PURPFILE)"  "$(IMAGE_VERSDIR)\purpose.txt")
    $(if $(CORE_FWIDINFO),
      data-override="$(CORE_FWIDFILE)"  "$(IMAGE_VERSDIR)\fwid1.txt")
    $(if $(CORE_DEVATTRINFO),
      data-override="$(CORE_DEVATTRFILE)"  "$(IMAGE_VERSDIR)\deviceattributes.ini")
    OVERRIDE_END
  )
endef

#==============================================================================

CLEAN_COREFILE =\
  del | "$(CORE_MSTOBY)" "$(CORE_ORIDEIBY)" "$(CORE_SWVERFILE)" "$(CORE_MODELFILE)"\
    "$(CORE_IMEISVFILE)" "$(CORE_PLATFILE)" "$(CORE_PRODFILE)" "$(CORE_PURPFILE)"\
    "$(CORE_FWIDFILE)" "$(CORE_DEVATTRFILE)" |\
  del | $(call getgenfiles,$(CORE_OBYGEN))

BUILD_COREFILE =\
  echo-q  | Generating file(s) for $(CORE_TITLE) image creation |\
  write-c | "$(CORE_MSTOBY)" | $(call def2str,$(CORE_MSTOBYINFO))\n |\
  $(call iif,$(USE_ROFS1),\
    $(if $(CORE_SWVERINFO),\
      writeu | "$(CORE_SWVERFILE)"   | $(call quote,$(CORE_SWVERINFO)) |)\
    $(if $(CORE_MODELINFO),\
      writeu | "$(CORE_MODELFILE)"   | $(CORE_MODELINFO)  |)\
    $(if $(CORE_IMEISVINFO),\
      writeu | "$(CORE_IMEISVFILE)"  | $(CORE_IMEISVINFO) |)\
    $(if $(CORE_PLATINFO),\
      writeu | "$(CORE_PLATFILE)"    | $(CORE_PLATINFO)   |)\
    $(if $(CORE_PRODINFO),\
      writeu | "$(CORE_PRODFILE)"    | $(CORE_PRODINFO)   |)\
    $(if $(CORE_PURPINFO),\
      writeu | "$(CORE_PURPFILE)"    | $(CORE_PURPINFO)   |)\
    $(if $(CORE_FWIDINFO),\
      writeu | "$(CORE_FWIDFILE)"    | $(CORE_FWIDINFO)   |)\
    $(if $(CORE_DEVATTRINFO),\
      writeu | "$(CORE_DEVATTRFILE)" | $(call def2str,$(CORE_DEVATTRINFO)) |)\
  )\
  $(if $(CORE_ORIDEINFO),\
    write-c | "$(CORE_ORIDEIBY)" | $(call def2str,$(CORE_ORIDEINFO)) |)\
  $(if $(CORE_ORIDECONF),\
    genorideiby | >>$(CORE_ORIDEIBY) | $(call def2str,$(CORE_ORIDEFILES) | $(CORE_ORIDECONF)) |)\
  $(CORE_OBYGEN)


###############################################################################
# Core pre-build step

CLEAN_COREPRE =\
 $(if $(filter 1,$(USE_VARIANTBLD)),$(CLEAN_VARIANT) |)\
 $(CLEAN_COREFILE) | $(CLEAN_DEFHRH) | $(CLEAN_FEATMAN)

BUILD_COREPRE =\
  $(if $(filter 1,$(USE_VARIANTBLD)),$(BUILD_VARIANT) |)\
  mkdir | "$(CORE_DIR)" |\
  $(BUILD_COREFILE) |\
  $(BUILD_DEFHRH)   |\
  $(BUILD_FEATMAN)

#==============================================================================
# Core build step

BLR.CORE.IDIR = $(call dir2inc,$(CORE_IDIR) $(call iif,$(USE_FEATVAR),,$(FEATVAR_IDIR)))
BLR.CORE.HBY  = $(call includeiby,<data_caging_paths_for_iby.hrh> $(CORE_HBY))
BLR.CORE.OBY  =\
  $(call includeiby,$(CORE_OBY))\
  $(and $(call true,$(SYMBIAN_FEATURE_MANAGER)),$(CORE_FEAIBY),$(call mac2cppdef,-U__FEATURE_IBY__)$(call includeiby,$(CORE_FEAIBY)))\
  $(call includeiby,$(if $(filter 1,$(USE_VARIANTBLD)),$(VARIANT_OBY)) $(BLDROBY) $(CORE_ORIDEIBY))
BLR.CORE.OPT  = $(CORE_OPT) $(if $(filter 1,$(USE_PAGEDCODE)),$(if $(ODP_CODECOMP),-c$(ODP_CODECOMP))) -o$(call pathconv,$(ROM_IMG)) $(BLDROPT)
BLR.CORE.POST =\
  test | "$(ROM_IMG)" $(call iif,$(USE_PAGEDROM),"$(ROM_INC)") |\
  $(call iif,$(USE_ROFS1),\
    move | "$(ROM_PREFIX).rofs1.img" | $(ROFS1_IMG)    |\
    move | "$(ROM_PREFIX).rofs1.log" | $(ROFS1_LOG)    |\
    move | "$(ROM_PREFIX).rofs1.oby" | $(ROFS1_OUTOBY) |\
    $(call iif,$(USE_SYMGEN),move | "$(ROM_PREFIX).rofs1.symbol" | $(ROFS1_SYM)))

CLEAN_CORE = $(call CLEAN_BLDROM,CORE)
BUILD_CORE = $(call BUILD_BLDROM,CORE)

REPORT_CORE =\
  $(CORE_TITLE) dir | $(CORE_DIR) | d |\
  Core ROM image    | $(ROM_IMG)  | f\
  $(call iif,$(USE_SYMGEN),| Core ROM symbols | $(ROM_SYM) | f)\
  $(call iif,$(USE_ROFS1),|\
    Core ROFS1 image | $(ROFS1_IMG) | f\
    $(call iif,$(USE_SYMGEN),| Core ROFS1 symbols | $(ROFS1_SYM) | f))

#==============================================================================
# Core post-build step

CLEAN_COREPOST = $(CLEAN_IMGCHK)
BUILD_COREPOST = $(call iif,$(USE_IMGCHK),$(BUILD_IMGCHK))


###############################################################################
# Core symbol generation

MAKSYM_CMD = $(MAKSYM_TOOL) $(call pathconv,"$(ROM_LOG)" "$(ROM_SYM)")

CLEAN_CORESYM = del | "$(ROM_SYM)" "$(ROFS1_SYM)"
BUILD_CORESYM =\
  echo-q | Creating $(CORE_TITLE) symbol file(s) |\
  cmd    | $(MAKSYM_CMD) |\
  $(call iif,$(USE_ROFS1),cmd | $(MAKSYMROFS_TOOL) $(call pathconv,"$(ROFS1_LOG)" "$(ROFS1_SYM)"))

REPORT_CORESYM =\
  Core ROM symbols | $(ROM_SYM) | f\
  $(call iif,$(USE_ROFS1),| Core ROFS1 symbols | $(ROFS1_SYM) | f)


###############################################################################
# Steps

SOS.CORE.STEPS =\
  $(call iif,$(SKIPPRE),,$(and $(filter 1,$(USE_VARIANTBLD)),$(call true,$(USE_CONE)),CONEGEN RESTART) COREPRE)\
  $(call iif,$(SKIPBLD),,CORE) $(call iif,$(SKIPPOST),,COREPOST)

ALL.CORE.STEPS = $(SOS.CORE.STEPS)

CORE_PRESTEPS = $(call iif,$(USE_SMR),smr |)
CORE_STEPS    = $(CORE_PRESTEPS) $(ALL.CORE.STEPS)
CORE_IMGSTEPS = $(CORE_PRESTEPS) $(SOS.CORE.STEPS)


###############################################################################
# Targets

.PHONY: core $(addprefix core-,all check cone i2file image pre symbol)

core core% rom% rofs1%: IMAGE_TYPE = CORE
core-all              : USE_SYMGEN = 1

core core-all: ;@$(call IMAKER,$$(CORE_STEPS))
core-image   : ;@$(call IMAKER,$$(CORE_IMGSTEPS))

core-cone  : ;@$(call IMAKER,CONEGEN)
core-pre   : ;@$(call IMAKER,COREPRE)
core-check : ;@$(call IMAKER,IMGCHK)
core-symbol: ;@$(call IMAKER,CORESYM)
core-i2file: ;@$(call IMAKER,I2FILE)

core-trace-%: LABEL         = _$*
core-trace-%: USE_UDEB      = 1
core-trace-%: CORE_UDEBFILE = $(call findfile,$(TRACE_PREFIX)$*$(TRACE_SUFFIX),$(TRACE_IDIR))
core-trace-%:\
  ;@$(if $(wildcard $(CORE_UDEBFILE)),,$(error Can't make target `$@', file `$(CORE_UDEBFILE)' not found))\
    $(call IMAKER,$$(ALL.CORE.STEPS))


###############################################################################
# Helps

$(call add_help,CORE_PURPFILE,v,(string),The (generated) _core_purpose.txt file name.)
$(call add_help,CORE_PURPINFO,v,(string),The content string for the purpose.txt file.)

$(call add_help,core,t,Create $$(CORE_TITLE) image.)
$(call add_help,core-dir,t,Create directory structure for $$(CORE_TITLE) creation.)
$(call add_help,core-i2file,t,Extract all files from $$(CORE_TITLE) image.)
$(call add_help,core-image,t,Create $$(CORE_TITLE) image (.img) file(s).)
$(call add_help,core-pre,t,Run pre-step, create files etc. for $$(CORE_TITLE) creation.)
$(call add_help,core-symbol,t,Create $$(CORE_TITLE) symbol file(s).)

BUILD_HELPDYNAMIC +=\
  $(foreach file,$(call reverse,$(wildcard $(addsuffix /$(TRACE_PREFIX)*$(TRACE_SUFFIX),$(TRACE_IDIR)))),\
    $(call add_help,core-trace-$(patsubst $(TRACE_PREFIX)%$(TRACE_SUFFIX),%,$(notdir $(file))),t,\
      Create $(CORE_TITLE) image with traces for $(file).))


# END OF IMAKER_CORE.MK
