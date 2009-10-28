USE_NAMEMK = 1
# Example version of image_conf_naming.mk
# If this file exists in the build area, it is read by iMaker and can be
# used for image naming, setting directories and version info generation.

# this variable is intended to be overriden by customer that would need to customize the version string.
CUSTOMIZE_VERSION?=

# setting langpack templates
ROFS2_DIR  = $(RELEASE_IMAGES_DIR)/$(PRODUCT_NAME)/$(TYPE)/langpack/$(LANGPACK_NAME)
ROFS2_NAME = $(PRODUCT_TYPE)_$(MAJOR_VERSION)$(MINOR_VERSION).$(LANGPACK_ID)_$(TYPE)

# setting core templates
CORE_NAME = $(PRODUCT_TYPE)_$(MAJOR_VERSION)$(MINOR_VERSION)_$(TYPE)
CORE_DIR  = $(RELEASE_IMAGES_DIR)/$(PRODUCT_NAME)/$(TYPE)/core/$(CORE_NAME)

# setting customer templates
ROFS3_NAME = $(PRODUCT_TYPE)_$(MAJOR_VERSION)$(MINOR_VERSION)_$(TYPE)
ROFS3_DIR  = $(RELEASE_IMAGES_DIR)/$(PRODUCT_NAME)/$(TYPE)/customer/$(CUSTVARIANT_NAME)

# setting version string templates
#CORE_VERSION=V $(COREPLAT_VERSION).$(S60_VERSION).$(BUILD_YEAR)_wk$(BUILD_WEEK)
CORE_VERSION=v $(BUILD_ID)
CORE_SWVERINFO = $(CORE_VERSION).$(LANGPACK_ID)$(TYPE_SWINFO)$(CUSTOMIZE_VERSION)\\\n$(DAY)-$(MONTH)-$(YEAR2)\\\n(c) Nokia
LANGPACK_SWVERINFO = $(CORE_VERSION).$(LANGPACK_ID)$(TYPE_SWINFO)$(CUSTOMIZE_VERSION)\\\n$(DAY)-$(MONTH)-$(YEAR2)\\\n(c) Nokia
ROFS3_CUSTINFO = $(CORE_VERSION).$(LANGPACK_ID)$(TYPE_SWINFO)$(CUSTOMIZE_VERSION)\\\n$(DAY)-$(MONTH)-$(YEAR2)\\\n(c) Nokia

# fix the fpsx image location too.
CORE_FLASH       = $(CORE_DIR)/$(CORE_NAME)$(call iif,$(USE_ROFS2)$(USE_ROFS3),.core)$(FLASH_EXT)
ROFS2_FLASH      = $(ROFS2_DIR)/$(ROFS2_NAME).rofs2$(FLASH_EXT)
ROFS3_FLASH      = $(ROFS3_DIR)/$(ROFS3_NAME).rofs3$(FLASH_EXT)

# declaring missing target declaration foti/fota...
$(call add_help,foti,t,Create FOTI sw updater)
$(call add_help,fota,t,Create FOTA sw updater)

