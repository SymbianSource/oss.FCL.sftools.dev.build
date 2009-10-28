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
    $(eval __i_type  := $(call select,$(call substr,1,1,$(strip $2)),t,t,v))\
    $(eval __i_isvar := $(call equal,$(__i_type),v))\
    $(foreach name,$1,\
      $(eval HELP.$(name).TYPE := $(__i_type))\
      $(if $(__i_isvar),$(eval HELP.$(name).VALUES = $3))\
      $(eval HELP.$(name).DESC = $(strip $(eval __i_desc := $(if $(__i_isvar),$4,$3))\
        $(foreach p,$(if $(__i_isvar),,4) 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20,\
          $(if $(call defined,$p),$(eval __i_desc := $(__i_desc)$(,)$($p)))))$(__i_desc))))

get_helpitems =\
  $(strip $(eval __i_list := $(filter HELP.%.TYPE,$(.VARIABLES)))\
  $(foreach var,$(__i_list),$(call select,$($(var)),$1,$(patsubst HELP.%.TYPE,%,$(var)))))

#==============================================================================

.PHONY: help help-config help-target help-variable

.DEFAULT_GOAL := help

help:: ;@$(call IMAKER,HELPUSAGE:b)

help-config: ;@$(call IMAKER,HELPCFG:b)

help-target help-variable: $$@-* ;

help-target-%-list help-target-%-wiki help-target-% \
help-variable-%-list help-variable-%-value help-variable-%-all help-variable-%-wiki help-variable-% \
help-%-list help-%:\
  ;@$(call IMAKER)

# Help usage info
define HELP_USAGE

  Print help data on documented iMaker API items; targets and variables.
  Wildcards *, ? and [] can be used with % patterns.

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

BUILD_HELPDYNAMIC =\
  $(foreach file,$(call reverse,$(wildcard $(addsuffix /$(TRACE_PREFIX)*$(TRACE_SUFFIX),$(TRACE_IDIR)))),\
    $(call add_help,core-trace-$(patsubst $(TRACE_PREFIX)%$(TRACE_SUFFIX),%,$(notdir $(file))),t,Core image with traces for $(file).))\
  $(call add_help,$(call getlastdir,$(wildcard $(LANGPACK_ROOT)/$(LANGPACK_PREFIX)*/)),t,Language variant target.)\
  $(call add_help,$(call getlastdir,$(wildcard $(CUSTVARIANT_ROOT)/$(CUSTVARIANT_PREFIX)*/)),t,Customer variant target.)\
  $(eval include $(wildcard $(LANGPACK_ROOT)/$(LANGPACK_PREFIX)*/$(LANGPACK_MKNAME)))\
  $(eval include $(wildcard $(CUSTVARIANT_ROOT)/$(CUSTVARIANT_PREFIX)*/$(VARIANT_MKNAME)))

