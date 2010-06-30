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
# Description: iMaker help configuration
#



# Add help for a target or variable
# add_help(name,type,values,desc)
# @param name   - The name of the item for which the help is added
# @param type   - The type of the item; t (target) or v (variable)
# @param values - The possible values for the item, only for variables
# @param desc   - Descrition of the item

add_help =\
  $(if $(filter help%,$(MAKECMDGOALS)),\
    $(eval __i_type  := $(if $(filter t% T%,$2),t,v))\
    $(eval __i_isvar := $(filter v,$(__i_type)))\
    $(foreach name,$1,\
      $(eval HELP.$(name).TYPE := $(__i_type))\
      $(if $(__i_isvar),$(eval HELP.$(name).VALUES = $3))\
      $(eval HELP.$(name).DESC = $(strip $(eval __i_desc = $(if $(__i_isvar),$$4,$$3))\
        $(foreach p,$(if $(__i_isvar),,4) 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20,\
          $(if $(call defined,$p),$(eval __i_desc = $(value __i_desc)$(,)$$($p))))\
        $(subst $$1,$(name),$(subst $$2,$(__i_type),$(__i_desc)))))))

get_helpitems =\
  $(strip $(eval __i_list := $(filter HELP.%.TYPE,$(.VARIABLES)))\
  $(foreach var,$(__i_list),$(call select,$($(var)),$1,$(patsubst HELP.%.TYPE,%,$(var)))))

#==============================================================================

.PHONY: help help-config

help:: ;@$(call IMAKER,HELPUSAGE)

help-config: ;@$(call IMAKER,HELPCFG)

help-%: ;@$(call IMAKER,HELP)

# Help usage info
define HELP_USAGE

  Print help data on documented iMaker API items; targets and variables.
  Wildcards *, ? and [..] can be used with % patterns.

  help                  : Print this message.
  help-%                : $(HELP.help-%.DESC)
  help-%-list           : $(HELP.help-%-list.DESC)

  help-target           : $(HELP.help-target.DESC)
  help-target-%         : $(HELP.help-target-%.DESC)
  help-target-%-wiki    : $(HELP.help-target-%-wiki.DESC)
  help-target-%-list    : $(HELP.help-target-%-list.DESC)

  help-variable         : $(HELP.help-variable.DESC)
  help-variable-%       : $(HELP.help-variable-%.DESC)
  help-variable-%-all   : $(HELP.help-variable-%-all.DESC)
  help-variable-%-wiki  : $(HELP.help-variable-%-wiki.DESC)
  help-variable-%-list  : $(HELP.help-variable-%-list.DESC)
  help-variable-%-value : $(HELP.help-variable-%-value.DESC)

  help-config           : $(HELP.help-config.DESC)

  menu                  : Run interactive menu.
  version               : Print the iMaker version number.
endef

BUILD_HELPUSAGE = echo | $(call def2str,$(HELP_USAGE))\n

BUILD_HELPDYNAMIC =

