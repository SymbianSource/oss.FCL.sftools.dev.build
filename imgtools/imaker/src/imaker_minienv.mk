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
# Description: Default iMaker minienv configuration
#



###############################################################################
#  __  __ _      _ ___
# |  \/  (_)_ _ (_) __|_ ___ __
# | |\/| | | ' \| | _|| ' \ V /
# |_|  |_|_|_||_|_|___|_||_\_/
#

MINIENV_ZIP      = $(EPOC_ROOT)/$(MINIENV_MFBSNAME)_$(MINIENV_MFBVER).jar
MINIENV_EXCLBIN  = *.axf *.bin *.cmt *.fpsx *.hex *.out *.pmd *.ppu *.zip
MINIENV_INCLBIN  = *.axf *.bin *.fpsx *.hex *.out
MINIENV_SOSDIR   = $(OUTDIR)

MINIENV_MFFILE   = $(EPOC_ROOT)/META-INF/MANIFEST.MF
MINIENV_MFTMP    = $(OUTTMPDIR)/META-INF/MANIFEST.MF

MINIENV_MFBNAME  = Minienv for $(PRODUCT_MODEL)
MINIENV_MFBSNAME = com.nokia.tools.griffin.minienv.$(PRODUCT_MODEL)
MINIENV_MFBVER   = $(MAJOR_VERSION).$(MINOR_VERSION).0
MINIENV_MFPATH   = epoc32/tools
MINIENV_MFSWVER  = $(word 1,$(subst ., ,$(MINIENV_MFBVER))).*
MINIENV_MFCFGFLT = (&(product_type=$(PRODUCT_TYPE))(sw_version=$(MINIENV_MFSWVER)))
#MINIENV_MFCFGFLT = (&(product_type=$(PRODUCT_TYPE))(sw_version=$(MAJOR_VERSION).$(MINOR_VERSION)))

define MINIENV_MFINFO
  Manifest-Version: 1.0
  Bundle-ManifestVersion: 2.0
  Bundle-Name: $(MINIENV_MFBNAME)
  Bundle-SymbolicName: $(MINIENV_MFBSNAME);singleton:=true
  Bundle-Version: $(MINIENV_MFBVER)
  Griffin-ExportDirectory: $(MINIENV_MFPATH)
  Griffin-ConfigurationFilter: $(MINIENV_MFCFGFLT)

  Name: epoc32/tools/imaker.cmd
  Require-Bundle: com.nokia.tools.griffin.theme
endef

MINIENV_META = find-af | $(MINIENV_MFTMP) | $(MINIENV_MFFILE) |

#==============================================================================

MINIENV_IMAKER =\
  find-a  | $(E32TOOLS)   | imaker imaker.cmd ||\
  find-a  | $(IMAKER_DIR) | * ||\
  find-ar | $(CONFIGROOT)/assets/image | * |

MINIENV_ITOOL =\
  find-a | $(ITOOL_DIR) | *.exe *.pl *.py imgcheck.* | *upct*

MINIENV_BLDROM =\
  find-a | $(E32TOOLS) |\
    armutl.pm bpabiutl.pm buildrom.* checksource.pm configpaging.* datadriveimage.pm e32plat.pm e32variant.pm\
    externaltools.pm flexmodload.pm genutl.pm maksym.* maksymrofs.* modload.pm pathutl.pm rofsbuild.exe rombuild.exe\
    romosvariant.pm romutl.pm spitool.* uidcrc.exe winutl.pm feature* genericparser.pm rvct_*2set.pm writer.pm mingwm10.dll ||\
  find-ar | $(E32TOOLS)/build/lib/XML | * |

MINIENV_CONE = find-a | $(E32TOOLS) | cone cone.cmd || find-ar | $(CONE_TOOLDIR) | * |

MINIENV_CPP = find-a | $(E32GCCBIN) | cpp.exe cygwin1.dll |

MINIENV_TOOL1 =\
  $(MINIENV_ITOOL)  |\
  $(MINIENV_BLDROM) |\
  $(MINIENV_CONE)   |\
  $(MINIENV_CPP)    |\
  find-a | $(E32TOOLS) |\
    featuredatabase.dtd s60ibymacros.pm\
    bmconv.exe dumpsis.exe elf2e32.exe interpretsis.exe mifconv.exe petran.exe svgtbinencode.exe\
    xerces-c_2_*.dll ||\
  find-a | $(E32TOOLS)/variant | * ||

MINIENV_TOOL2 =\
  find-ar | $(dir $(WIDGET_TOOL)) $(WIDGET_HSTOOLDIR) | * ||\
  find-a  | $(E32DATAZ)/private/10282f06 $(EPOC32)/winscw/c/private/10282f06 | Widget_lproj.xml ||

MINIENV_TOOL = $(foreach tool,$(sort $(filter $(addprefix MINIENV_TOOL,0 1 2 3 4 5 6 7 8 9),$(.VARIABLES))),$($(tool)) |)

