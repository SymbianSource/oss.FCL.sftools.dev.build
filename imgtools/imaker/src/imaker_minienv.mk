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
# Description: Default iMaker minienv configuration
#



###############################################################################
#  __  __ _      _ ___
# |  \/  (_)_ _ (_) __|_ ___ __
# | |\/| | | ' \| | _|| ' \ V /
# |_|  |_|_|_||_|_|___|_||_\_/
#

MINIENV_ZIP     = $(WORKPREFIX)_minienv.zip
MINIENV_EXCLBIN = *.axf *.bin *.cmt *.fpsx *.hex *.out *.pmd *.ppu *.zip
MINIENV_INCLBIN = *.axf *.bin *.fpsx *.hex *.out
MINIENV_SOSDIR  = $(WORKDIR)

CLEAN_MINIENV = del | $(MINIENV_ZIP)
BUILD_MINIENV =\
  echo-q | Creating minimal flash image creation environment $(MINIENV_ZIP) |\
  $(MINIENV_TOOL) | $(MINIENV_CONF) |\
  zip-q  | $(MINIENV_ZIP) | __find__ |

MINIENV_IMAKER =\
  find   | $(E32TOOLS)   | imaker.cmd localise.pm localise_all_resources.pm obyparse.pm override.pm plugincommon.pm | |\
  find-a | $(IMAKER_DIR) | * |

MINIENV_TOOL =\
  $(MINIENV_IMAKER) |\
  find-a | $(ITOOL_DIR) | * | |\
  find-a | $(E32TOOLS) |\
    cli.cmd s60ibymacros.pm\
    armutl.pm bpabiutl.pm buildrom.* checksource.pm configpaging.pm datadriveimage.pm e32plat.pm\
    e32variant.pm externaltools.pm featurevariantmap.pm featurevariantparser.pm genutl.pm maksym.*\
    maksymrofs.* modload.pm pathutl.pm rofsbuild.exe rombuild.exe spitool.* uidcrc.exe winutl.pm\
    *.bsf | gcc*.bsf |\
  find-a  | $(E32TOOLS)/variant | * | |\
  find-ar | $(E32GCCBIN)        | * | |\
  find-ar | $(CONFT_TOOLDIR)    | * |

MINIENV_CONF =\
  find-a    | $(E32INC)              | *.hrh | |\
  find-ar   | $(E32INCCFG)           | * | |\
  find-ar   | $(E32INC)/oem          | * | |\
  find-ar   | $(E32INC)/variant      | * | |\
  find-a    | $(E32ROM)              | * | |\
  find-ar   | $(E32ROMCFG)           | * | $(MINIENV_EXCLBIN) |\
  find-ar   | $(E32ROM)/configpaging | * | |\
  find-ar   | $(E32ROMINC)           | * | |\
  find-ar   | $(E32ROM)/variant      | * | |\
  find-ar   | $(OST_DICTDIR)         | $(OST_DICTPAT) | |\
  find-ar   | $(EPOC32)/data/Z/resource/plugins | * | |\
  find-a    | $(COREPLAT_DIR) | $(MINIENV_INCLBIN) | |\
  find-ar   | $(PRODUCT_DIR)  | $(MINIENV_INCLBIN) | |\
  sosfind-a | $(MINIENV_SOSDIR) | *.tmp1.oby | *.rom.oby *.rofs?.oby | *_bldromplugin.log


###############################################################################
# Targets

.PHONY:\
  minienv

minienv: ;@$(call IMAKER,$(call ucase,$@))


# END OF IMAKER_MINIENV.MK
