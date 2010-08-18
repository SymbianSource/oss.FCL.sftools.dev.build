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
# Description: iMaker ROFS2 image configuration
#



###############################################################################
#  ___  ___  ___ ___   ___
# | _ \/ _ \| __/ __| |_  )
# |   / (_) | _|\__ \  / /
# |_|_\\___/|_| |___/ /___|
#

ROFS2_FEAXML    = $(E32ROMINC)/featuredatabase.xml $(E32INC)/s60features.xml
ROFS2_FEAIBY    = $(ROFS2_DIR)/feature.iby $(ROFS2_DIR)/s60features.iby

ROFS2_ID        = $(LANGPACK_ID)
ROFS2_REVISION  = $(LANGPACK_REVISION)
ROFS2_SWVERINFO = $(ROFS2_VERSION)\n$(BUILD_YEAR)-$(BUILD_MONTH)-$(BUILD_DAY)\n$(PRODUCT_TYPE)\n(c) $(PRODUCT_MANUFACT)
ROFS2_SWVERTGT  = $(IMAGE_VERSDIR)\langsw.txt
ROFS2_FWID      = language

ROFS2_ICHKIMG  += $(CORE_ICHKIMG)

ROFS2_CONECONF  = $(PRODUCT_NAME)_langpack_$(LANGPACK_ID)_root.confml


###############################################################################
# ROFS2 pre

