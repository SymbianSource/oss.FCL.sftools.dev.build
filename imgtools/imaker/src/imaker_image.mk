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
# Description: Default iMaker image configuration
#



USE_FEATVAR    = $(call select,$(word 1,$(getsbvrominc)),invalid,0,1)
USE_IMGCHK     = 0
USE_NOROMHDR   = 0
USE_QTLOCLZTN  = 0
USE_ROFS       = 1,2,3
USE_ROFSFILE   = $(call iif,$(USE_PAGING),1,0)
USE_ROMFILE    = 1
USE_SMR        = 0
USE_SYMGEN     = 0
USE_UDEB       = 0

# Temporary
USE_BLRWORKDIR = 0

#==============================================================================

TYPE = rnd

MAJOR_VERSION = 001
MINOR_VERSION = 000
SW_VERSION    = $(MAJOR_VERSION).$(MINOR_VERSION)
SW_TYPEINFO   = $(call select,$(TYPE),rnd,RD)

BUILD_INFOMK = $(call findfile,image_conf_buildinfo.mk,,1)
BUILD_NAMEMK = $(call findfile,image_conf_naming.mk,,1)
BUILD_YEAR   = $(YEAR)
BUILD_MONTH  = $(MONTH)
BUILD_WEEK   = $(WEEK)
BUILD_DAY    = $(DAY)
BUILD_ID     = 001
BUILD_NUMBER = 001

COREPLAT_NAME    =
COREPLAT_DIR     = $(CONFIGROOT)/$(COREPLAT_NAME)
COREPLAT_VERSION =
PLATFORM_NAME    = $(subst .,,$(COREPLAT_VERSION)$(S60_VERSION))
PLATFORM_DIR     = $(CONFIGROOT)/$(PLATFORM_NAME)
PRODUCT_MSTNAME  =
PRODUCT_MSTDIR   = $(if $(PRODUCT_MSTNAME),$(PLATFORM_DIR)/$(PRODUCT_MSTNAME))
PRODUCT_NAME     =
PRODUCT_MANUFACT = Nokia
PRODUCT_MODEL    = N00
PRODUCT_TYPE     =
PRODUCT_REVISION = 01
PRODUCT_DIR      = $(if $(PRODUCT_NAME),$(PLATFORM_DIR)/$(if $(PRODUCT_MSTNAME),$(PRODUCT_MSTNAME)/)$(PRODUCT_NAME))

FEATURE_VARIANT = $(PRODUCT_NAME)
FEATVAR_IDIR    = $(call getrominc)
FEATVAR_HRH     = $(call findfile,feature_settings.hrh)

LABEL   =
NAME    = $(or $(PRODUCT_NAME),imaker)$(LABEL)
WORKDIR = $(if $(PRODUCT_NAME),$(E32ROMBLD)/$(PRODUCT_NAME),$(CURDIR))

IMAGE_TYPE    =
IMAGE_ID      = $(or $(subst CORE,1,$(subst ROFS,,$(filter CORE ROFS%,$(IMAGE_TYPE)))),\
  $(call lcase,$(call substr,1,1,$(filter EMMC MCARD UDA,$(IMAGE_TYPE)))))
IMAGE_PREFIX  = $($(IMAGE_TYPE)_PREFIX)_$(call lcase,$(IMAGE_TYPE))
IMAGE_HBY     = <data_caging_paths_for_iby.hrh> <variant/header.iby>
IMAGE_VERSDIR = RESOURCE_FILES_DIR\versions

IMAGE_ORIDEFILES =
IMAGE_ORIDECONF  =

TRACE_IDIR     = $(addsuffix /traces,$(FEATVAR_IDIR))
TRACE_PREFIX   =
TRACE_SUFFIX   = _trace.txt
TRACE_UDEBFILE = $(E32ROMBLD)/mytraces.txt

OVERRIDE_CONF = OVERRIDE_REPLACE/WARN #OVERRIDE_REPLACE/ADD, OVERRIDE_REPLACE/SKIP, OVERRIDE_SKIP/ADD

#GENIBY_FILEPAT = *.dll *.exe *.agt *.csy *.fsy *.tsy *.drv *.nif *.pgn *.prt

ARM_VERSION = ARMV5
SOS_VERSION = #9.5
S60_VERSION =

CPPFILE_FILTER = FF_WDP_\S+|SYMBIAN_\S+
CPPFILE_LIST   = $(if $(FEATURE_VARIANT),$(FEATVAR_HRH))

TARGET_PRODUCT =
TARGET_DEFAULT = all


###############################################################################
# Internal macros and definitions

getrominc =\
  $(if $(call true,$(USE_FEATVAR)),$(getsbvrominc),$(if $(word 5,$(__i_getrominc)),$(call restwords,5,$(__i_getrominc))\
    ,$(PRODUCT_DIR) $(PRODUCT_MSTDIR) $(CONFIGROOT)) $(E32ROM) $(E32ROMINC) $(E32INC)/oem $(E32INC))

#    ,$(PRODUCT_DIR) $(PRODUCT_MSTDIR) $(CONFIGROOT)) $(E32INC)/config $(E32ROM) $(E32ROMINC) $(E32INC)/internal $(E32INC))

getsbvrominc =\
  $(if $(and $(FEATURE_VARIANT),$(call equal,$(__i_featvar),$(FEATURE_VARIANT))),,$(eval __i_featvar := $(FEATURE_VARIANT))\
    $(eval __i_getrominc := $(if $(__i_featvar),$(shell $(PERL) -x $(IMAKER_TOOL) --incdir $(__i_featvar)),invalid)))$(__i_getrominc)

