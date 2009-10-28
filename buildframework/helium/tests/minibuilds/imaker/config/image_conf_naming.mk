USE_NAMEMK = 1
# Example version of image_conf_naming.mk
# If this file exists in the build area, it is read by iMaker and can be
# used for image naming, setting directories and version info generation.

# this variable is intended to be overriden by customer that would need to customize the version string.
CUSTOMIZE_VERSION?=

# setting langpack templates
ROFS2_DIR  = $(RELEASE_IMAGES_DIR)/$(PRODUCT_NAME)/$(TYPE)/langpack/$(LANGPACK_PREFIX)$(LANGPACK_ID)
ROFS2_NAME = $(PRODUCT_TYPE)_$(BUILD_ID)_$(LANGPACK_ID)_$(TYPE)

# setting core templates
CORE_NAME = $(PRODUCT_TYPE)_$(BUILD_ID)_$(TYPE)
CORE_DIR  = $(RELEASE_IMAGES_DIR)/$(PRODUCT_NAME)/$(TYPE)/core/$(CORE_NAME)

UDA_NAME = $(PRODUCT_TYPE)_$(BUILD_ID)_$(TYPE)
UDA_DIR  = $(RELEASE_IMAGES_DIR)/$(PRODUCT_NAME)/$(TYPE)/uda

# setting customer templates
ROFS3_NAME = $(PRODUCT_TYPE)_$(BUILD_ID)_${CUSTVARIANT_NAME}_$(TYPE)
ROFS3_DIR  = $(RELEASE_IMAGES_DIR)/$(PRODUCT_NAME)/$(TYPE)/customer/$(CUSTVARIANT_NAME)

# setting version string templates
#CORE_VERSION=V$(COREPLAT_VERSION).$(S60_VERSION).$(BUILD_YEAR)_wk$(BUILD_WEEK)
CORE_SHORTVERSION=$(MAJOR_VERSION)$(MINOR_VERSION).$(BUILD_NUMBER)$(TYPE_SWINFO)$(CUSTOMIZE_VERSION)
CORE_VERSION=v$(BUILD_ID)$(TYPE_SWINFO)$(CUSTOMIZE_VERSION)

LANGPACK_SHORTVERSION=$(MAJOR_VERSION)$(MINOR_VERSION).$(BUILD_NUMBER).$(LANGPACK_ID)$(TYPE_SWINFO)$(CUSTOMIZE_VERSION)
LANGPACK_VERSION=v$(BUILD_ID).$(LANGPACK_ID)$(TYPE_SWINFO)$(CUSTOMIZE_VERSION)

ROFS3_SHORTVERSION=$(MAJOR_VERSION)$(MINOR_VERSION).$(BUILD_NUMBER).$(CUSTVARIANT_NAME)$(TYPE_SWINFO)$(CUSTOMIZE_VERSION)$(FOTA_A_BUILD)
ROFS3_VERSION=v$(BUILD_ID)$(TYPE_SWINFO)$(CUSTOMIZE_VERSION)

CORE_SWVERINFO = $(CORE_VERSION)\\\n$(DAY)-$(MONTH)-$(YEAR2)\\\n(c) Nokia
LANGPACK_SWVERINFO = $(LANGPACK_VERSION)\\\n$(DAY)-$(MONTH)-$(YEAR2)\\\n(c) Nokia
ROFS3_CUSTINFO = $(ROFS3_VERSION)\\\n$(DAY)-$(MONTH)-$(YEAR2)\\\n(c) Nokia

# fix the fpsx image location too.
CORE_FLASH       = $(CORE_DIR)/$(CORE_NAME)$(call iif,$(USE_ROFS2)$(USE_ROFS3),.core)$(FLASH_EXT)
ROFS2_FLASH      = $(ROFS2_DIR)/$(ROFS2_NAME).rofs2$(FLASH_EXT)
ROFS3_FLASH      = $(ROFS3_DIR)/$(ROFS3_NAME).rofs3$(FLASH_EXT)

# declaring missing target declaration foti/fota...
$(call add_help,foti,t,Create FOTI sw updater)
$(call add_help,fota,t,Create FOTA sw updater)

IMAKER_VARXML  = $(RELEASE_IMAGES_DIR)/$(PRODUCT_TYPE)_$(BUILD_ID)_core$(LANGPACK_NAME)$(CUSTVARIANT_NAME)${TYPE}.iconfig.xml
IMAKER_VARLIST=CORE_NAME ROFS2_NAME ROFS3_NAME LANGPACK_ID CUSTVARIANT_ID PRODUCT_NAME PRODUCT_TYPE TYPE CORE_VERSION LANGPACK_VERSION ROFS3_VERSION CORE_DIR ROFS2_DIR ROFS3_DIR

USE_FOTAXML=1

FOTA_CONFXML = $(ROFS3_DIR)/$(ROFS3_NAME)_$(LANGPACK_ID)$(if $(CUSTVARIANT_ID),_$(CUSTVARIANT_ID)).config.xml

define FOTA_XMLINFO
  <?xml version="1.0"?>
  <flash_config>
  \    <image_set>
  \        <product>$(PRODUCT_NAME)</product>
  \        <type_designator>$(PRODUCT_TYPE)</type_designator>
  \        <image_type>$(TYPE)</image_type>
  \        <sw_version>$(CORE_VERSION)</sw_version>
  \        <image type="core" name="$(CORE_FLASH)"/>
  $(if $(LANGPACK_ID),
  \        <image type="language" name="$(ROFS2_FLASH)" id="$(LANGPACK_ID)"/>)
  $(if $(CUSTVARIANT_ID),
  \        <image type="customer" name="$(ROFS3_FLASH)" id="$(CUSTVARIANT_ID)"/>)
  \        <fwid>$(PRODUCT_TYPE)_$(CORE_SHORTVERSION) $(LANGPACK_SHORTVERSION) $(ROFS3_SHORTVERSION)</fwid>
  $(if $(CUSTVARIANT_DESC),
  \        <description>$(CUSTVARIANT_DESC)</description>)
  \        <date>$(DAY)-$(MONTH)-$(YEAR2)</date>
  \    </image_set>
  </flash_config>
endef
