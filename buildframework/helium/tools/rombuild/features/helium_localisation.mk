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
# Description: 
#
###############################################################################
ifeq ($(RD_LOCALISATION),1)
#include image_conf_language_definitions.mk
endif
define to_language_names
$(foreach lid,$(subst $(comma), ,$1),$(LANGUAGE_$(lid)))
endef
###############################################################################

###############################################################################
# Variation helpers
#
###############################################################################
match_re=$(shell perl -e "print "1" if (\"$1\" =~ /$2/i);")
# find_variant_path(variantid, toplevel_variant_directory)
find_variant_path=$(foreach path,$(wildcard $2/*_*),$(if $(call match_re,$(path),_$1$$),$(path)/data $(path)))
# find_variants_path(variantid_list, toplevel_variant_directory)
find_variants_path=$(foreach variantid,$1,$(call find_variant_path,$(variantid),$2))
###############################################################################



###############################################################################
# Simple languagepack automation
###############################################################################
ifeq ($(HELIUM_LOCALISATION),1)
LP_AUTOMATION_OVERRIDE_IBY=$(ROFS2_NAME)_override_lp_automation.iby
HELIUM_LANGUAGES_TXT=$(ROFS2_NAME)_languages.txt
HELIUM_LANG_TXT=$(ROFS2_NAME)_lang.txt

# Generate the language files based on LANGUAGE_IDS, DEFAULT_LANGUAGE_ID and LANGID
#
CLEAN_HELIUM_LANGFILES = echo | Deleting $(HELIUM_LANG_TXT)\n | del | $(HELIUM_LANG_TXT) | echo | Deleting $(HELIUM_LANGUAGES_TXT)\n |  del | $(HELIUM_LANGUAGES_TXT)
BUILD_HELIUM_LANGFILES = \
  echo   | Generating the language files for Variant image creation\n | \
  writeu | $(HELIUM_LANG_TXT) | $(LANGID) | \
  writeu | $(HELIUM_LANGUAGES_TXT) | \
    $(call sstrip,$(foreach lang,$(LANGUAGE_IDS), \
      $(lang)$(call select,$(lang),$(DEFAULT_LANGUAGE_ID),$(comma)d)\n)) | \
    $(if $(findstring $(DEFAULT_LANGUAGE_ID),$(LANGUAGE_IDS)),, \
      echo | Error: Default_language=$(DEFAULT_LANGUAGE_ID) was not found in the list of variant languages=$(LANGUAGE_IDS)\n)


CLEAN_HELIUM_CREATE_LP_AUTOMATION_OVERRIDE_IBY = echo | Deleting $(LP_AUTOMATION_OVERRIDE_IBY)\n | del | $(LP_AUTOMATION_OVERRIDE_IBY)
BUILD_HELIUM_CREATE_LP_AUTOMATION_OVERRIDE_IBY = \
	echo  | Generating the $(LP_AUTOMATION_OVERRIDE_IBY)\n | \
	write | $(LP_AUTOMATION_OVERRIDE_IBY) | // Generated iby for lp automation\n\
	\n\#ifndef __GENERATED_LP_AUTOMATION_OVERRIDE_VERSION_IBY__\
	\n\#define __GENERATED_LP_AUTOMATION_OVERRIDE_VERSION_IBY__\n\
	\nROM_IMAGE[2] {\
	\ndata-override=$(HELIUM_LANGUAGES_TXT)	resource\Bootdata\languages.txt\
	\ndata-override=$(HELIUM_LANG_TXT) 	resource\versions\lang.txt\
	$(foreach lang,$(LANGUAGE_IDS),\n\#include <Locales_$(lang).iby>)\
	\n}\
	\n\n\#endif // __GENERATED_LP_AUTOMATION_OVERRIDE_VERSION_IBY__\n



# iMaker hook integration.
BLR.ROFS2.PRE += HELIUM_LANGFILES HELIUM_CREATE_LP_AUTOMATION_OVERRIDE_IBY
ROFS2_OBY += $(call iif,$(USE_OVERRIDE),$(LP_AUTOMATION_OVERRIDE_IBY),)
endif