MINIENV_CONF1 =\
  find-a  | $(E32INC)              | *.hrh ||\
  find-ar | $(E32INCCFG)           | *     ||\
  find-ar | $(E32ROM)/configpaging | *     ||\
  find-a  | $(sort $(dir $(CORE_FEAXML)))  | $(notdir $(CORE_FEAXML)) ||\
  find-a  | $(CONFIGROOT)          | *.mk  ||\
  find-a  | $(PLATFORM_DIR)        | *.mk mem*.hrh ||\
  find-ar | $(PRODUCT_DIR)         | *.mk mem*.hrh ||\
  find-a  | $(E32INC)/mw                                      | ThirdPartyBitmap.pal       ||\
  find-a  | $(E32ROMINC)/customervariant/mw                   | Certificates_Operator.iby  ||\
  find-a  | $(E32DATAZ)/private/101f72a6                      | *                          ||\
  find-a  | $(E32DATAZ)/private/10202be9                      | cccccc00_empty.cre         ||\
  find-a  | $(E32DATAZ)/private/200009F3                      | defaultimportfile.mde      ||\
  find-a  | $(E32DATAZ)/private/20019119                      | config.xml                 ||\
  find-a  | $(E32DATAZ)/resource                              | swicertstore*.dat          ||\
  find-a  | $(E32DATAZ)/system/data                           | SkinExclusions.ini         ||\
  find-ar | $(E32DATAZ)/system/data/midp2/security/trustroots | *                          ||\
  find-a  | $(E32DATAZ)/system/sounds/audiothemes             | at_nokia.xml               ||\
  find-a  | $(EPOC32)/release/armv5/urel                      | R1_Mobile_4_0_Operator.cfg ||\
  find-a  | $(EPOC32)/release/armv5/urel/z/private/100059C9   | ScriptInit.txt             ||\
  find-a  | $(EPOC_ROOT)/ext/app/firsttimeuse/StartupSettings3/tools | APConf.txt          ||\
  find-af | $(SISINST_HALHDA) |||\
  find-ar | $(CONFIGROOT) | * | *.pmd isa.out dsp.hex *.cmt fota_updapp.bin *.axf DCT_ISA*.zip |

MINIENV_CONF2 =\
  sosfind-a | $(MINIENV_SOSDIR) | *.rom.oby *.rofs?.oby *.uda.oby *.emmc.oby *.mcard.oby | *_bldromplugin.log

MINIENV_CONF3 =\
  find-ar | $(OST_DICTDIR)  | $(OST_DICTPAT)     ||\
  find-a  | $(COREPLAT_DIR) | $(MINIENV_INCLBIN) ||\
  find-ar | $(PRODUCT_DIR)  | $(MINIENV_INCLBIN) ||

#  find-a  | $(CONFIGROOT)   | *.confml ||\
#  find-ar | $(CONFIGROOT)/assets | *   ||\
#  find-a  | $(PLATFORM_DIR) | *.confml ||\
#  find-ar | $(PRODUCT_DIR)  | *.confml ||\

MINIENV_CONF = $(foreach conf,$(sort $(filter $(addprefix MINIENV_CONF,0 1 2 3 4 5 6 7 8 9),$(.VARIABLES))),$($(conf)) |)

#==============================================================================

CLEAN_MINIENV = $(if $(MINIENV_META),$(CLEAN_MINIENVMETA) |) del | "$(MINIENV_ZIP)"
BUILD_MINIENV =\
  $(if $(MINIENV_META),$(BUILD_MINIENVMETA) |)\
  echo-q | Creating minimal flash image creation environment |\
  find ||||\
  $(MINIENV_META)   |\
  $(MINIENV_IMAKER) |\
  $(MINIENV_TOOL)   |\
  $(MINIENV_CONF)   |\
  zip$(if $(filter debug 127,$(VERBOSE)),,-q) | "$(MINIENV_ZIP)" | __find__ |

REPORT_MINIENV =\
  Minienv input SOS dir | $(MINIENV_SOSDIR) | d |\
  Minienv archive       | $(MINIENV_ZIP)    | f

CLEAN_MINIENVMETA = del | "$(MINIENV_MFTMP)"
BUILD_MINIENVMETA =\
  echo-q | Creating manifest file |\
  write  | "$(MINIENV_MFTMP)" | $(call def2str,$(MINIENV_MFINFO))\n


###############################################################################
# Targets

.PHONY: minienv minienv-conf minienv-imaker minienv-tool core-minienv

minienv-conf: MINIENV_IMAKER =
minienv-conf: MINIENV_TOOL   =

minienv-imaker: MINIENV_TOOL =
minienv-imaker: minienv-tool ;

minienv-itool: MINIENV_TOOL = $(MINIENV_ITOOL)
minienv-itool: minienv-tool ;

minienv-tool: MINIENV_META =
minienv-tool: MINIENV_CONF =

minienv: MINIENV_CONF3 =
minienv minienv-conf minienv-tool core-minienv: ;@$(call IMAKER,MINIENV)


# END OF IMAKER_MINIENV.MK
