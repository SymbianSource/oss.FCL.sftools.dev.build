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
# Description: iMaker external tools configuration
#



###############################################################################
# External tools

BLDROM_TOOL     = buildrom
ROMBLD_TOOL     = rombuild
ROFSBLD_TOOL    = rofsbuild
MAKSYM_TOOL     = maksym
MAKSYMROFS_TOOL = maksymrofs
IMGCHK_TOOL     = imgcheck
INTPRSIS_TOOL   = interpretsis
READIMG_TOOL    = readimage

UNZIP_TOOL      = unzip
ZIP_TOOL        = zip
7ZIP_TOOL       = 7za
FILEDISK_TOOL   = filedisk
WINIMAGE_TOOL   = "c:/program files/winimage/winimage.exe"

#==============================================================================

BLDROM_OPT =\
  -loglevel1 $(call iif,$(KEEPTEMP),-p) -v -nosymbols\
  $(call iif,$(USE_FEATVAR),-DFEATUREVARIANT=$(FEATURE_VARIANT))\
  $(if $(IMAGE_TYPE),-D_IMAGE_TYPE_$(IMAGE_TYPE)) $(if $(TYPE),-D_IMAGE_TYPE_$(call ucase,$(TYPE)))

BLDROM_PARSE =\
  parse | \nMissing file(s):\n | Missing file: |\
  parse | \nWarning(s):\n      | /WARNING:\|WARN:/i |\
  parse | \nError(s):\n        | /ERROR:\|ERR :/i   |\
  parse | \nCan$'t locate:\n | Can$'t locate | parse | \ncouldn$'t be located:\n | couldn$'t be located

#* Writing tmp7.oby - result of problem-suppression phase
#Can't open \epoc32\release\ARMV5\urel\apgrfx.dll.map
#Unrecognised option -NO-HEADER0

# For passing extra paramters (from command line)
BLDROPT =
BLDROBY =


###############################################################################
# S60 Configuration Tool CLI

CONFT_TOOL    = cli.cmd
CONFT_TOOLDIR = $(or $(wildcard /s60/tools/toolsextensions/ConfigurationTool),/ext/tools/toolsextensions/ConfigurationTool)

CONFT_DIR     = $(WORKDIR)/ct
CONFT_TMPDIR  = $(CONFT_DIR)/_temp
CONFT_CFGNAME = variant
CONFT_CONFML  = $(call iif,$(USE_VARIANTBLD),$(VARIANT_CONFML),$(WORKDIR)/$(CONFT_CFGNAME).confml)
CONFT_IMPL    = $(CONFIGROOT)/confml_data/s60;$(CONFIGROOT)/confml_data/customsw
CONFT_IBYML   = $(CONFT_TOOLDIR)/ibyml
CONFT_OUTDIR  = $(call iif,$(USE_VARIANTBLD),$(VARIANT_OUTDIR),$(CONFT_DIR)/cenrep)
CONFT_CRLOG   = $(call iif,$(USE_VARIANTBLD),$(VARIANT_PREFIX)_,$(CONFT_DIR))cenrep.log
CONFT_ECLCONF = -configuration $(CONFT_TMPDIR) -data $(CONFT_TMPDIR)
CONFT_CONF    = $(CONFT_ECLCONF)\
  -master $(CONFT_CONFML) -impl $(CONFT_IMPL) $(if $(CONFT_IBYML),-ibyml $(CONFT_IBYML)) -output $(CONFT_DIR)\
  -report $(CONFT_CRLOG) -ignore_errors
CONFT_CONFCP  = $(call iif,$(USE_VARIANTBLD),$(VARIANT_CONFCP),$(CONFT_CFGNAME))

CONFT_CMD     = $(CONFT_TOOL) $(CONFT_CONF)
CONFT_PARSE   = parse | \nWarnings, errors and problems:\n | /warning:\|error:\|problem/i

CLEAN_CENREP =\
  del    | $(CONFT_CRLOG) |\
  deldir | "$(CONFT_DIR)" "$(CONFT_TMPDIR)" $(call iif,$(USE_VARIANTBLD),,"$(CONFT_OUTDIR)")