BUILD_HELP =\
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
      $(eval __i_isvar := $(call equal,$(HELP.$(var).TYPE),v))\
      $(if $(__i_value),$(if $(__i_isvar),$(,)v=>$(call pquote,$(call def2str,$($(var))))))\
      $(,)t=>q($(HELP.$(var).TYPE))\
      $(if $(__i_desc),\
        $(,)d=>$(call pquote,$(HELP.$(var).DESC))\
        $(if $(__i_isvar),$(,)V=>$(call pquote,$(HELP.$(var).VALUES)))) }$(,)));\
    imaker:DPrint(1, map($(if $(__i_desc),$(if $(__i_wiki),,q(-) x 40 . qq(\n) .))\
      qq($(if $(__i_wiki),== $$_->{n} ==,$$_->{n}))\
      $(if $(__i_value),. ($$_->{t} eq q(v) ? qq( = `$$_->{v}$') : q())) . qq(\n)\
      $(if $(__i_desc),.\
        qq($(__i_wiki)Type       : ) . ($$_->{t} eq q(t) ? qq(Target\n) : qq(Variable\n)) .\
        qq($(__i_wiki)Description: $$_->{d}\n) .\
        ($$_->{t} eq q(v) ? qq($(__i_wiki)Values     : $$_->{V}\n) : q())), @var));\
    return(q()))

BUILD_HELPCFG =\
  echo | Finding available configuration file(s):\n\
    $(call get_cfglist,$(CONFIGROOT),image_conf_.*\.mk,2)\n

get_cfglist =\
  $(call peval,\
    use File::Find;\
    my ($$dir, @conf) = (GetAbsDirname($(call pquote,$1)), ());\
    find(sub {\
      push(@conf, $$File::Find::name) if\
        /$2$$/s && (($$File::Find::name =~ tr/\///) > (($$dir =~ tr/\///) + $3));\
    }, $$dir);\
    return(join(q(\n), map(Quote($$_), sort({lc($$a) cmp lc($$b)} @conf)))))


###############################################################################
# Helps

$(call add_help,CONFIGROOT,v,(string),Define the default configuration root directory.)
$(call add_help,USE_OVERRIDE,v,([0|1]),Define whether the override.pm Buildrom.pl plugin is used.)
$(call add_help,USE_PAGING,v,((0|rom|code[:[(1|2|3)]+]?)),Define the usage of On Demand Pagin (ODP). (E.g. 0,rom,code).)
$(call add_help,USE_ROFS,v,([[dummy|]0..6][,[dummy|]0..6]*),Define the rofs sections in use. A comma separated list can be given of possible values. (E.g. 1,2,3).)
$(call add_help,USE_ROMFILE,v,([0|1]),Define whether the \epoc32\rombuild\romfiles.txt is used. Files in romfiles are automatically moved to ROM, everything else in core is moved to ROFS1.)
$(call add_help,USE_SYMGEN,v,([0|1]),Generate the rom symbol file. 0=Do not generate, 1=Generate)
$(call add_help,USE_UDEB,v,([0|1|full]),Include the usage of the debug binary *.txt to define the list of binaries that are taken from udeb folder instead of the urel.)
$(call add_help,USE_VERGEN,v,([0|1]),Use iMaker version info generation)
$(call add_help,KEEPTEMP,v,([0|1]),Keep the buildrom.pl temp files (copied to the WORKDIR). E.g. tmp1.oby tmp2.oby..tmp9.oby)
$(call add_help,LABEL,v,(string),A label to the NAME of the image)
$(call add_help,NAME,v,(string),The name of the image)
$(call add_help,TYPE,v,(rnd|prd|subcon),Defines the image type.)
$(call add_help,WORKDIR,v,(string),The working directory for the image creation)
$(call add_help,PRODUCT_NAME,v,(string),Name of the product)
$(call add_help,PRODUCT_MODEL,v,(string),The model of the product)
$(call add_help,PRODUCT_REVISION,v,(string),The revision of the product.)
$(call add_help,BLDROM_OPT,v,(string),The default buildrom.pl options)
$(call add_help,BLDROPT,v,(string),For passing extra parameters (from command line) to the buildrom.pl)
$(call add_help,BLDROBY,v,(string),For passing extra oby files (from command line) to the buildrom.pl)
$(call add_help,SOS_VERSION,v,([0-9]+.[0-9]+),Symbian OS version number. The value is used in the version info generation (platform.txt).(see USE_VERGEN))
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
$(call add_help,ROFS3_CUSTSWFILE,v,(string),The (generated) source file name for customersw.txt.)
$(call add_help,ROFS3_CUSTSWINFO,v,(string),The content string for the customersw.txt.)
$(call add_help,ROFS3_FWIDFILE,v,(string),The (generated) _rofs3_fwid.txt file name.)
$(call add_help,ROFS3_FWIDINFO,v,(string),The content string for the fwid3.txt file.)
$(call add_help,VARIANT_DIR,v,(string),Configure the directory where to included the customer variant content. By default all content under $(VARIANT_CPDIR) is included to the image as it exists in the folder.)
$(call add_help,VARIANT_CONFML,v,(string),Configure what is the ConfigurationTool input confml file, when configuration tool is ran.)
$(call add_help,VARIANT_CONFCP,v,(string),Configure which ConfigurationTool generated configurations dirs are copied to output.)

# Targets
$(call add_help,version,t,Print the version information)
$(call add_help,clean,t,Clean all target files.)
$(call add_help,core,t,Create the core image (ROM,ROFS1))
$(call add_help,rofs2,t,Create the rofs2 image)
$(call add_help,rofs3,t,Create the rofs3 image)
$(call add_help,variant,t,Create the variant image (rofs2,rofs3))
$(call add_help,uda,t,Create the User Data area (uda) image.)
$(call add_help,image,t,Create only the image file(s) (*.img))
$(call add_help,core-image,t,Create the core image files (rom.img, rofs1.img))
$(call add_help,rofs2-image,t,Create the rofs2 image file (rofs2.img))
$(call add_help,rofs3-image,t,Create the rofs3 image file (rofs3.img))
$(call add_help,variant-image,t,Create the variant image files (rofs3.img,rofs3.img))
$(call add_help,uda-image,t,Create the User Data area (uda) image.)
$(call add_help,toolinfo,t,Print info about the tool)
$(call add_help,romsymbol,t,Create the rom symbol file)
$(call add_help,all,t,Create all image sections and symbol files.)
$(call add_help,flash-all,t,Create all image sections and symbol files.)
$(call add_help,flash,t,Create all image sections files. Not any symbol files.)
$(call add_help,f2image,t,Revert the Symbian image file (.img) from the elf2flash (flash) file.(See CORE_FLASH,ROFS2_FLASH,ROFS3_FLASH))
$(call add_help,step-%,t,\
Generic target to execute any step inside the iMaker configuration. Any step (e.g. BUILD_*,CLEAN_*) can be executed with step-STEPNAME.\
Example: step-ROFS2PRE executes the CLEAN_ROFS2PRE and BUILD_ROFS2PRE commands.)
$(call add_help,print-%,t,Print the value of the given variable to the screen.)

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
