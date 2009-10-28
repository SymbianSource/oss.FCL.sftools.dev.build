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
# Description: iMaker ROFS2 image configuration
#



###############################################################################
#  ___  ___  ___ ___   ___
# | _ \/ _ \| __/ __| |_  )
# |   / (_) | _|\__ \  / /
# |_|_\\___/|_| |___/ /___|
#

USE_NEWLOCLZTN  = $(if $(filter 5%,$(S60_VERSION)),1,0)

ROFS2_TITLE     = ROFS2
ROFS2_DIR       = $(WORKDIR)/rofs2
ROFS2_NAME      = $(NAME)
ROFS2_PREFIX    = $(ROFS2_DIR)/$(ROFS2_NAME)
ROFS2_IDIR      =
ROFS2_HBY       =
ROFS2_OBY       =
ROFS2_OPT       =
ROFS2_MSTOBY    = $(ROFS2_PREFIX)_rofs2_master.oby
ROFS2_HEADER    =
ROFS2_INLINE    =
ROFS2_FOOTER    =
ROFS2_TIME      = $(DAY)/$(MONTH)/$(YEAR)

ROFS2_OBYGEN    =

ROFS2_VERIBY    = $(ROFS2_PREFIX)_rofs2_version.iby
ROFS2_ROMVER    = 0.01(0)
ROFS2_VERSION   = $(CORE_VERSION)
ROFS2_FWIDFILE  = $(ROFS2_PREFIX)_rofs2_fwid.txt
ROFS2_FWID      = language
ROFS2_FWIDVER   = $(LANGPACK_ID)
ROFS2_FWIDINFO  = id=$(ROFS2_FWID)\nversion=$(ROFS2_FWIDVER)\n

ROFS2_IMG       = $(ROFS2_PREFIX).rofs2.img
ROFS2_LOG       = $(ROFS2_PREFIX).rofs2.log
ROFS2_OUTOBY    = $(ROFS2_PREFIX).rofs2.oby
ROFS2_SYM       = $(ROFS2_PREFIX).rofs2.symbol

ROFS2_PLUGINLOG = $(ROFS2_PREFIX)_rofs2_bldromplugin.log
ROFS2_PAGEFILE  = $(ODP_PAGEFILE)
ROFS2_UDEBFILE  = $(TRACE_UDEBFILE)

ROFS2_ICHKLOG   = $(ROFS2_PREFIX)_rofs2_imgcheck.log
ROFS2_ICHKOPT   = $(IMGCHK_OPT)
ROFS2_ICHKIMG   = $(ROFS2_IMG) $(CORE_ICHKIMG)

ROFS2_I2FDIR    = $(ROFS2_DIR)/img2file

#==============================================================================

define ROFS2_MSTOBYINFO
  $(BLDROM_HDRINFO)

  ROM_IMAGE 0        non-xip size=0x00000000
  ROM_IMAGE 1 dummy1 non-xip size=$(ROFS_MAXSIZE)
  ROM_IMAGE 2  rofs2 non-xip size=$(ROFS_MAXSIZE)
  ROM_IMAGE 3 dummy3 non-xip size=$(ROFS_MAXSIZE)

  $(BLDROM_PLUGINFO)

  // ROFS2 header
  //
  $(ROFS2_HDRINFO)

  ROM_IMAGE[2] {
    $(call ODP_CODEINFO,2)
    $(BLR.ROFS2.OBY)
    $(ROFS2_INLINE)
    $(ROFS2_FOOTERINFO)
  }
endef