BUILD_CENREP =\
  echo-q | Calling S60 Configuration Tool |\
  mkcd   | $(CONFT_DIR) |\
  deldir | $(CONFT_TMPDIR) |\
  cmd    | $(CONFT_CMD) | $(CONFT_PARSE) |\
  $(foreach dir,$(CONFT_CONFCP),\
    finddir | $(CONFT_DIR)/$(dir) | * | |\
    copy    | __find__ | $(CONFT_OUTDIR) |)\
  $(call iif,$(KEEPTEMP),,deldir | $(CONFT_TMPDIR))


###############################################################################
# Interpretsis

SISINST_DIR    = $(WORKDIR)/sisinst
SISINST_SISDIR = $(call iif,$(USE_VARIANTBLD),$(VARIANT_SISDIR))
SISINST_OUTDIR = $(call iif,$(USE_VARIANTBLD),$(VARIANT_OUTDIR),$(SISINST_DIR)/output)
#SISINST_ZDIR   = $(SISINST_DIR)/z_drive
SISINST_ZDIR   = $(EPOC32)/data/Z

SISINST_HALINI = $(wildcard $(PRODUCT_DIR)/interpretsis.ini)
SISINST_CONF   = -w info -z $(SISINST_ZDIR) $(if $(SISINST_HALINI),-i $(SISINST_HALINI)) -c $(SISINST_OUTDIR) -s $(SISINST_SISDIR)
SISINST_CMD    = $(INTPRSIS_TOOL) $(SISINST_CONF)
SISINST_PARSE  =\
  parse | \nWarning(s):\n | /^WARN:/ |\
  parse | \nError(s):\n   | /^ERR :/

#CLEAN_SISINSTPRE = deldir | $(SISINST_ZDIR)
#BUILD_SISINSTPRE =\
#  mkdir | $(SISINST_ZDIR) |\
#  $(foreach img,$(ROM_IMG) $(foreach rofs,1 2 3 4 5 6,$(call iif,$(USE_ROFS$(rofs)),$(ROFS$(rofs)_IMG))),\
#    cmd | $(READIMG_TOOL) -z $(SISINST_ZDIR) $(img) |)

CLEAN_SISINST = deldir | "$(SISINST_DIR)" $(call iif,$(USE_VARIANTBLD),,"$(SISINST_OUTDIR)")
BUILD_SISINST =\
  echo-q | Installing SIS |\
  mkdir  | $(SISINST_OUTDIR) |\
  cmd    | $(SISINST_CMD) | $(SISINST_PARSE)


###############################################################################
# Operator Cache Tool

OPC_TOOL     = $(ITOOL_DIR)/opcache_tool.py
OPC_CONF     = -u $(OPC_URL) -e $(OPC_EXPDATE) -m $(OPC_MMAPFILE) -i $(OPC_RAWDIR) -o $(OPC_OUTDIR)/$(OPC_CACHEDIR)
OPC_CMD      = $(PYTHON) $(OPC_TOOL) $(OPC_CONF)
OPC_DIR      = $(WORKDIR)/opcache
OPC_RAWDIR   = $(call iif,$(USE_VARIANTBLD),$(VARIANT_OPCDIR))
OPC_OUTDIR   = $(call iif,$(USE_VARIANTBLD),$(VARIANT_OUTDIR),$(OPC_DIR)/output)
OPC_CACHEDIR = cache
OPC_MMAPFILE = $(OPC_DIR)/mimemap.dat

OPC_URL      = http://www.someoperator.com/Cache_OpCache
OPC_EXPDATE  = 3

define OPC_MIMEMAP
  .bmp:   image/bmp
  .css:   text/css
  .gif:   image/gif
  .htm:   text/html
  .html:  text/html
  .ico:   image/x-icon
  .jpeg:  image/jpeg
  .jpg:   image/jpeg
  .js:    text/javascript
  .mid:   audio/mid
  .midi:  audio/midi
  .png:   image/png
  .tif:   image/tiff
  .tiff:  image/tiff
  .wbmp:  image/vnd.wap.wbmp
  .wml:   text/vnd.wap.wml
  .wmlc:  application/vnd.wap.wmlc
  .xhtml: application/xhtml+xml