includeiby = $(if $(strip $1),$(call peval,\
  my @files = ();\
  while ($(call pquote,$1) =~ /(?:([1-6]):)?(?:<(.+?)>|"+(.+?)"+|(\S+))/g) {\
    my $$rom = (defined($$1) ? $$1 : q());\
    push(@files, ($$rom ? q(ROM_IMAGE[).$$rom.q(] {\n) : q()) . q(\#include ).\
      (defined($$2) ? qq(<$$2>) : q(").GetAbsFname(defined($$3) ? $$3 : $$4).q(")) . ($$rom ? q(\n}) : q()))\
  }\
  return(join(q(), map(q(\n) . $$_, @files)))))

define BLDROM_HDRINFO
  // Generated master oby for $($1_TITLE) image creation
  //
  // Filename: $($1_MSTOBY)
  // Command : $(call BLDROM_CMD,$1)
endef

define BLDROM_PLUGINFO
  /* Buildrom plugins
  */
  externaltool=override:-i$1;-l$($1_PLUGINLOG)$(if $(filter debug 127,$(VERBOSE)),;-ddebug)
  $(OVERRIDE_CONF)
  externaltool=obyparse:-i$1;-l$($1_PLUGINLOG);-w$($1_DIR)$(if $(filter debug 127,$(VERBOSE)),;-ddebug);-f$(FEATURE_VARIANT)
  externaltool=stubsischeck:-i$1;-l$($1_PLUGINLOG)$(if $(filter debug 127,$(VERBOSE)),;-ddebug)
  $(call iif,$(if $(filter CORE,$1),$(USE_ROFS1)),
    $(call iif,$(USE_ROMFILE),
      OBYPARSE_ROM $(CORE_ROMFILE))
    $(call iif,$(USE_ROFSFILE),
      OBYPARSE_ROFS1 $(CORE_ROFSFILE))
  )
  $(call iif,$(USE_UDEB),
    OBYPARSE_UDEB $(call select,$(USE_UDEB),full,*,$($1_UDEBFILE)))
endef

getgenfiles = $(if $1,\
  $(eval __i_cmd := $(filter geniby% write%,$(call lcase,$(call getelem,1,$1))))\
  $(if $(__i_cmd),"$(call getelem,2,$1)")\
  $(call getgenfiles,$(call restelems,$(if $(filter geniby%,$(__i_cmd)),7,$(if $(filter write%,$(__i_cmd)),4,2)),$1)))

#==============================================================================

BLDROM_CMD = $(BLDROM_TOOL)\
  $(filter-out --D% -U% $(filter-out $(BLDROM_CMDDOPT),$(filter -D%,$(BLR.$1.OPT))),$(BLR.$1.OPT))\
  $(BLR.$1.IDIR) $(subst \,/,$($1_MSTOBY))

BLDROM_CMDDOPT = -DFEATUREVARIANT=% -D_FULL_DEBUG -D_PLAT=%

CLEAN_BLDROM =\
  del | $(foreach file,dir *.img *.inc *.log *.oby *.symbol,"$($1_PREFIX).$(file)")\
    $(foreach file,ecom*.s?? features.dat loglinux.oby logwin.oby tmp?.oby,"$($1_DIR)/$(file)")\
    "$($1_PLUGINLOG)" |\
  $(BLR.$1.CLEAN)

BUILD_BLDROM =\
  $(or $(BLR.$1.BUILD),\
    echo-q | Creating $($1_TITLE) SOS $(if $(filter -noimage,$(BLR.$1.OPT)),oby,image) |\
    $(call iif,$(USE_BLRWORKDIR),,cd | "$($1_DIR)" |)\
    cmd    | $(strip $(call BLDROM_CMD,$1)) | $(BLDROM_PARSE) |\
    move   | "$($1_DIR)/tmp1.oby" | $($1_PREFIX).tmp1.oby |\
    $(call iif,$(KEEPTEMP),,del | "$($1_DIR)/tmp?.oby" "$($1_PREFIX).dummy*" |)\
    $(BLR.$1.POST))


###############################################################################
# Steps

IMAGE_STEPS = core $(VARIANT_STEPS)

VARIANT_STEPS = $(call iif,$(USE_ROFS2),langpack_$(or $(TARGETID),01))\
  $(foreach rofs,3 4 5 6,$(call iif,$(USE_ROFS$(rofs)),rofs$(rofs)))


###############################################################################
# Targets

.PHONY: default all flash image variant #i2file variant-i2file

default default-%:\
  ;@$(call IMAKER,$$(if $$(PRODUCT_NAME),,$$(TARGET_PRODUCT)) $$(TARGET_DEFAULT))

all  : ;@$(call IMAKER,flash-all)
image: ;@$(call IMAKER,flash-image)

flash flash-% image-%: ;@$(call IMAKER,$$(IMAGE_STEPS))

variant variant_% variant-%: ;@$(call IMAKER,$$(VARIANT_STEPS))

#i2file        : ;@$(call IMAKER,$(call ucase,$@))
#variant-i2file: ;@$(call IMAKER,VARIANTI2F)

#==============================================================================

$(call includechk,$(addprefix $(IMAKER_DIR)/imaker_,fat.mk odp.mk rofs.mk smr.mk core.mk variant.mk))


# END OF IMAKER_IMAGE.MK