define ROFS2_HDRINFO
  $(DEFINE) _IMAGE_WORKDIR $(ROFS2_DIR)
  $(call mac2cppdef,$(BLR.ROFS2.OPT))
  $(call iif,$(USE_NEWLOCLZTN),
    $(foreach lang,$(call getlangbyid,$(LANGPACK_LANGS)),
      #define __LOCALES_$(lang)_IBY__)
    $(foreach lang,$(call getlangbyid,$(LANGPACK_LANGS)),
      ADD_LANGUAGE $(lang))
  )
  $(BLR.ROFS2.HBY)
  $(ROFS2_HEADER)
  $(if $(filter 2,$(USE_VARIANTBLD)),$(VARIANT_HEADER))
endef

define ROFS2_FOOTERINFO
  $(if $(ROFS2_TIME),time=$(ROFS2_TIME))
  $(ROFS2_FOOTER)
endef

define ROFS2_VERIBYINFO
  // Generated `$(ROFS2_VERIBY)$' for ROFS2 image creation
  $(if $(ROFS2_ROMVER),

    version=$(ROFS2_ROMVER))

  OVERRIDE_REPLACE/ADD
  $(call iif,$(USE_NEWLOCLZTN),
    data-override=$(LANGPACK_LANGFILE)  RESOURCE_FILES_DIR\Bootdata\languages.txt
    data-override=$(LANGPACK_IDFILE)  RESOURCE_FILES_DIR\versions\lang.txt
    data-override=$(LANGPACK_SWVERFILE)  RESOURCE_FILES_DIR\versions\langsw.txt
  )
  $(call iif,$(USE_FOTA),
    data-override=$(ROFS2_FWIDFILE)  RESOURCE_FILES_DIR\versions\fwid2.txt)
  OVERRIDE_END
endef

#==============================================================================

CLEAN_ROFS2FILE =\
  del | "$(ROFS2_MSTOBY)" "$(ROFS2_VERIBY)" "$(ROFS2_FWIDFILE)" |\
  $(CLEAN_LANGFILE) |\
  del | $(call getgenfiles,$(call _buildoby,$(ROFS2_OBYGEN)))

BUILD_ROFS2FILE =\
  echo-q | Generating file(s) for ROFS2 image creation |\
  write  | $(ROFS2_MSTOBY) | $(call def2str,$(ROFS2_MSTOBYINFO)) |\
  $(call iif,$(USE_VERGEN),\
    write  | $(ROFS2_VERIBY)   | $(call def2str,$(ROFS2_VERIBYINFO)) |\
    writeu | $(ROFS2_FWIDFILE) | $(ROFS2_FWIDINFO) |)\
  $(call iif,$(USE_NEWLOCLZTN),$(BUILD_LANGFILE)) |\
  $(call _buildoby,$(ROFS2_OBYGEN))


###############################################################################
#

LANGPACK_SYSLANGMK     = system_languages.mk

LANGPACK_ROOT          = $(PRODUCT_DIR)/language
LANGPACK_PREFIX        = langpack_
LANGPACK_MKNAME        = language_variant.mk
LANGPACK_NAME          =
LANGPACK_DIR           = $(LANGPACK_ROOT)/$(LANGPACK_NAME)
LANGPACK_CONFML        = $(or $(wildcard $(LANGPACK_DIR)/$(CONFT_CFGNAME).confml),$(PRODVARIANT_CONFML))
LANGPACK_CONFCP        = $(PRODVARIANT_CONFCP) $(if $(wildcard $(LANGPACK_DIR)/$(CONFT_CFGNAME).confml),$(CONFT_CFGNAME))

LANGPACK_IDFILE        = $(ROFS2_PREFIX)_rofs2_lang.txt
LANGPACK_ID            = 01
LANGPACK_LANGFILE      = $(ROFS2_PREFIX)_rofs2_languages.txt
LANGPACK_LANGS         = English
LANGPACK_DEFAULTLANG   = $(word 1,$(LANGPACK_LANGS))
LANGPACK_DEFAULTREGION = Western
LANGPACK_SWVERFILE     = $(ROFS2_PREFIX)_rofs2_langsw.txt
LANGPACK_SWVERINFO     = $(CORE_SWVERINFO)
LANGPACK_INFOFILE      = $(ROFS2_PREFIX)_rofs2_$(LANGPACK_NAME)_info.txt

LANGPACK_LANGNAMES     = $(call getlangname,$(LANGPACK_LANGS))
LANGPACK_LANGIDS       = $(call getlangid,$(LANGPACK_LANGS))
LANGPACK_DEFLANGNAME   = $(call getlangname,$(LANGPACK_DEFAULTLANG))
LANGPACK_DEFLANGID     = $(call getlangid,$(LANGPACK_DEFAULTLANG))
LANGPACK_REGION        = $(call getlangregion,$(LANGPACK_DEFAULTLANG))

#==============================================================================

CLEAN_LANGFILE = del | "$(LANGPACK_LANGFILE)" "$(LANGPACK_IDFILE)" "$(LANGPACK_SWVERFILE)" "$(LANGPACK_INFOFILE)"
BUILD_LANGFILE =\
  echo-q | Generating language files for Language Package image creation |\
  $(if $(strip $(LANGUAGE_SYSLANGS)),,\
    error | 1 | No system languages defined\n |)\
  $(if $(strip $(LANGPACK_LANGS)),,\
    error | 1 | No languages defined in the language pack\n |)\
  $(call select,$(words $(LANGPACK_LANGS)),$(words $(LANGPACK_LANGIDS)),,\
    error | 1 | Not all languages of the language pack defined in the system languages\n |)\
  $(call select,$(words $(LANGPACK_LANGS)),$(words $(call getlangbyid,$(LANGPACK_LANGS))),,\
    error | 1 | Duplicate language defined in the language pack\n |)\
  $(if $(strip $(LANGPACK_DEFAULTLANG)),,\
    error | 1 | No default language defined\n |)\
  $(if $(word 2,$(LANGPACK_DEFAULTLANG)),\
    error | 1 | More than one default language defined\n |)\
  $(if $(filter $(call lcase,$(LANGPACK_DEFAULTLANG)),$(call lcase,$(LANGPACK_LANGS))),,\
    error | 1 | Default language not defined in the language pack languages\n |)\
  $(if $(word 2,$(sort $(call getlangregion,$(LANGPACK_LANGS)))),\
    error | 1 | Not all languages of the language pack belong to the same region\n |)\
  \
  writeu | $(LANGPACK_LANGFILE)  | $(LANGPACK_LANGINFO) |\
  writeu | $(LANGPACK_IDFILE)    | $(LANGPACK_ID) |\
  writeu | $(LANGPACK_SWVERFILE) | $(LANGPACK_SWVERINFO) |\
  $(if $(LANGPACK_NAME),\
    write | $(LANGPACK_INFOFILE) | $(call def2str,$(LANGPACK_INFO)))

LANGPACK_LANGINFO =\
  $(foreach lang,$(LANGPACK_LANGIDS),\
    $(lang)$(call select,$(lang),$(LANGPACK_DEFLANGID),$(,)d)\n)

define LANGPACK_INFO
  Generated `$(LANGPACK_INFOFILE)$' for documenting the language selections

  Name         : $(LANGPACK_NAME)
  Default Lang.: $(LANGPACK_DEFLANGNAME) ($(LANGPACK_DEFLANGID))
  Languages    : $(LANGPACK_LANGNAMES)
  Language IDs : $(LANGPACK_LANGIDS)
  Region       : $(LANGPACK_REGION)
endef


###############################################################################
# ROFS2 pre

CLEAN_ROFS2PRE = $(if $(filter 2,$(USE_VARIANTBLD)),$(CLEAN_CUSTVARIANT) |) $(CLEAN_ROFS2FILE)
BUILD_ROFS2PRE =\
  $(if $(filter 2,$(USE_VARIANTBLD)),$(BUILD_CUSTVARIANT) |)\
  mkcd | $(ROFS2_DIR) |\
  $(BUILD_ROFS2FILE)

#==============================================================================
# ROFS2 build

BLR.ROFS2.IDIR = $(call dir2inc,$(ROFS2_IDIR) $(call iif,$(USE_FEATVAR),,$(FEATVAR_IDIR)))
BLR.ROFS2.HBY  = $(call includeiby,$(IMAGE_HBY) $(ROFS2_HBY))
BLR.ROFS2.OBY  = $(call includeiby,$(ROFS2_OBY) $(if $(filter 2,$(USE_VARIANTBLD)),$(VARIANT_OBY)) $(call iif,$(USE_VERGEN),$(ROFS2_VERIBY)))
BLR.ROFS2.OPT  = $(ROFS2_OPT) $(if $(filter 2,$(USE_PAGEDCODE)),$(if $(ODP_CODECOMP),-c$(ODP_CODECOMP))) -o$(notdir $(ROFS2_NAME).img) $(BLDROPT)
BLR.ROFS2.POST = $(call iif,$(KEEPTEMP),,del | $(ROFS2_PREFIX).???)

CLEAN_ROFS2 = $(CLEAN_BLDROM)
BUILD_ROFS2 = $(BUILD_BLDROM)

#==============================================================================
# ROFS2 post

CLEAN_ROFS2POST = $(CLEAN_IMGCHK) | $(CLEAN_MAKSYMROFS)
BUILD_ROFS2POST =\
  $(call iif,$(USE_IMGCHK),$(BUILD_IMGCHK) |)\
  $(call iif,$(USE_SYMGEN),$(BUILD_MAKSYMROFS))

#==============================================================================

SOS.ROFS2.STEPS = $(call iif,$(USE_ROFS2),$(call iif,$(SKIPPRE),,ROFS2PRE) $(call iif,$(SKIPBLD),,ROFS2) $(call iif,$(SKIPPOST),,ROFS2POST))
ALL.ROFS2.STEPS = $(SOS.ROFS2.STEPS)


###############################################################################
# Targets

.PHONY: rofs2 rofs2-all rofs2-image rofs2-pre rofs2-check rofs2-symbol rofs2-i2file

rofs2 rofs2-%  : IMAGE_TYPE = ROFS2
rofs2-all      : USE_SYMGEN = 1

rofs2 rofs2-all: ;@$(call IMAKER,$$(ALL.ROFS2.STEPS))
rofs2-image    : ;@$(call IMAKER,$$(SOS.ROFS2.STEPS))

rofs2-pre      : ;@$(call IMAKER,ROFS2PRE)
rofs2-check    : ;@$(call IMAKER,IMGCHK)
rofs2-symbol   : ;@$(call IMAKER,MAKSYMROFS)

rofs2-i2file   : USE_ROFS = 2
rofs2-i2file   : ;@$(call IMAKER,VARIANTI2F)

# langpack_%
$(LANGPACK_PREFIX)%: LANGPACK_NAME  = $(TARGETNAME)
$(LANGPACK_PREFIX)%: LANGPACK_ID    = $(TARGETID)
$(LANGPACK_PREFIX)%: VARIANT_DIR    = $(LANGPACK_DIR)
$(LANGPACK_PREFIX)%: VARIANT_MKNAME = $(LANGPACK_MKNAME)
$(LANGPACK_PREFIX)%: VARIANT_CONFML = $(LANGPACK_CONFML)
$(LANGPACK_PREFIX)%: VARIANT_CONFCP = $(LANGPACK_CONFCP)
$(LANGPACK_PREFIX)%: variantrofs2_$(TARGETID)$(TARGETEXT) ;

# langpack_all langpack_china langpack_japan langpack_western
.PHONY: $(addprefix $(LANGPACK_PREFIX),all china japan western)

$(addprefix $(LANGPACK_PREFIX),all china japan western):\
  ;@$(call IMAKER,$$(addsuffix |,$$(call getlpacksbyregion,$(LANGPACK_ID))))

#==============================================================================
# Helps

$(call add_help,LANGPACK_DIR,v,(string),Overrides the VARIANT_DIR for language pack, see the instructions of VARIANT_CONFCP for details.)
$(call add_help,LANGPACK_CONFML,v,(string),Overrides the VARIANT_CONFML for language pack, see the instructions of VARIANT_CONFML for details.)
$(call add_help,LANGPACK_CONFCP,v,(string),Overrides the VARIANT_CONFCP for language pack, see the instructions of VARIANT_CONFCP for details.)
$(call add_help,LANGPACK_LANGS,v,(string),Languages are the languages that are taken to the image (SC language is is defaulting to 01 in languages.txt))
$(call add_help,LANGPACK_DEFAULTLANG,v,(string),Default language is the language where the device will boot to (SIM language overrides this selection))
$(call add_help,LANGPACK_ID,v,(string),Language id used in the lang.txt generation)

$(call add_help,$(LANGPACK_PREFIX)all,t,Create all language packages.)
$(call add_help,$(LANGPACK_PREFIX)china,t,Create language packages that belong to China region.)
$(call add_help,$(LANGPACK_PREFIX)japan,t,Create language packages that belong to Japan region.)
$(call add_help,$(LANGPACK_PREFIX)western,t,Create language packages that belong to Western region.)


###############################################################################
# Functions

# Convert a list of language names and/or ids to numeric codes (ids) based on the system language mapping, e.g. English => 01, etc.
getlangid   = $(call _getlang,$1,$(LANGUAGE_ID-NAME),2)
# Sorted by language ids and duplicates removed
getlangbyid = $(call _getlang,$1,$(LANGUAGE_ID-NAME),2,1)

# Language ids/names to language names, e.g. 01 => English, etc.
getlangname  = $(call _getlang,$1,$(LANGUAGE_ID-NAME),3)
getlnamebyid = $(call _getlang,$1,$(LANGUAGE_ID-NAME),3,1)

# Language ids/names to language regions, e.g. 01/English => Western, etc.
getlangregion  = $(call _getlang,$1,$(LANGUAGE_ID-REGION),2)
getlregionbyid = $(call _getlang,$1,$(LANGUAGE_ID-REGION),2,1)

# Get all language pack targets that belong to a given region
getlpacksbyregion = $(strip\
  $(foreach file,$(wildcard $(LANGPACK_ROOT)/$(LANGPACK_PREFIX)*/$(LANGPACK_MKNAME)),\
    $(eval include $(file))\
    $(if $(call select,$1,all,1)$(call select,$1,$(LANGPACK_REGION),1),\
      $(notdir $(patsubst %/,%,$(dir $(file)))))))


###############################################################################
# Internal stuff

LANGUAGE_EVAL =\
  $(eval -include $(call findfile,$(LANGPACK_SYSLANGMK),$(FEATVAR_IDIR)))\
  $(eval LANGUAGE_ID-NAME :=)$(eval LANGUAGE_ID-REGION :=)\
  $(call _evallangdata,$(subst $(\n), | ,$(LANGUAGE_SYSLANGS)))

_evallangdata = $(if $1,\
  $(eval __i_ldata := $(call getelem,1,$1))\
  $(if $(eval __i_lid := $(word 2,$(__i_ldata)))$(__i_lid),\
    $(eval __i_lidx   := $(call _getlangid,$(__i_lid)))\
    $(eval __i_region := $(or $(word 3,$(__i_ldata)),$(LANGPACK_DEFAULTREGION)))\
    $(eval LANGUAGE_ID-NAME   += $(__i_lidx)|$(__i_lid)|$(word 1,$(__i_ldata))|$(call lcase,$(word 1,$(__i_ldata))))\
    $(eval LANGUAGE_ID-REGION += $(__i_lidx)|$(__i_region)|$(call lcase,$(__i_region))))\
  $(call _evallangdata,$(if $(__i_ldata),$(call restwords,3,$(call restwords,$(words $(__i_ldata)),$1)),$(call restwords,$1))))

_getlang = $(strip\
  $(eval __i_lids :=)\
  $(foreach id,$1,\
    $(eval __i_lidx := $(call _getlangid,$(id)))\
    $(eval __i_lids += $(if $(filter $(__i_lidx)|%,$(LANGUAGE_ID-NAME)),$(__i_lidx),\
      $(word 1,$(subst |, ,$(filter %|$(call lcase,$(id)),$(LANGUAGE_ID-NAME)))))))\
  $(foreach lid,$(if $4,$(sort $(__i_lids)),$(__i_lids)),\
    $(word $3,$(subst |, ,$(filter $(lid)|%,$2)))))

_getlangid =\
  $(if $(filter 0%,$1),$(call _getlangid,$(call substr,2,,$1)),\
    $(eval __i_len := $(call strlen,$1))$(eval __i_prefix := 0)\
    $(call sstrip,$(foreach len,6 5 4 3 2 1,$(if $(filter $(len),$(__i_len)),$(eval __i_prefix :=))$(__i_prefix)))$1)


# END OF IMAKER_ROFS2.MK
