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
# Description: iMaker external tools configuration
#



###############################################################################
# External tools

BLDROM_TOOL     = $(PERL) -S buildrom.pl
FEATMAN_TOOL    = $(PERL) -S features.pl
ROMBLD_TOOL     = rombuild
ROFSBLD_TOOL    = rofsbuild
MAKSYM_TOOL     = $(PERL) -S maksym.pl
MAKSYMROFS_TOOL = $(PERL) -S maksymrofs.pl
ELF2E32_TOOL    = elf2e32
IMGCHK_TOOL     = imgcheck
INTPRSIS_TOOL   = interpretsis
READIMG_TOOL    = readimage

ZIP_TOOL        = zip
7ZIP_TOOL       = 7za
UNZIP_TOOL      = $(7ZIP_TOOL)

BUILD_TOOLSET =\
  tool-cpp          | $(CPP)           |\
  tool-elf2e32      | $(ELF2E32_TOOL)  |\
  tool-interpretsis | $(INTPRSIS_TOOL) |\
  tool-opcache      | $(OPC_TOOL)      |\
  tool-unzip        | $(UNZIP_TOOL)

#==============================================================================

BLDROM_JOBS =

BLDROM_OPT =\
  -loglevel1 $(call iif,$(KEEPTEMP),-p) -v $(call iif,$(USE_SYMGEN),,-nosymbols) $(addprefix -j,$(BLDROM_JOBS))\
  $(call iif,$(USE_BLRWORKDIR),-workdir="$($(IMAGE_TYPE)_DIR)")\
  $(call iif,$(USE_FEATVAR),-DFEATUREVARIANT=$(FEATURE_VARIANT))\
  $(call iif,$(SYMBIAN_FEATURE_MANAGER),\
    $(if $($(IMAGE_TYPE)_FEAXML),-fm=$(subst $( ),$(,),$(strip $($(IMAGE_TYPE)_FEAXML)))) -D__FEATURE_IBY__)\
  $(if $(IMAGE_TYPE),-D_IMAGE_TYPE_$(IMAGE_TYPE)) $(if $(TYPE),-D_IMAGE_TYPE_$(call ucase,$(TYPE)))

BLDROM_PARSE =\
  parse   | Missing files:   | /Missing file:/i ||\
  parse   | Errors:          | /ERROR:\|ERR :/i ||\
  parse-4 | Erroneous links: | /WARNING: Kernel\/variant\/extension/i ||\
  parse   | Warnings:        | /WARNING:\|WARN:/i |\
    /WARNING: the value of attribute .+ has been overridden\|WARNING: Kernel\/variant\/extension\|Warning: Can't open .+\.map/i

#  parse   | Can't locate:    | /Can't locate\|couldn't be located/i |
#Unrecognised option -NO-HEADER0

# For passing extra parameters (from command line)
BLDROPT =
BLDROBY =

#==============================================================================