endef

CLEAN_OPCACHE = del | $(OPC_MMAPFILE) | deldir | "$(OPC_DIR)" $(call iif,$(USE_VARIANTBLD),,"$(OPC_OUTDIR)")
BUILD_OPCACHE =\
  echo-q | Creating Operator Cache content |\
  write  | $(OPC_MMAPFILE) |\
    $(call def2str,\# Generated `$(OPC_MMAPFILE)$' for Operator Cache content creation$(\n)$(\n)$(OPC_MIMEMAP)) |\
  test   | $(OPC_RAWDIR)/* |\
  mkdir  | $(OPC_OUTDIR)/$(OPC_CACHEDIR) |\
  cmd    | $(OPC_CMD)


###############################################################################
# Widget Pre-installation

WIDGET_WGZIP   = $(WORKDIR)/*.wgz
WIDGET_WGZDIR  = $(EPOC32)/release/winscw/udeb/z/data/WidgetBURTemp
WIDGET_WGZIBY  = $(E32ROMINC)/widgetbackupfiles.iby
WIDGET_WGZPXML = Info.plist

CLEAN_WGZPREINST = del | $(WIDGET_WGZIBY) | deldir | $(WIDGET_WGZDIR)
BUILD_WGZPREINST =\
  echo-q   | Widget Pre-installation |\
  echo-q   | Unzip $(WIDGET_WGZIP) file(s) to $(WIDGET_WGZDIR), generating $(WIDGET_WGZIBY) |\
  wgunzip  | $(WIDGET_WGZIP) | $(WIDGET_WGZDIR) | $(WIDGET_WGZPXML) |\
  geniby-r | $(WIDGET_WGZIBY) | $(WIDGET_WGZDIR) | * | data="%1" "data/WidgetBURTemp/%2" | end


###############################################################################
# Image Checker

IMGCHK_LOG = $($(IMAGE_TYPE)_ICHKLOG)
IMGCHK_OPT = --verbose --dep
IMGCHK_CMD = $(IMGCHK_TOOL) $($(IMAGE_TYPE)_ICHKOPT) $($(IMAGE_TYPE)_ICHKIMG)

define IMGCHK_HDRINFO
  # Image Check log for $($(IMAGE_TYPE)_TITLE) SOS image
  #
  # Filename: $(IMGCHK_LOG)
  # Command : $(IMGCHK_CMD)
endef

CLEAN_IMGCHK = del | "$(basename $(IMGCHK_LOG)).*" "imgcheck.log"
BUILD_IMGCHK =\
  echo-q | Checking $($(IMAGE_TYPE)_TITLE) SOS image file(s) |\
  cd     | $($(IMAGE_TYPE)_DIR) |\
  write  | $(IMGCHK_LOG) | $(call def2str,$(IMGCHK_HDRINFO))\n |\
  cmdtee | $(IMGCHK_CMD) | >>$(IMGCHK_LOG) |\
  del    | imgcheck.log


###############################################################################
# CheckDependency

CHKDEP_TOOL     = CheckDependency.pl
CHKDEP_CONFXML  = $(E32ROMBLD)/iad/iad_rofs_config.xml
CHKDEP_ROFSFILE = $(E32ROMBLD)/IAD_rofsfiles.txt
CHKDEP_OPT      = -i $(CHKDEP_CONFXML) -o $(CHKDEP_ROFSFILE)
CHKDEP_CMD      = $(PERL) -S $(CHKDEP_TOOL) $(CHKDEP_OPT)

CLEAN_CHKDEP = del | $(CHKDEP_ROFSFILE)
BUILD_CHKDEP =\
  echo-q | Running CheckDependency tool |\
  cmd    | $(CHKDEP_CMD)


###############################################################################
# Image to files; extract files from .img using Readimage tool

I2FILE_DIR = $(WORKDIR)/img2file

CLEAN_COREI2F = deldir | $(CORE_I2FDIR)
BUILD_COREI2F = $(call _buildi2file,CORE,$(CORE_I2FDIR),$(ROM_IMG) $(call iif,$(USE_ROFS1),$(ROFS1_IMG)))

CLEAN_VARIANTI2F = $(foreach rofs,2 3 4 5 6,$(call iif,$(USE_ROFS$(rofs)),deldir | $(ROFS$(rofs)_I2FDIR) |))
BUILD_VARIANTI2F =\
  $(foreach rofs,2 3 4 5 6,$(call iif,$(USE_ROFS$(rofs)),\
    $(call _buildi2file,ROFS$(rofs),$(ROFS$(rofs)_I2FDIR),$(ROFS$(rofs)_IMG))))

CLEAN_I2FILE = deldir | $(I2FILE_DIR) | $(CLEAN_COREI2F) | $(CLEAN_VARIANTI2F)
BUILD_I2FILE =\
  $(BUILD_COREI2F) | $(BUILD_VARIANTI2F) |\
  copy | $(CORE_I2FDIR)/* | $(I2FILE_DIR) |\
  $(foreach rofs,2 3 4 5 6,$(call iif,$(USE_ROFS$(rofs)),copy | $(ROFS$(rofs)_I2FDIR)/* | $(I2FILE_DIR) |))

_buildi2file =\
  echo-q | Extracting files from $($1_TITLE) SOS image to $2 |\
  mkcd   | $2 |\
  $(foreach img,$3,\
    cmd | $(READIMG_TOOL) -s $(img)   |\
    cmd | $(READIMG_TOOL) -z . $(img) |)


###############################################################################
# Tool info

define TOOL_INFO
  $(MAKE)          | $(MAKE) -v   | GNU Make (\S+).+(built for \S+) |
  $(PERL)          | $(PERL) -v   | perl, v(.+?)$$ |
  $(CPP)           | $(CPP) -v -h | CPP version (.+?)$$ |
  $(call _grepversion,$(E32TOOLS)/imaker.cmd) |
  $(call _grepversion,$(IMAKER_TOOL)) |
  $(call _grepversion,$(IMAKER_DIR)/imaker.pm) |
  $(if $(wildcard $(IMAKER_DIR)/imaker_extension.pm),$(call _grepversion,$(IMAKER_DIR)/imaker_extension.pm) |)
  $(call _grepversion,$(IMAKER_DIR)/imaker.mk) |
  $(call _grepversion,$(IMAKER_DIR)/imaker_public.mk) |
  $(if $(wildcard $(IMAKER_DIR)/imaker_extension.mk),$(call _grepversion,$(IMAKER_DIR)/imaker_extension.mk) |)
  $(ROMBLD_TOOL)   | $(ROMBLD_TOOL)         | ROMBUILD.+? V(.+?)\s*$$  |
  $(ROFSBLD_TOOL)  | $(ROFSBLD_TOOL)        | ROFSBUILD.+? V(.+?)\s*$$ |
  $(IMGCHK_TOOL)   | $(IMGCHK_TOOL) -h      | IMGCHECK.+? V(.+?)\s*$$  |
  $(INTPRSIS_TOOL) | $(INTPRSIS_TOOL) -h    | INTERPRETSIS\s+Version\s+(.+?)\s*$$ |
  $(READIMG_TOOL)  | $(READIMG_TOOL)        | Readimage.+? V(.+?)\s*$$ |
  $(CONFT_TOOL)    | $(CONFT_TOOL) -version | ^.+?\n(.+?)\n(.+?)\n
endef

BUILD_TOOLINFO = echo-q | | toolchk | $(strip $(TOOL_INFO)) | end

#==============================================================================

_grepversion = $1 | $(PERL) -ne "print, exit if /%version:\s*\S+\s*%/" < $1 | %version:\s*(\S+)\s*%


###############################################################################
# Targets

.PHONY: checkdep opcache sisinst toolinfo wgzpreinst

chkdep opcache sisinst toolinfo wgzpreinst:\
  ;@$(call IMAKER,$(call ucase,$@))


# END OF IMAKER_TOOLS.MK