BUILD_HELP =\
  $(BUILD_HELPDYNAMIC)\
  $(eval __i_var := $(filter help-%,$(MAKECMDGOALS)))\
  $(if $(filter help-target help-variable,$(__i_var)),$(eval __i_var := $(__i_var)-*))\
  $(eval __i_helpgoal := $(__i_var))\
  $(foreach prefix,help target variable,$(eval __i_var := $(patsubst $(prefix)-%,%,$(__i_var))))\
  $(foreach suffix,all list value wiki,$(eval __i_var := $(patsubst %-$(suffix),%,$(__i_var))))\
  $(eval __i_list := $(if $(findstring help-target-$(__i_var),$(__i_helpgoal)),$(call get_helpitems,t),\
    $(if $(findstring help-variable-$(__i_var),$(__i_helpgoal)),$(call get_helpitems,v),$(call get_helpitems,t) $(call get_helpitems,v))))\
  $(eval __i_value := $(filter %-$(__i_var)-all %-$(__i_var)-value,$(__i_helpgoal)))\
  $(eval __i_desc := $(filter-out %-$(__i_var)-list %-$(__i_var)-value,$(__i_helpgoal)))\
  $(eval __i_wiki := $(if $(filter %-$(__i_var)-wiki,$(__i_helpgoal)),\ * ))\
  $(call peval,\
    my @var = ($(foreach var,$(foreach var2,$(subst $(,), ,$(__i_var)),$(call filterwcard,$(var2),$(__i_list))),{\
      n=>$(call pquote,$(var))\
      $(eval __i_isvar := $(filter v,$(HELP.$(var).TYPE)))\
      $(if $(__i_value),$(if $(__i_isvar),$(,)v=>$(call pquote,$(call def2str,$($(var))))))\
      $(,)t=>q($(HELP.$(var).TYPE))\
      $(if $(__i_desc),\
        $(,)d=>$(call pquote,$(HELP.$(var).DESC))\
        $(if $(__i_isvar),$(,)V=>$(call pquote,$(HELP.$(var).VALUES)))) }$(,)));\
    DPrint(1, map($(if $(__i_desc),$(if $(__i_wiki),,q(-) x 40 . qq(\n) .))\
      qq($(if $(__i_wiki),== $$_->{n} ==,$$_->{n}))\
      $(if $(__i_value),. ($$_->{t} eq q(v) ? qq( = `$$_->{v}') : q())) . qq(\n)\
      $(if $(__i_desc),.\
        qq($(__i_wiki)Type       : ) . ($$_->{t} eq q(t) ? qq(Target\n) : qq(Variable\n)) .\
        qq($(__i_wiki)Description: $$_->{d}\n) .\
        ($$_->{t} eq q(v) ? qq($(__i_wiki)Values     : $$_->{V}\n) : q())), @var));\
    return(q()))

BUILD_HELPCFG =\
  echo | Finding available configuration file(s):\n\
    $(call peval,return(join(q(), map(Quote(qq($$_\n)), GetConfmkList(1)))))


###############################################################################
# print-%

BUILD_PRINTVAR = $(call peval,DPrint(1,\
  $(foreach var1,$(subst $(,), ,$(subst print-,,$(filter print-%,$(MAKECMDGOALS)))),\
    $(foreach var2,$(call filterwcard,$(var1),$(filter-out BUILD_PRINTVAR,$(filter $(word 1,$(call substm,* ? [, ,$(var1)))%,$(.VARIABLES)))),\
      $(call pquote,$(var2) = `$(call def2str,$($(var2)))').qq(\n),))); return(q()))

print-%: ;@$(call IMAKER,PRINTVAR)

$(call add_help,print-%,t,Print the value(s) of the given variable(s). Wildcards *, ? and [..] can be used in variable names.)


###############################################################################
# Helps

$(call add_help,CONFIGROOT,v,(string),Define the default configuration root directory.)
$(call add_help,USE_PAGING,v,((0|rom|code[:[(1|2|3)]+]?)),Define the usage of On Demand Pagin (ODP). (E.g. 0,rom,code).)
$(call add_help,USE_ROFS,v,([[dummy|]0..6][,[dummy|]0..6]*),Define the rofs sections in use. A comma separated list can be given of possible values. (E.g. 1,2,3).)
$(call add_help,USE_ROMFILE,v,([0|1]),Define whether the \epoc32\rombuild\romfiles.txt is used. Files in romfiles are automatically moved to ROM, everything else in core is moved to ROFS1.)
$(call add_help,USE_SYMGEN,v,([0|1]),Generate the rom symbol file. 0=Do not generate, 1=Generate)
$(call add_help,USE_UDEB,v,([0|1|full]),Include the usage of the debug binary *.txt to define the list of binaries that are taken from udeb folder instead of the urel.)
$(call add_help,KEEPTEMP,v,([0|1]),Keep the buildrom.pl temp files (copied to the OUTDIR). E.g. tmp1.oby tmp2.oby..tmp9.oby)
$(call add_help,LABEL,v,(string),A label to the NAME of the image)
$(call add_help,NAME,v,(string),The name of the image)
$(call add_help,TYPE,v,(rnd|prd|subcon),Defines the image type.)
$(call add_help,OUTDIR,v,(string),The output directory for the image creation.)
$(call add_help,WORKDIR,v,(string),The working directory for the image creation. Deprecated, please use OUTDIR.)
$(call add_help,PRODUCT_NAME,v,(string),Name of the product)
$(call add_help,PRODUCT_MODEL,v,(string),The model of the product)
$(call add_help,PRODUCT_REVISION,v,(string),The revision of the product.)
$(call add_help,BLDROM_OPT,v,(string),The default buildrom.pl options)
$(call add_help,BLDROPT,v,(string),For passing extra parameters (from command line) to the buildrom.pl)
$(call add_help,BLDROBY,v,(string),For passing extra oby files (from command line) to the buildrom.pl)
$(call add_help,SOS_VERSION,v,([0-9]+.[0-9]+),Symbian OS version number. The value is used in the version info generation (platform.txt).)
$(call add_help,COREPLAT_NAME,v,(string),Name of the core platform)
$(call add_help,CORE_DIR,v,(string),The working directory, when creating core image)
$(call add_help,CORE_NAME,v,(string),The name of the core image)
$(call add_help,CORE_OBY,v,(string),The oby file(s) included to the core image creation)
$(call add_help,CORE_OPT,v,(string),The core specific buildrom options)
$(call add_help,CORE_MSTOBY,v,(string),The generated master oby file name, which includes the CORE_OBY files)
$(call add_help,CORE_TIME,v,(string),The time defined to the core image)
$(call add_help,CORE_VERIBY,v,(string),The name of the generated core *version.iby, which included version files and info)
$(call add_help,CORE_ROMVER,v,(string),The rom version parameter passed to the version.iby)
$(call add_help,CORE_VERSION,v,(string),The version of the core. Used in sw.txt generation.)
$(call add_help,CORE_SWVERFILE,v,(string),The (generated) _core_sw.txt version file name. This generated file is included in the CORE_VERIBY file.)
$(call add_help,CORE_SWVERINFO,v,(string),The content string for the sw.txt file.)
$(call add_help,CORE_MODELFILE,v,(string),The (generated) _core_model.txt file name.)
$(call add_help,CORE_MODELINFO,v,(string),The content string for the model.txt file.)
$(call add_help,CORE_IMEISVFILE,v,(string),The (generated) _core_imeisv.txt file name.)
$(call add_help,CORE_IMEISVINFO,v,(string),The content string for the imeisv.txt file.)
$(call add_help,CORE_PLATFILE,v,(string),The (generated) _core_platform.txt file name.)
$(call add_help,CORE_PLATINFO,v,(string),The content string for the platform.txt file.)
$(call add_help,CORE_PRODFILE,v,(string),The (generated) _core_product.txt file name.)
$(call add_help,CORE_PLATINFO,v,(string),The content string for the product.txt file.)
$(call add_help,CORE_FWIDFILE,v,(string),The (generated) _core_fwid.txt file name.)
$(call add_help,CORE_PLATINFO,v,(string),The content string for the fwid.txt file.)
$(call add_help,CORE_NDPROMFILE,v,(string),The name of the core Non Demand Paging rom file.)
$(call add_help,CORE_ODPROMFILE,v,(string),The name of the core On Demand Paging rom file (Rom paging).)
$(call add_help,CORE_CDPROMFILE,v,(string),The name of the core Code Demand Paging rom file (Code paging).)
$(call add_help,CORE_ROFSFILE,v,(string),The name of the core rofs file.)
$(call add_help,CORE_UDEBFILE,v,(string),The name of the core udeb file. See USE_UDEB.)
$(call add_help,ROFS2_DIR,v,(string),The working directory, when creating the rofs2 image)
$(call add_help,ROFS2_NAME,v,(string),The name of the rofs2 image)
$(call add_help,ROFS2_OBY,v,(string),The oby file(s) included to the rofs2 image creation)
$(call add_help,ROFS2_OPT,v,(string),The rofs2 specific buildrom options)
$(call add_help,ROFS2_MSTOBY,v,(string),The (generated) rofs2 master oby file name. This file includes the ROFS2_OBY files and other parameters)
$(call add_help,ROFS2_HEADER,v,(string),This variable can contain a header section for the rofs2 master oby.)
$(call add_help,ROFS2_FOOTER,v,(string),This variable can contain a footer section for the rofs2 master oby.)
$(call add_help,ROFS2_TIME,v,(string),The time defined to the rofs2 image.)
$(call add_help,ROFS2_VERIBY,v,(string),The (generated) version iby file name for the rofs2 image. This file included the version text files and other version parameters.)
$(call add_help,ROFS2_ROMVER,v,(string),The rofs2 ROM version string)
$(call add_help,ROFS2_FWIDFILE,v,(string),The (generated) _rofs2_fwid.txt file name.)
$(call add_help,ROFS2_FWIDINFO,v,(string),The content string for the fwid2.txt file.)
$(call add_help,ROFS3_DIR,v,(string),The working directory, when creating the rofs3 image)
$(call add_help,ROFS3_NAME,v,(string),The name of the rofs3 image)
$(call add_help,ROFS3_OBY,v,(string),The oby file(s) included to the rofs3 image creation)
$(call add_help,ROFS3_OPT,v,(string),The rofs3 specific buildrom options)
$(call add_help,ROFS3_MSTOBY,v,(string),The (generated) version iby file name for the rofs3 image. This file included the version text files and other version parameters.)
$(call add_help,ROFS3_HEADER,v,(string),This variable can contain a header section for the rofs3 master oby.)
$(call add_help,ROFS3_FOOTER,v,(string),This variable can contain a footer section for the rofs3 master oby.)
$(call add_help,ROFS3_TIME,v,(string),The time defined to the rofs3 image.)
$(call add_help,ROFS3_VERIBY,v,(string),The (generated) version iby file name for the rofs3 image. This file included the version text files and other version parameters.)
$(call add_help,ROFS3_ROMVER,v,(string),The rofs3 ROM version string)
$(call add_help,ROFS3_SWVERFILE,v,(string),The (generated) source file name for customersw.txt.)
$(call add_help,ROFS3_SWVERINFO,v,(string),The content string for the customersw.txt.)
$(call add_help,ROFS3_FWIDFILE,v,(string),The (generated) _rofs3_fwid.txt file name.)
$(call add_help,ROFS3_FWIDINFO,v,(string),The content string for the fwid3.txt file.)
$(call add_help,VARIANT_DIR,v,(string),Configure the directory where to included the customer variant content. By default all content under $(VARIANT_CPDIR) is included to the image as it exists in the folder.)
$(call add_help,PRODUCT_VARDIR,v,(string),Overrides the VARIANT_DIR for product variant, see the instructions of VARIANT_DIR for details.)
$(call add_help,TARGET_DEFAULT,v,(string),Configure actual target(s) for target default.)

# Targets
$(call add_help,version,t,Print the version information)
$(call add_help,clean,t,Clean all target files.)
$(call add_help,variant,t,Create the variant image (rofs2,rofs3))
$(call add_help,image,t,Create only the image file(s) (*.img))
$(call add_help,variant-image,t,Create the variant image files (rofs2.img, rofs3.img))
$(call add_help,toolinfo,t,Print info about the tool)
$(call add_help,romsymbol,t,Create the rom symbol file)
$(call add_help,all,t,Create all image sections and symbol files.)
$(call add_help,flash-all,t,Create all image sections and symbol files.)
$(call add_help,flash,t,Create all image sections files. Not any symbol files.)
$(call add_help,f2image,t,Revert the Symbian image file (.img) from the elf2flash (flash) file.(See CORE_FLASH,ROFS2_FLASH,ROFS3_FLASH))
$(call add_help,step-%,t,\
Generic target to execute any step inside the iMaker configuration. Any step (e.g. BUILD_*,CLEAN_*) can be executed with step-STEPNAME.\
Example: step-ROFS2PRE executes the CLEAN_ROFS2PRE and BUILD_ROFS2PRE commands.)
$(call add_help,default,t,Default target, uses variable TARGET_DEFAULT to get actual target(s), current default = $$(TARGET_DEFAULT).)

$(call add_help,help,t,Print help on help targets.)
$(call add_help,help-%,t,Print help on help items matching the pattern.)
$(call add_help,help-%-list,t,Print a list of help items matching the pattern.)
$(call add_help,help-target,t,Print help on all targets (same as help-target-*).)
$(call add_help,help-target-%,t,Print help on targets matching the pattern.)
$(call add_help,help-target-%-wiki,t,Print wiki-formatted help on targets matching the pattern.)
$(call add_help,help-target-%-list,t,Print a list of targets matching the pattern.)
$(call add_help,help-variable,t,Print help on all variables (same as help-variable-*).)
$(call add_help,help-variable-%,t,Print help on variables matching the pattern.)
$(call add_help,help-variable-%-all,t,Print full help on variables matching the pattern.)
$(call add_help,help-variable-%-wiki,t,Print wiki-formatted help on variables matching the pattern.)
$(call add_help,help-variable-%-list,t,Print a list of variables matching the pattern.)
$(call add_help,help-variable-%-value,t,Print a list of variables with values matching the pattern.)
$(call add_help,help-config,t,Print a list of available configurations in the current working environment.)


# END OF IMAKER_HELP.MK