define ROFS2_HDRINFO
  $(DEFINE) _IMAGE_WORKDIR $(ROFS2_DIR)
  $(call mac2cppdef,$(BLR.ROFS2.OPT))
  $(foreach lang,$(call getlangbyid,$(LANGPACK_LANGS)),
    #define __LOCALES_$(lang)_IBY__)
  $(foreach lang,$(call getlangbyid,$(LANGPACK_LANGS)),
    LANGUAGE_CODE $(lang))
  $(call iif,$(USE_QTLOCLZTN),QT_TO_SYMBIAN_LANGID $(LANGPACK_SYSLANGINI))
  $(BLR.ROFS2.HBY)
  $(ROFS2_HEADER)
  $(if $(filter 2,$(USE_VARIANTBLD)),$(VARIANT_HEADER))
endef

ROFS2_ORIDEINFO += $(LANGPACK_ORIDEINFO)

define LANGPACK_ORIDEINFO
  OVERRIDE_REPLACE/ADD
  data-override="$(LANGPACK_LANGFILE)"  "RESOURCE_FILES_DIR\Bootdata\languages.txt"
  data-override="$(LANGPACK_IDFILE)"  "$(IMAGE_VERSDIR)\lang.txt"
  OVERRIDE_END
endef

#==============================================================================

CLEAN_ROFS2FILE += | $(CLEAN_LANGFILE)
BUILD_ROFS2FILE += | $(BUILD_LANGFILE)


###############################################################################
# Language package

LANGPACK_SYSLANGMK     = $(call findfile,system_languages.mk,,1)
LANGPACK_SYSLANGINI    = $(E32DATAZ)/resource/system_languages.ini

LANGPACK_ROOT          = $(or $(wildcard $(PRODUCT_DIR)/language),$(or $(if $(PRODUCT_MSTNAME),$(wildcard $(PRODUCT_MSTDIR)/language)),$(PRODUCT_DIR)/language))
LANGPACK_PREFIX        = langpack_
LANGPACK_MKNAME        = language_variant.mk
LANGPACK_NAME          = $(LANGPACK_PREFIX)$(LANGPACK_ID)
LANGPACK_DIR           = $(if $(and $(call true,$(USE_CONE)),$(call true,$(IMAKER_MKRESTARTS))),$(CONE_OUTDIR),$(LANGPACK_ROOT)/$(LANGPACK_NAME)$(call iif,$(USE_CONE),/content))
LANGPACK_DIRS          = $(wildcard $(LANGPACK_ROOT)/$(LANGPACK_PREFIX)*$(call iif,$(USE_CONE),/content))
LANGPACK_MK            = $(or $(wildcard $(LANGPACK_DIR)/$(LANGPACK_MKNAME)),$(wildcard $(LANGPACK_ROOT)/$(LANGPACK_NAME)/content/$(LANGPACK_MKNAME)))

LANGPACK_IDFILE        = $(ROFS2_PREFIX)_rofs2_lang.txt
LANGPACK_IDINFO        = $(ROFS2_VERSION)
LANGPACK_ID            = $(if $(filter $(LANGPACK_PREFIX)%,$(TARGETNAME)),$(TARGETID1),01)
LANGPACK_REVISION      = 01
LANGPACK_LANGFILE      = $(ROFS2_PREFIX)_rofs2_languages.txt
LANGPACK_LANGS         = English
LANGPACK_DEFAULTLANG   = $(word 1,$(LANGPACK_LANGS))
LANGPACK_DEFAULTREGION = Western
LANGPACK_REGIONS       = china japan western
LANGPACK_INFOFILE      = $(ROFS2_PREFIX)_rofs2_$(LANGPACK_NAME)_info.txt

LANGPACK_LANGNAMES     = $(call getlangname,$(LANGPACK_LANGS))
LANGPACK_LANGIDS       = $(call getlangid,$(LANGPACK_LANGS))
LANGPACK_DEFLANGNAME   = $(call getlangname,$(LANGPACK_DEFAULTLANG))
LANGPACK_DEFLANGID     = $(call getlangid,$(LANGPACK_DEFAULTLANG))
LANGPACK_REGION        = $(call getlangregion,$(LANGPACK_DEFAULTLANG))

#==============================================================================

CLEAN_LANGFILE = del | "$(LANGPACK_LANGFILE)" "$(LANGPACK_IDFILE)" "$(LANGPACK_INFOFILE)"
BUILD_LANGFILE =\
  echo-q | Generating language files for Language Package image creation |\
  $(if $(strip $(LANGUAGE_SYSLANGS)),,\
    error | 1 | No system languages defined. |)\
  $(if $(strip $(LANGPACK_LANGS)),,\
    error | 1 | No languages defined in the language pack. |)\
  $(call select,$(words $(LANGPACK_LANGS)),$(words $(LANGPACK_LANGIDS)),,\
    error | 1 | Not all languages of the language pack defined in the system languages. |)\
  $(call select,$(words $(LANGPACK_LANGS)),$(words $(call getlangbyid,$(LANGPACK_LANGS))),,\
    error | 1 | Duplicate language defined in the language pack. |)\
  $(if $(strip $(LANGPACK_DEFAULTLANG)),,\
    error | 1 | No default language defined. |)\
  $(if $(word 2,$(LANGPACK_DEFAULTLANG)),\
    error | 1 | More than one default language defined. |)\
  $(if $(filter $(call lcase,$(LANGPACK_DEFAULTLANG)),$(call lcase,$(LANGPACK_LANGS))),,\
    error | 1 | Default language not defined in the language pack languages. |)\
  $(if $(word 2,$(sort $(call getlangregion,$(LANGPACK_LANGS)))),\
    error | 1 | Not all languages of the language pack belong to the same region. |)\
  \
  writeu | "$(LANGPACK_LANGFILE)" | $(LANGPACK_LANGINFO) |\
  writeu | "$(LANGPACK_IDFILE)"   | $(LANGPACK_IDINFO) |\
  $(if $(LANGPACK_NAME),\
    write | "$(LANGPACK_INFOFILE)" | $(call def2str,$(LANGPACK_INFO)))

LANGPACK_LANGINFO =\
  $(foreach lang,$(LANGPACK_LANGIDS),\
    $(lang)$(call select,$(lang),$(LANGPACK_DEFLANGID),$(,)d)\n)

define LANGPACK_INFO
  Generated `$(LANGPACK_INFOFILE)' for documenting the language selections

  Name         : $(LANGPACK_NAME)
  Default Lang.: $(LANGPACK_DEFLANGNAME) ($(LANGPACK_DEFLANGID))
  Languages    : $(LANGPACK_LANGNAMES)
  Language IDs : $(LANGPACK_LANGIDS)
  Region       : $(LANGPACK_REGION)
endef


###############################################################################
# Targets

LANGPACK_EXPORT = $(if $(filter $(LANGPACK_PREFIX)%,$(TARGETNAME)),$(addprefix $(LANGPACK_PREFIX)%:LANGPACK_,ID NAME))
TARGET_EXPORT  += $(LANGPACK_EXPORT)

# langpack_all langpack_china langpack_japan langpack_western
.PHONY: $(addprefix $(LANGPACK_PREFIX),all $(LANGPACK_REGIONS))

$(addprefix $(LANGPACK_PREFIX),all $(LANGPACK_REGIONS)) \
$(addsuffix -%,$(addprefix $(LANGPACK_PREFIX),all $(LANGPACK_REGIONS))):\
  ;@$(call IMAKER,$$(call getlpacksbyregion,$(LANGPACK_ID)))

$(LANGPACK_PREFIX)%: rofs2_$$* ;


###############################################################################
# Helps

$(call add_help,LANGPACK_DIR,v,(string),Overrides the VARIANT_DIR for language pack, see the instructions of VARIANT_DIR for details.)
$(call add_help,LANGPACK_LANGS,v,(string),Languages are the languages that are taken to the image (SC language is is defaulting to 01 in languages.txt))
$(call add_help,LANGPACK_DEFAULTLANG,v,(string),Default language is the language where the device will boot to (SIM language overrides this selection))
$(call add_help,LANGPACK_ID,v,(string),Language id used in the lang.txt generation)

$(call add_help,$(LANGPACK_PREFIX)all,t,Create all language packages.)
$(call add_help,$(LANGPACK_PREFIX)china,t,Create language packages that belong to China region.)
$(call add_help,$(LANGPACK_PREFIX)japan,t,Create language packages that belong to Japan region.)
$(call add_help,$(LANGPACK_PREFIX)western,t,Create language packages that belong to Western region.)

LANGPACK_HELP =\
  $(call add_help,$(call getlpfrompath,$(LANGPACK_DIRS)),t,Language variant target.)\
  $(eval include $(wildcard $(addsuffix /$(LANGPACK_MKNAME),$(LANGPACK_DIRS))))

BUILD_HELPDYNAMIC += $(LANGPACK_HELP)


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
  $(foreach file,$(wildcard $(addsuffix /$(LANGPACK_MKNAME),$(LANGPACK_DIRS))),\
    $(eval include $(file))\
    $(if $(call select,$1,all,1)$(call select,$1,$(LANGPACK_REGION),1),$(call getlpfrompath,$(file)))))

# Get language pack target(s) from given path(s)
getlpfrompath = $(filter $(LANGPACK_PREFIX)%,$(call substm,/ \, ,$1))


###############################################################################
# Internal stuff

LANGUAGE_EVAL =\
  $(eval LANGUAGE_ID-NAME :=)$(eval LANGUAGE_ID-REGION :=)\
  $(call _evallangdata,$(strip $(subst $(\n), | ,$(LANGUAGE_SYSLANGS))))

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