DEFHRH_IDIR = . $($(IMAGE_TYPE)_IDIR) $(FEATVAR_IDIR)
DEFHRH_CMD  = $(CPP) -nostdinc -undef -dM -D_IMAGE_INCLUDE_HEADER_ONLY\
  $(call dir2inc,$(DEFHRH_IDIR)) -include $(call upddrive,$(FEATVAR_HRH)) $(call updoutdrive,$($(IMAGE_TYPE)_MSTOBY)) \|\
  $(PERL) -we $(call iif,$(USE_UNIX),',")print(sort({lc($$a) cmp lc($$b)} <STDIN>))$(call iif,$(USE_UNIX),',")\
    >>$($(IMAGE_TYPE)_DEFHRH)

define DEFHRH_HDRINFO
  // Generated file for documenting feature variant definitions
  //
  // Filename: $($(IMAGE_TYPE)_DEFHRH)
  // Command : $(DEFHRH_CMD)
endef

CLEAN_DEFHRH = del | "$($(IMAGE_TYPE)_DEFHRH)"
BUILD_DEFHRH =\
  $(if $($(IMAGE_TYPE)_DEFHRH),\
    write | "$($(IMAGE_TYPE)_DEFHRH)" | $(call def2str,$(DEFHRH_HDRINFO))\n\n |\
    cmd   | $(DEFHRH_CMD))

#==============================================================================

FEATMAN_OPT = $($(IMAGE_TYPE)_FEAXML) --ibyfile=$($(IMAGE_TYPE)_DIR) --verbose
FEATMAN_CMD = $(FEATMAN_TOOL) $(FEATMAN_OPT)

CLEAN_FEATMAN = del | $(foreach file,$($(IMAGE_TYPE)_FEAIBY),"$(file)")
BUILD_FEATMAN =\
  $(call iif,$(SYMBIAN_FEATURE_MANAGER),$(if $($(IMAGE_TYPE)_FEAXML),\
    echo-q | Generating Feature manager file(s) |\
    write  | $($(IMAGE_TYPE)_FEAIBY) | |\
    cmd    | $(FEATMAN_CMD)))

#==============================================================================
# ROFS symbol generation

MAKSYMROFS_CMD = $(MAKSYMROFS_TOOL) $(call pathconv,"$($(IMAGE_TYPE)_LOG)" "$($(IMAGE_TYPE)_SYM)")

CLEAN_MAKSYMROFS = del | "$($(IMAGE_TYPE)_SYM)"
BUILD_MAKSYMROFS =\
  echo-q | Creating $($(IMAGE_TYPE)_TITLE) symbol file |\
  cmd    | $(MAKSYMROFS_CMD)

REPORT_MAKSYMROFS = $($(IMAGE_TYPE)_TITLE) symbols | $($(IMAGE_TYPE)_SYM) | f


###############################################################################
# ConE

USE_CONE = 0

CONE_TOOL    = $(call iif,$(USE_UNIX),,call )cone
CONE_TOOLDIR = $(or $(wildcard $(E32TOOLS)/configurationengine),$(E32TOOLS)/cone)
CONE_OUTDIR  = $(OUTTMPDIR)/cone
CONE_PRJ     = $(CONFIGROOT)
CONE_CONF    = $($(IMAGE_TYPE)_CONECONF)
CONE_RNDCONF = $(COREPLAT_NAME)/$(PRODUCT_NAME)/rnd/root.confml
CONE_ADDCONF = $(call select,$(TYPE),rnd,$(if $(wildcard $(CONE_PRJ)/$(CONE_RNDCONF)),$(CONE_RNDCONF)))
CONE_LOG     = $($(or $(addsuffix _,$(IMAGE_TYPE)),WORK)PREFIX)_cone_$(call substm,* / : ? \,@,$(TARGET)).log
CONE_VERBOSE = $(if $(filter debug 127,$(VERBOSE)),5)
CONE_GOPT    = generate --project="$(CONE_PRJ)"\
  $(if $(CONE_CONF),--configuration="$(CONE_CONF)") $(addprefix --add=,$(CONE_ADDCONF))\
  $(if $(CONE_LOG),--log-file="$(CONE_LOG)") $(addprefix --verbose=,$(CONE_VERBOSE))
CONE_PARSE   = parse-2 | ConE errors: | /ERROR\s*:/i |

#==============================================================================

CONE_MK    = $(if $(CONE_PRJ),$(CONE_PRJ).mk)
CONE_MKOPT = $(CONE_GOPT) --impl=imaker.* --all-layers --set=imaker.makefilename="$(CONE_MK)" --output=.
CONE_MKCMD = $(CONE_TOOL) $(CONE_MKOPT)

CLEAN_CONEPRE = del | "$(CONE_MK)" "$(CONE_LOG)"
BUILD_CONEPRE =\
  echo-q | Creating ConE makefile `$(CONE_MK)' |\
  cmd    | $(CONE_MKCMD) | $(CONE_PARSE) |\
  test   | "$(CONE_MK)"

#==============================================================================

CONE_IMPLS       =
CONE_IMPLOPT     = $(addprefix --impl=,$(subst $(,), ,$(CONE_IMPLS)))
CONE_LAYERS      =
CONE_LAYEROPT    = $(addprefix --layer=,$(subst $(,), ,$(CONE_LAYERS)))
CONE_REPFILE     = $(basename $(CONE_LOG)).html
CONE_REPDATADIR  = $(OUTDIR)/cone-repdata
CONE_REPDATAFILE = $(CONE_REPDATADIR)/$(IMAGE_TYPE).dat
CONE_RTMPLFILE   =

CONE_GENOPT = $(CONE_GOPT)\
  $(CONE_IMPLOPT) $(CONE_LAYEROPT) --add-setting-file=imaker_variantdir.cfg\
  $(if $(CONE_REPFILE),$(call select,$(USE_CONE),mk,--report-data-output="$(CONE_REPDATAFILE)",--report="$(CONE_REPFILE)"))\
  $($(IMAGE_TYPE)_CONEOPT) --output="$(CONE_OUTDIR)"
CONE_GENCMD = $(CONE_TOOL) $(CONE_GENOPT)

CLEAN_CONEGEN = del | "$(CONE_LOG)" "$(CONE_REPFILE)" | deldir | "$(CONE_OUTDIR)"
BUILD_CONEGEN =\
  echo-q | Generating $($(IMAGE_TYPE)_TITLE) content with ConE |\
  mkdir  | "$(CONE_OUTDIR)" |\
  cmd    | $(CONE_GENCMD)   | $(CONE_PARSE)

REPORT_CONEGEN =\
  ConE log | $(CONE_LOG) | f\
  $(if $(CONE_REPFILE),| ConE report | $(CONE_REPFILE) | f)

#==============================================================================

CLEAN_CONEREPPRE = deldir | "$(CONE_REPDATADIR)"
BUILD_CONEREPPRE =

CONE_REPGENOPT =\
  report --input-data-dir="$(CONE_REPDATADIR)"\
  $(if $(CONE_RTMPLFILE),--template="$(CONE_RTMPLFILE)")\
  --report="$(CONE_REPFILE)" --log-file="$(CONE_LOG)" $(addprefix --verbose=,$(CONE_VERBOSE))
CONE_REPGENCMD = $(CONE_TOOL) $(CONE_REPGENOPT)

CLEAN_CONEREPGEN = del | "$(CONE_REPFILE)"
BUILD_CONEREPGEN = $(if $(CONE_REPFILE),\
  echo-q | Generating report with ConE to `$(CONE_REPFILE)' |\
  cmd    | $(CONE_REPGENCMD))

REPORT_CONEREPGEN = $(if $(CONE_REPFILE),ConE report | $(CONE_REPFILE) | f)

#==============================================================================

CONE_XCF = $(ICDP_XCF)

CONE_XCFOPT = $(CONE_GOPT) --impl=xcf.gcfml --all-layers --output="$(dir $(CONE_XCF))"
CONE_XCFCMD = $(CONE_TOOL) $(CONE_XCFOPT)

CLEAN_CONEXCF = del | "$(CONE_XCF)" "$(CONE_LOG)"
BUILD_CONEXCF =\
  echo-q | Creating XCF file `$(CONE_XCF)' |\
  cmd    | $(CONE_XCFCMD) | $(CONE_PARSE)  |\
  test   | "$(CONE_XCF)"

#==============================================================================

.PHONY: cone-pre cone-gen cone-rep-pre cone-rep-gen

cone-pre: ;@$(call IMAKER,CONEPRE)
cone-gen: ;@$(call IMAKER,CONEGEN)
cone-rep-pre: ;@$(call IMAKER,CONEREPPRE)
cone-rep-gen: ;@$(call IMAKER,CONEREPGEN)


###############################################################################
# SIS pre-installation

SISINST_INI    = $(wildcard $(VARIANT_DIR)/sis_config.ini)
SISINST_DIR    = $(VARIANT_SISDIR)
SISINST_OUTDIR = $(VARIANT_OUTDIR)
SISINST_CFGINI = $(IMAGE_PREFIX)_sis.ini
SISINST_LOG    = $(IMAGE_PREFIX)_sis.log
SISINST_CONF   = -d $(if $(filter Z z,$(or $($(IMAGE_TYPE)_DRIVE),Z)),C,$($(IMAGE_TYPE)_DRIVE)) -e -k 5.4 -s "$(SISINST_DIR)"
SISINST_HALHDA =

# sf/os/kernelhwsrv/halservices/hal/inc/hal_data.h:
define SISINST_HALINFO
  EManufacturer_Ericsson          0x00000000
  EManufacturer_Motorola          0x00000001
  EManufacturer_Nokia             0x00000002
  EManufacturer_Panasonic         0x00000003
  EManufacturer_Psion             0x00000004
  EManufacturer_Intel             0x00000005
  EManufacturer_Cogent            0x00000006
  EManufacturer_Cirrus            0x00000007
  EManufacturer_Linkup            0x00000008
  EManufacturer_TexasInstruments  0x00000009

  EDeviceFamily_Crystal         0
  EDeviceFamily_Pearl           1
  EDeviceFamily_Quartz          2

  ECPU_ARM                      0
  ECPU_MCORE                    1
  ECPU_X86                      2

  ECPUABI_ARM4                  0
  ECPUABI_ARMI                  1
  ECPUABI_THUMB                 2
  ECPUABI_MCORE                 3
  ECPUABI_MSVC                  4
  ECPUABI_ARM5T                 5
  ECPUABI_X86                   6

  ESystemStartupReason_Cold     0
  ESystemStartupReason_Warm     1
  ESystemStartupReason_Fault    2

  EKeyboard_Keypad              0x1
  EKeyboard_Full                0x2

  EMouseState_Invisible         0
  EMouseState_Visible           1

  EMachineUid_Series5mx         0x1000118a
  EMachineUid_Brutus            0x10005f60
  EMachineUid_Cogent            0x10005f61
  EMachineUid_Win32Emulator     0x10005f62
  EMachineUid_WinC              0x10005f63
  EMachineUid_CL7211_Eval       0x1000604f
  EMachineUid_LinkUp            0x00000000
  EMachineUid_Assabet           0x100093f3
  EMachineUid_Zylonite          0x101f7f27
  EMachineUid_IQ80310           0x1000a681
  EMachineUid_Lubbock           0x101f7f26
  EMachineUid_Integrator        0x1000AAEA
  EMachineUid_Helen             0x101F3EE3
  EMachineUid_X86PC             0x100000ad
  EMachineUid_OmapH2            0x1020601C
  EMachineUid_OmapH4            0x102734E3
  EMachineUid_NE1_TB            0x102864F7
  EMachineUid_EmuBoard          0x1200afed
  EMachineUid_OmapH6            0x10286564
  EMachineUid_OmapZoom          0x10286565
  EMachineUid_STE8500           0x101FF810

  EPowerBatteryStatus_Zero      0
  EPowerBatteryStatus_Replace   1
  EPowerBatteryStatus_Low       2
  EPowerBatteryStatus_Good      3

  EPowerBackupStatus_Zero       0
  EPowerBackupStatus_Replace    1
  EPowerBackupStatus_Low        2
  EPowerBackupStatus_Good       3
endef

define SISINST_CFGINFO
  $(foreach lang,$(LANGPACK_LANGIDS),
    DEVICE_SUPPORTED_LANGUAGE = $(lang))
endef

CLEAN_SISINST = del | "$(SISINST_CFGINI)" "$(SISINST_LOG)"
BUILD_SISINST =\
  echo-q  | Installing SIS file(s) |\
  sisinst | $(SISINST_INI) | $(SISINST_CFGINI) | $(SISINST_CONF)  |\
    $(SISINST_HALHDA) | $(strip $(call def2str,$(SISINST_HALINFO) | $(SISINST_CFGINFO))) |\
    $(SISINST_OUTDIR) | $(SISINST_LOG)


###############################################################################
# Operator Cache Tool

OPC_TOOL     = $(PYTHON) $(ITOOL_DIR)/opcache_tool.py
OPC_INI      = $(wildcard $(VARIANT_DIR)/opcache_config.ini)
OPC_DIR      = $(VARIANT_OPCDIR)
OPC_OUTDIR   = $(VARIANT_OUTDIR)/$(OPC_CACHEDIR)
OPC_TMPDIR   = $(OUTTMPDIR)/opcache
OPC_CACHEDIR = system/cache/op
OPC_URL      = http://www.someoperator.com/Cache_OpCache
OPC_EXPDATE  = 2012-01-01
OPC_MIMEFILE = $(IMAGE_PREFIX)_opcachemime.dat
OPC_CONF     = -u "$(OPC_URL)" -e "$(OPC_EXPDATE)" -m "$(OPC_MIMEFILE)" -i "$(OPC_DIR)" -o "$(OPC_OUTDIR)"

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

CLEAN_OPCACHE = del | "$(OPC_MIMEFILE)"
BUILD_OPCACHE =\
  echo-q  | Creating Operator Cache content |\
  mkdir   | "$(OPC_OUTDIR)"   |\
  write   | "$(OPC_MIMEFILE)" | $(call def2str,$(OPC_MIMEMAP))\n |\
  opcache | $(OPC_INI) | $(OPC_CONF) | $(OPC_TMPDIR)


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

CLEAN_I2FILE = deldir | "$($(IMAGE_TYPE)_I2FDIR)"
BUILD_I2FILE =\
  echo-q | Extracting files from $($(IMAGE_TYPE)_TITLE) SOS image to $($(IMAGE_TYPE)_I2FDIR) |\
  mkcd   | "$($(IMAGE_TYPE)_I2FDIR)" |\
  $(foreach img,$($(IMAGE_TYPE)_IMG),\
    cmd  | $(READIMG_TOOL) -s $(img)   |\
    cmd  | $(READIMG_TOOL) -z . $(img) |)


###############################################################################
# Rofsbuild FAT

ROFSBLD_FATOPT = -datadrive="$($(IMAGE_TYPE)_OUTOBY)" $(addprefix -j,$(BLDROM_JOBS)) $(call iif,$(KEEPGOING),-k) -loglevel2 -slog

CLEAN_ROFSBLDFAT = del | "$($(IMAGE_TYPE)_LOG)"
BUILD_ROFSBLDFAT =\
  cmd  | $(ROFSBLD_TOOL) $(ROFSBLD_FATOPT) |\
  move | "$($(IMAGE_TYPE)_OUTOBY).log" | $($(IMAGE_TYPE)_LOG)


###############################################################################
# Filedisk

FILEDISK_TOOL  = filedisk
FILEDISK_OPT   = /mount 0 $(call peval,GetAbsFname($(call pquote,$($(IMAGE_TYPE)_IMG)),1)) $(call peval,$$iVar[0] = GetFreeDrive())
FILEDISK_SLEEP = 1

CLEAN_FILEDISK = del | "$($(IMAGE_TYPE)EMPTY_IMG)"
BUILD_FILEDISK =\
  $(if $($(IMAGE_TYPE)EMPTY_CMD),\
    cmd   | $($(IMAGE_TYPE)EMPTY_CMD) |\
    move  | "$($(IMAGE_TYPE)EMPTY_IMG)" | $($(IMAGE_TYPE)_IMG) |)\
  cmd     | $(FILEDISK_TOOL) $(FILEDISK_OPT) |\
  copydir | "$($(IMAGE_TYPE)_DATADIR)" | $(call peval,$$iVar[0])/ |\
  cmd     | $(FILEDISK_TOOL) /status $(call peval,$$iVar[0]) |\
  sleep   | $(FILEDISK_SLEEP) |\
  cmd     | $(FILEDISK_TOOL) /umount $(call peval,$$iVar[0])


###############################################################################
# WinImage

WINIMAGE_TOOL = "c:/program files/winimage/winimage.exe"
WINIMAGE_OPT  = $(call pathconv,$($(IMAGE_TYPE)_IMG)) /i $(call pathconv,$($(IMAGE_TYPE)_DATADIR)) /h /q

CLEAN_WINIMAGE = del | "$($(IMAGE_TYPE)EMPTY_IMG)"
BUILD_WINIMAGE =\
  $(if $($(IMAGE_TYPE)EMPTY_CMD),\
    cmd  | $($(IMAGE_TYPE)EMPTY_CMD) |\
    move | "$($(IMAGE_TYPE)EMPTY_IMG)" | $($(IMAGE_TYPE)_IMG) |)\
  cmd | $(WINIMAGE_TOOL) $(WINIMAGE_OPT)


###############################################################################
# Widget Pre-installation

WIDGET_TOOLDIR = $(E32TOOLS)/widget_tools
WIDGET_TOOL    = $(WIDGET_TOOLDIR)/widgetpreinstaller/installwidgets.pl
WIDGET_DIR     = $(VARIANT_WGZDIR)
WIDGET_TMPDIR  = $(OUTTMPDIR)/widget
WIDGET_OUTDIR  = $(VARIANT_OUTDIR)
WIDGET_IDIR    = $(WIDGET_DIR) $(VARIANT_DIR) $(FEATVAR_IDIR)
WIDGET_INI     = $(call findfile,widget_config.ini,$(WIDGET_IDIR),1)
WIDGET_CFGINI  = $(IMAGE_PREFIX)_widget.ini
WIDGET_LANGOPT = $(LANGPACK_DEFLANGID)
WIDGET_OPT     = -verbose $(if $(filter debug 127,$(VERBOSE)),-debug) -epocroot "$(WIDGET_TMPDIR)" $(call iif,$(WIDGET_LANGOPT),-localization $(WIDGET_LANGOPT))
WIDGET_CMD     = $(PERL) $(WIDGET_TOOL) $(WIDGET_OPT) "$(WIDGET_CFGINI)"

define WIDGET_HDRINFO
  # Generated configuration file for Widget pre-installation
  #
  # Filename: $(WIDGET_CFGINI)
  # Command : $(WIDGET_CMD)

  $(if $(WIDGET_INI),,[drive-$(call lcase,$($(IMAGE_TYPE)_DRIVE))])
endef

WIDGET_HSINI     = $(IMAGE_PREFIX)_hsplugin.ini
WIDGET_HSCINI    = $(IMAGE_PREFIX)_hsplugincwrt.ini
WIDGET_HSOPT     = "$(WIDGET_TMPDIR)" "$(WIDGET_HSINI)"
WIDGET_HSCOPT    = "$(WIDGET_TMPDIR)" "$(WIDGET_HSCINI)"
WIDGET_HSCMD     = $(call iif,$(USE_UNIX),,call )$(WIDGET_TOOLDIR)/hspluginpreinstaller/HSPluginPreInstaller $(WIDGET_HSOPT)
WIDGET_HSCCMD    = $(call iif,$(USE_UNIX),,call )$(WIDGET_TOOLDIR)/hspluginpreinstaller/HSPluginPreInstaller $(WIDGET_HSCOPT)

WIDGET_HSVIEWDIR = $(if $(VARIANT_CPDIR),$(wildcard $(subst \,/,$(VARIANT_CPDIR))/private/200159c0/install))
WIDGET_HSWIDEDIR = $(E32DATAZ)/private/200159c0/install/wideimage_2001f489
WIDGET_HSOUTDIR  = $(subst \,/,$(WIDGET_OUTDIR))/private/200159c0/install

define WIDGET_HSINFO
  # Generated configuration file for Home Screen plugin pre-installation for$(if $1, $1) widgets
  #
  # Filename: $(WIDGET_HS$(if $1,C)INI)
  # Command : $(WIDGET_HS$(if $1,C)CMD)

  WIDGET_REGISTRY_PATH=$(subst \,/,$(WIDGET_OUTDIR))/private/10282f06/$1WidgetEntryStore.xml

  VIEW_CONFIGURATION_PATH=$(WIDGET_HSVIEWDIR)

  WIDEIMAGE_PATH=$(WIDGET_HSWIDEDIR)

  OUTPUT_DIR=$(WIDGET_HSOUTDIR)
endef

CLEAN_WIDGET =\
  del    | "$(WIDGET_CFGINI)" "$(WIDGET_HSINI)" "$(WIDGET_HSCINI)" |\
  deldir | "$(WIDGET_TMPDIR)"

BUILD_WIDGET =\
  echo-q  | Installing widget(s) |\
  genwgzcfg | $(WIDGET_CFGINI) | $(WIDGET_INI) | $(WIDGET_DIR) | $(call def2str,$(WIDGET_HDRINFO)) |\
  $(and $(WIDGET_HSINFO),$(WIDGET_HSVIEWDIR),\
    write | "$(WIDGET_HSINI)"  | $(call def2str,$(call WIDGET_HSINFO))\n |\
    write | "$(WIDGET_HSCINI)" | $(call def2str,$(call WIDGET_HSINFO,CWRT))\n |)\
  mkdir   | "$(WIDGET_TMPDIR)" |\
  cmd     | (cd $(call pathconv,$(WIDGET_TMPDIR))) & $(WIDGET_CMD) |\
  copydir | "$(WIDGET_TMPDIR)/epoc32/$(if $(filter CORE ROFS%,$(IMAGE_TYPE)),release/winscw/udeb/z,winscw/?)" |\
    $(WIDGET_OUTDIR) |\
  $(and $(WIDGET_HSINFO),$(WIDGET_HSVIEWDIR),\
    mkdir | "$(WIDGET_HSOUTDIR)" |\
    cmd   | $(WIDGET_HSCMD)  |\
    cmd   | $(WIDGET_HSCCMD) |)\
  $(call iif,$(KEEPTEMP),,deldir | "$(WIDGET_TMPDIR)")


###############################################################################
# Data package 2.0 creation / iCreatorDP

#USE_DPGEN = 0

ICDP_TOOL    = iCreatorDP.py
ICDP_TOOLDIR = $(EPOC_ROOT)/iCreatorDP
ICDP_OPT     = --xcfs="$(ICDP_XCF)" --wa="$(ICDP_WRKDIR)" --ba="$(ICDP_BLDDIR)" --i="$(ICDP_IMGDIR)" --build
ICDP_OUTDIR  = $(EPOC_ROOT)/output
ICDP_XCF     = $(ICDP_OUTDIR)/griffin.xcf
ICDP_WRKDIR  = $(ICDP_OUTDIR)/DP_WA
ICDP_BLDDIR  = $(ICDP_OUTDIR)/DP_OUT
ICDP_IMGDIR  = $(ICDP_OUTDIR)/images
ICDP_VPLDIR  = $(ICDP_OUTDIR)/VPL
ICDP_CMD     = $(PYTHON) $(ICDP_TOOL) $(ICDP_OPT)

ICDP_CUSTIMG = $(ICDP_IMGDIR)/customer.fpsx
ICDP_UDAIMG  = $(ICDP_IMGDIR)/customer_uda.fpsx

#ICDP_IMGLIST = "$(ICDP_IMGDIR)/customer.fpsx" "$(ICDP_IMGDIR)/customer_uda.fpsx"

CLEAN_DPPRE = $(CLEAN_CONEXCF) | del | "$(ICDP_CUSTIMG)"
BUILD_DPPRE =\
  $(BUILD_CONEXCF) |\
  echo-q | Copying images |\
  mkdir  | "$(ICDP_IMGDIR)" |\
  copy   | "$(ROFS3_FLASH)" | $(ICDP_CUSTIMG) |\
#  copy   | $(UDA_FLASH) | $(ICDP_UDAIMG)

CLEAN_DPBLD = deldir | "$(ICDP_BLDDIR)"
BUILD_DPBLD =\
  echo-q | Generating data package |\
  cd     | "$(ICDP_TOOLDIR)" |\
  cmd    | $(ICDP_CMD)

CLEAN_DPPOST = deldir | "$(ICDP_VPLDIR)"
BUILD_DPPOST =\
  find-r | "$(ICDP_BLDDIR)" | *.zip | |\
  unzip  | __find__ | $(ICDP_VPLDIR)

#==============================================================================

.PHONY: datapack datapack-pre

datapack    : ;@$(call IMAKER,$$(call iif,$$(SKIPPRE),,DPPRE) $$(call iif,$$(SKIPBLD),,DPBLD) $$(call iif,$$(SKIPPOST),,DPPOST))
datapack-pre: ;@$(call IMAKER,DPPRE)


###############################################################################
# Data package copying functionality for Griffin

#DP_SRCDIR   = $(EPOC_ROOT)/output/images
DP_CORESRC  =
DP_LANGSRC  =
DP_CUSTSRC  =
DP_UDASRC   =
DP_DCPSRC   =
DP_VPLSRC   =
DP_SIGNSRC  =

DP_OUTDIR   = $(EPOC_ROOT)/output/VPL
DP_CORETGT  = $(DP_OUTDIR)/core.fpsx
DP_LANGTGT  = $(DP_OUTDIR)/lang.fpsx
DP_CUSTTGT  = $(DP_OUTDIR)/customer.fpsx
DP_UDATGT   = $(DP_OUTDIR)/uda.fpsx
DP_DCPTGT   = $(DP_OUTDIR)/carbidev.dcp
DP_VPLTGT   = $(DP_OUTDIR)/carbidev.vpl
DP_SIGNTGT  = $(DP_OUTDIR)/carbidev_signature.bin

DP_MK    = $(OUTPREFIX)_dpcopy.mk
DP_MKLOG = $(basename $(DP_MK))_cone.log
DP_MKOPT =\
  generate --project="$(CONE_PRJ)" $(if $(CONE_CONF),--configuration="$(CONE_CONF)")\
  --impl=dp.makeml --all-layers --set=imaker.makefilename="$(DP_MK)"\
  --log-file="$(DP_MKLOG)" $(addprefix --verbose=,$(CONE_VERBOSE))
DP_MKCMD = $(CONE_TOOL) $(DP_MKOPT)

CLEAN_DPCOPYPRE = del | "$(DP_MK)" "$(DP_MKLOG)"
BUILD_DPCOPYPRE =\
  echo-q | Generating makefile `$(DP_MK)' for Data Package copy |\
  cmd    | $(DP_MKCMD) |\
  test   | "$(DP_MK)"

CLEAN_DPCOPY = deldir | "$(DP_OUTDIR)"

BUILD_DPCOPY =\
  echo-q | Copying Data Package contents |\
  mkdir  | "$(DP_OUTDIR)" |\
  $(foreach type,CORE LANG CUST UDA DCP VPL SIGN,\
    copy | "$(DP_$(type)SRC)" | $(DP_$(type)TGT) |)

#==============================================================================

.PHONY: dpcopy dpcopy-pre

dpcopy    : ;@$(call IMAKER,DPCOPY)
dpcopy-pre: ;@$(call IMAKER,DPCOPYPRE)


###############################################################################
# PlatSim

USE_PLATSIM               = 0

PLATSIM_TOOL              = pscli.exe
PLATSIM_TOOLDIR           = /rd_sw/platsim
PLATSIM_TOOL_INSTANCESDIR = $(PLATSIM_TOOLDIR)/instances
PLATSIM_IMAGESDIR         = $(PLATSIM_TOOLDIR)/HW77/images
PLATSIM_INSTANCE          = 1
RUN_PLATSIM               = 0
PLATSIM_IMAGES            = $(CORE_FLASH)
PLATSIM_IMAGESRC          = $(patsubst %\,%,$(call pathconv,$(dir $(PLATSIM_IMAGES))))

PLATSIM_INSTANCES = $(notdir $(foreach entry,$(wildcard $(PLATSIM_TOOL_INSTANCESDIR)/*),$(call isdir,$(entry))))
define isdir
$(if $(wildcard $1/*),$1)
endef

BUILD_PLATLAUNCH =\
  echo-q | Launching PlatSim instance $(PLATSIM_INSTANCE) |\
  cd     | $(PLATSIM_TOOLDIR) |\
  cmd    | $(PLATSIM_TOOL) --launch $(PLATSIM_INSTANCE)

BUILD_PLATSHUTDOWN =\
  echo-q | Stopping PlatSim instance $(PLATSIM_INSTANCE) |\
  cd     | $(PLATSIM_TOOLDIR) |\
  cmd    | $(PLATSIM_TOOL) --console --shutdown $(PLATSIM_INSTANCE)

BUILD_PLATCREATE =\
  echo-q | Creating new PlatSim instance $(PLATSIM_INSTANCE) |\
  cmd    | $(PLATSIM_TOOL) --console --create $(PLATSIM_INSTANCE) |\
  cmd    | $(PLATSIM_TOOL) --set $(PLATSIM_INSTANCE):imaker_$(PLATSIM_INSTANCE)

BUILD_PLATUPDATE =\
  echo-q | Updating PlatSim instance $(PLATSIM_INSTANCE) |\
  cmd    | $(PLATSIM_TOOL) --console --set $(PLATSIM_INSTANCE):$(PLATSIM_IMAGESRC):$(notdir $(PLATSIM_IMAGES))

BUILD_PLATBLD =\
  cd | $(PLATSIM_TOOLDIR) |\
  $(if $(filter $(PLATSIM_INSTANCE),$(PLATSIM_INSTANCES)),\
    echo-q | Platsim instance $(PLATSIM_INSTANCE) exists | $(BUILD_PLATSHUTDOWN),\
    $(BUILD_PLATCREATE)) |\
  $(BUILD_PLATUPDATE) |\
  $(call iif,$(RUN_PLATSIM),$(BUILD_PLATLAUNCH))

$(call add_help,USE_PLATSIM,v,(string),Define that the configuration is a PlatSim configuration.)


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
endef

BUILD_TOOLINFO = echo-q | | toolchk | $(strip $(TOOL_INFO)) | end

#==============================================================================

_grepversion = $1 | $(PERL) -ne "print, exit if /%version:\s*\S+\s*%/" < $1 | %version:\s*(\S+)\s*%


###############################################################################
# Targets

.PHONY: checkdep opcache sisinst toolinfo

chkdep opcache sisinst toolinfo:\
  ;@$(call IMAKER,$(call ucase,$@))


# END OF IMAKER_TOOLS.MK
