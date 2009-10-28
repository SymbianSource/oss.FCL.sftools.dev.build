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
# Description: Default iMaker configuration
#



#
# http://www.gnu.org/software/make/manual/make.html
#

ifndef __IMAKER_MK__
__IMAKER_MK__ := 1

# Special reserved characters (ASCII 30 and 31)
ichar := 
pchar := 

comma    := ,
,        := ,
empty    :=
space    := $(empty) #
$(space) := $(space)
squot    := '\''
'        := '\''
\t       := $(empty)	# Tabulator!

# Newline
define \n


endef

DEFINE := define

[A-Z]   := A B C D E F G H I J K L M N O P Q R S T U V W X Y Z #
[a-z]   := a b c d e f g h i j k l m n o p q r s t u v w x y z #
[0-9]   := 0 1 2 3 4 5 6 7 8 9 #
[spcl]  := ! " \# $ % & ' ( ) * + , - . / : ; < = > ? @ [ \ ] ^ _ ` { | } ~ #
charset := $([A-Z])$([a-z])$([0-9])$([spcl])

not         = $(if $(strip $1),,1)
true        = $(if $(filter-out 0,$(subst 0,0 ,$1)),1)
false       = $(if $(call true,$1),,1)
iif         = $(if $(call true,$1),$2,$3)
defined     = $(filter-out undef%,$(origin $1))
equal       = $(if $(strip $(subst $(strip $1),,$2)$(subst $(strip $2),,$1)),,1)
select      = $(if $(call equal,$(call lcase,$1),$(call lcase,$2)),$3,$4)
everynth    = $(strip $(eval __i_enth :=)$(call _everynth,$1,$(call restwords,$2,$3))$(__i_enth))
_everynth   = $(if $2,$(eval __i_enth += $(word 1,$2))$(call _everynth,$1,$(call restwords,$1,$(call restwords,$2))))
def2str     = $(if $(or $(call false,$2),$(findstring $(\n),$1)),$(subst $(\t),\t,$(subst $(\n),\n,$(call quote,$1))),$1)
cleandef    = $(subst $(ichar)_, ,$(filter-out /*%*/,$(subst /*, /*,$(subst */,*/ ,$(subst $( ),$(ichar)_,$1)))))
getwords    = $(subst |, ,$(subst \|,$(ichar):,$(subst $( ),$(ichar)_,$1)))
restoreelem = $(strip $(subst $(ichar):,\|,$(subst $(ichar)_, ,$1)))
getelem     = $(call restoreelem,$(word $1,$(call getwords,$2)))
lcase       = $(call tr,$([A-Z]),$([a-z]),$1)
ucase       = $(call tr,$([a-z]),$([A-Z]),$1)
pathconv    = $(call iif,$(USE_UNIX),$(subst \,/,$1),$(subst /,\,$1))
reverse     = $(if $1,$(call reverse,$(call restwords,$1)) $(word 1,$1))
firstwords  = $(if $2,$(wordlist 1,$(words $(wordlist $1,$(words $2),$2)),$2),$(wordlist 1,$(words $(wordlist 2,$(words $1),$1)),$1))
restwords   = $(if $2,$(wordlist $1,$(words $2),$2),$(wordlist 2,$(words $1),$1))
restelems   = $(call restoreelem,$(subst $( ),|,$(call restwords,$1,$(call getwords,$2))))
substm      = $(eval __i_str := $3)$(strip $(foreach w,$1,$(eval __i_str := $(subst $w,$2,$(__i_str)))))$(__i_str)
substs      = $(subst $(ichar)\,$2,$(subst $1,$2,$(subst $2,$(ichar)\,$3)))
quote       = $(call substs,\t,\\\t,$(call substs,\n,\\\n,$1))
quoteval    = $(subst \#,\\\#,$(subst $$,$$$$,$1))
sstrip      = $(subst $( ),,$(strip $1))

strlen = $(call _str2chars,$1)$(words $(__i_str))
substr = $(call _str2chars,$3)$(subst $(ichar), ,$(subst $( ),,$(wordlist $1,$(if $2,$2,$(words $(__i_str))),$(__i_str))))
_str2chars = $(strip\
  $(eval __i_str := $(subst $( ),$(ichar),$1))\
  $(foreach c,$(charset)$(ichar),$(eval __i_str := $(subst $c,$c ,$(__i_str)))))

tr =\
  $(strip $(eval __i_tr := $3)\
  $(foreach c,\
    $(join $(addsuffix :,$1),$2),\
    $(eval __i_tr := $(subst $(word 1,$(subst :, ,$c)),$(word 2,$(subst :, ,$c)),$(__i_tr))))$(__i_tr))

pquote      = q$(pchar)$1$(pchar)
peval       = @PEVAL{$(call substs,|,\|,$1)}LAVEP@
phex        = $(call peval,sprintf(q(%0$(if $2,$2,8)X),$(subst 0x0x,0x,$1)))
pabs2rel    = $(call peval,GetRelFname($(call pquote,$1$), $(call pquote,$2)))
pfilesize   = $(call peval,-s $(call pquote,$1) || 0)
prepeat     = $(call peval,$(call pquote,$2) x ($1))
pstr2xml    = $(call peval,Str2Xml($(call pquote,$1)))
pmatch      = $(call peval,$(call pquote,$1) =~ m$(pchar)$2$(pchar)m $(if $3,$3,&& $$1 || q(???)))
pgrep       = $(call peval,\
  $(eval __i_notfound := $(call pquote,$(if $4,$4,???)))\
  open(F, $(call pquote,$1)) or return($(__i_notfound));\
  $$_ = $(if $2,Uni2Ascii)(join(q(), <F>));\
  $$_ = Quote($(if $3,m$(pchar)$3$(pchar)m ? $$1 : $(__i_notfound),$$_));\
  s/\n/\\\n/g; s/\t/\\\t/g;\
  close(F); return($$_))

getlastdir = $(foreach file,$1,$(notdir $(patsubst %/,%,$(file))))
upddrive   = $(if $2,$2,$(EPOCDRIVE))$(if $(filter %:,$(call substr,1,2,$1)),$(call substr,3,,$1),$1)
dir2inc    = $(foreach dir,$1,-I$(call upddrive,$(dir)))
findfile   = $(foreach file,$1,$(eval __i_ffile := $(call _findfile,$(addsuffix /$(file),$2)))$(if $(__i_ffile),$(__i_ffile),$(file)))
_findfile  = $(if $1,$(eval __i_ffile := $(wildcard $(word 1,$1)))$(if $(__i_ffile),$(__i_ffile),$(call _findfile,$(call restwords,$1))))

filterwcard = $(shell $(PERL) -Xe '\
  (my $$re = q$(ichar)$1$(ichar)) =~ s/(.)/{q(*)=>q(.*),q(?)=>q(.),q([)=>q([),q(])=>q(])}->{$$1} || qq(\Q$$1\E)/ge;\
    print(map(qq( $$_), sort({lc($$a) cmp lc($$b)} grep(/^$$re$$/, split(/\s+/, q$(ichar)$2$(ichar))))))')

cppdef2var =\
  $(if $(wildcard $1),\
    $(eval __i_def2var := $(shell $(PERL) -Xe '\
      print(join(q(|), map(/^\s*\#define\s+(\S+)\s*(.*?)\s*$$/ ? qq($$1?=) . ($$2 eq q() ? 1 : $$2) : (),\
        sort({lc($$a) cmp lc($$b)} qx$(pchar)$(CPP) -nostdinc -undef -dM $(call dir2inc,$2) $(call upddrive,$1)$(pchar)))))'))\
    $(foreach assign,$(call getwords,$(__i_def2var)),$(eval $(call restoreelem,$(assign)))),\
  $(eval include $1))

mac2cppdef = $(foreach def,$1,$(if\
  $(filter -D% --D%,$(def)),$(eval __i_def := $(subst =, ,$(patsubst $(if $(filter --D%,$(def)),-)-D%,%,$(def))))\
    $(\n)$(if $(filter -D%,$(def)),\#undef  $(word 1,$(__i_def))$(\n)\#define,define ) $(word 1,$(__i_def)) $(word 2,$(__i_def)),\
  $(if $(filter -U%,$(def)),$(\n)\#undef $(patsubst -U%,%,$(def)))))

EPOCDRIVE   := $(eval EPOCDRIVE := $(call substr,1,2,$(CURDIR)))$(if $(filter %:,$(EPOCDRIVE)),$(EPOCDRIVE))
EPOC32      := $(patsubst %/,%,$(subst \,/,$(EPOCROOT)))/epoc32
E32ROM      := $(EPOC32)/rom
E32ROMCFG   := $(E32ROM)/config
E32ROMINC   := $(E32ROM)/include
E32ROMBLD   := $(EPOC32)/rombuild
E32INC      := $(EPOC32)/include
E32INCCFG   := $(E32INC)/config
E32TOOLS    := $(EPOC32)/tools
E32GCCBIN   := $(EPOC32)/gcc/bin

ITOOL_DIR   ?= $(E32TOOLS)/rom
ITOOL_PATH  :=
IMAKER_DIR  ?= $(ITOOL_DIR)/imaker
IMAKER_TOOL := $(IMAKER_DIR)/imaker.pl

CPP       ?= $(if $(wildcard $(E32TOOLS)/scpp.exe),$(E32TOOLS)/scpp.exe,cpp)
PERL      ?= perl
PYTHON    ?= python
USE_UNIX  := $(if $(findstring cmd.exe,$(call lcase,$(SHELL)))$(findstring mingw,$(call lcase,$(MAKE))),0,1)
NULL      := $(call iif,$(USE_UNIX),/dev/null,nul)
DONOTHING := $(call iif,$(USE_UNIX),\#,rem)

YEAR  := $(call substr,1,4,$(TIMESTAMP))
YEAR2 := $(call substr,3,4,$(TIMESTAMP))
MONTH := $(call substr,5,6,$(TIMESTAMP))
DAY   := $(call substr,7,8,$(TIMESTAMP))
WEEK  := $(call substr,15,,$(TIMESTAMP))

CURDIR := $(call substr,$(call select,$(call substr,1,2,$(CURDIR)),$(EPOCDRIVE),3,1),,$(CURDIR))
CURDIR := $(CURDIR:/=/.)
USER   := $(or $(USERNAME),$(shell $(PERL) -Xe 'print(getlogin())'))

MAKECMDGOALS ?= $(.DEFAULT_GOAL)
TARGET        = $(word 1,$(MAKECMDGOALS))
TARGETNAME    = $(word 1,$(subst -, ,$(TARGET)))
TARGETID      = $(subst $( ),_,$(call restwords,$(subst _, ,$(TARGETNAME))))
TARGETEXT     = $(findstring -,$(TARGET))$(subst $( ),-,$(call restwords,$(subst -, ,$(TARGET))))

CLEAN     = 1
BUILD     = 1
KEEPGOING = 0
KEEPTEMP  = 0
PRINTCMD  = 0
SKIPPRE   = 0
SKIPBLD   = 0
SKIPPOST  = 0
VERBOSE   = 1

CONFIGROOT ?= $(E32ROMCFG)

LABEL      =
NAME       = $(PRODUCT_NAME)$(LABEL)
WORKDIR    = $(if $(PRODUCT_NAME),$(E32ROMBLD)/$(PRODUCT_NAME),$(CURDIR))
WORKPREFIX = $(WORKDIR)/$(NAME)
WORKNAME   = $(WORKPREFIX)

CLEAN_WORKAREA  = del | $(WORKDIR)/* | deldir | $(WORKDIR)/*
ALL.CLEAN.STEPS = $(ALL.IMAGE.STEPS) WORKAREA


###############################################################################
#

CMDFILE = $(WORKPREFIX)$(if $(notdir $(WORKPREFIX)),_)$(call substm,* : ?,@,$(TARGET)).icmd
#LOGFILE = $(if $(IMAGE_TYPE),$($(IMAGE_TYPE)_PREFIX)_$(call lcase,$(IMAGE_TYPE))_imaker,$(WORKDIR)/log/$(basename $(notdir $(CMDFILE)))).log
export LOGFILE ?= $(WORKDIR)/log/$(basename $(notdir $(CMDFILE))).log

BUILD_EMPTY = echo-q | Empty target, nothing to build.

CLEAN_IMAKERPRE = $(CLEAN_IMAKEREVAL) | del | "$(CMDFILE)" "$(IMAKER_VARXML)"
BUILD_IMAKERPRE =\
  $(call testnewapi,$(strip $(API_TEST))) |\
  $(if $(filter help% print-%,$(MAKECMDGOALS)),,$(if $(and $(IMAKER_VARXML),$(IMAKER_VARLIST)),\
    write | $(IMAKER_VARXML) | $(call def2str,$(IMAKER_XMLINFO))))

IMAKER_VARXML  = $(if $(IMAGE_TYPE),$($(IMAGE_TYPE)_PREFIX)_$(TARGET)_config.xml)
IMAKER_VARLIST = NAME WORKDIR

define IMAKER_XMLINFO
  <?xml version="1.0" encoding="utf-8"?>
  <build>
  \    <config type="$(MAKECMDGOALS)">
  $(foreach var,$(IMAKER_VARLIST),
  \        <set name="$(var)" value="$(call pstr2xml,$($(var)))"/>)
  \    </config>
  </build>
endef

BUILD_PRINTVAR = $(call peval,DPrint(1,\
  $(foreach var1,$(subst $(,), ,$(subst print-,,$(filter print-%,$(MAKECMDGOALS)))),\
    $(foreach var2,$(call filterwcard,$(var1),$(filter-out BUILD_PRINTVAR,$(filter $(word 1,$(call substm,* ? [, ,$(var1)))%,$(.VARIABLES)))),\
      $(call pquote,$(var2) = `$(call def2str,$($(var2)))$').qq(\n),))); return(q()))

IMAKER_EVAL = $(strip\
  $(foreach file,$(call getwords,$(value MKFILE_LIST)),$(eval __i_file := $(call restoreelem,$(file)))$(eval -include $(__i_file)))\
  $(foreach file,$(call getwords,$(value CPPFILE_LIST)),$(eval __i_file := $(call restoreelem,$(file)))$(call cppdef2var,$(__i_file),$(FEATVAR_IDIR)))\
  $(LANGUAGE_EVAL)\
  $(eval ITOOL_PATH := $(if $(ITOOL_PATH),$(ITOOL_PATH)$(,))$(ITOOL_DIR)$(,))\
  $(eval ITOOL_PATH := $(ITOOL_PATH)$(call iif,$(USE_IINTPRSIS),$(USE_IINTPRSIS)$(,))$(call iif,$(USE_IREADIMG),$(USE_IREADIMG)$(,))$(call iif,$(USE_IROMBLD),$(USE_IROMBLD)$(,)))\
  $(eval ITOOL_PATH := $(call pathconv,$(subst $(,),$(call iif,$(USE_UNIX),:,;),$(ITOOL_PATH)$(call upddrive,$(E32TOOLS))$(,)$(call upddrive,$(E32GCCBIN)))))\
  $(eval PATH := $(ITOOL_PATH)$(call iif,$(USE_UNIX),:,;)$(PATH)))

IMAKER_CMDARG  := $(value IMAKER_CMDARG)
IMAKER_MAKECMD := $(value IMAKER_MAKECMD)
IMAKER_PERLCMD :=
IMAKER_SUBMAKE :=

define IMAKER
  $(if $(and $(filter-out help-config,$(filter help-% print-%,$(MAKECMDGOALS))),$(IMAKER_PERLCMD)),-$(DONOTHING),
    $(if $(IMAKER_PERLCMD),,$(IMAKER_EVAL))
    $(eval __i_steps := $1)
    $(if $(findstring |,$(__i_steps)),
      $(eval IMAKER_PERLCMD := -)
      $(foreach target,$(call getwords,$(__i_steps)),$(if $(call restoreelem,$(target)),
        $(eval IMAKER_SUBMAKE += $(words $(IMAKER_SUBMAKE) x))
        $(subst $(MAKECMDGOALS) |,,$(IMAKER_MAKECMD) |)IMAKER_SUBMAKE="$(IMAKER_SUBMAKE)" $(call restoreelem,$(target)) $(call restwords,$(MAKECMDGOALS))$(\n))),
      $(eval __i_steps := $(if $(strip $(__i_steps)),$(foreach step,$(__i_steps),\
        $(eval __i_step := $(word 1,$(subst :, ,$(step))))$(eval __i_attrib := $(word 2,$(subst :, ,$(step))))\
        $(if $(call defined,STEPS_$(__i_step)),\
          $(foreach step2,$(STEPS_$(__i_step)),$(if $(__i_attrib),$(word 1,$(subst :, ,$(step2))):$(__i_attrib),$(step2))),\
          $(step))),EMPTY:b))
      $(eval __i_steps := IMAKERPRE:cbk$(call sstrip,$(foreach step,$(__i_steps),\
        $(eval __i_step := $(word 1,$(subst :, ,$(step))))$(eval __i_attrib := $(word 2,$(subst :, ,$(step))))\
        -$(__i_step):$(or $(findstring c,$(__i_attrib)),$(call iif,$(CLEAN),c))$(or $(findstring b,$(__i_attrib)),$(call iif,$(BUILD),b))\
        $(or $(findstring k,$(__i_attrib)),$(call iif,$(KEEPGOING),k)))))
      $(eval IMAKER_STEPS := $(__i_steps))
      $(eval __i_steps :=\
        $(if $(filter print-%,$(MAKECMDGOALS)),IMAKERPRE:cbk-PRINTVAR:b,\
          $(if $(filter-out help-config,$(filter help-%,$(MAKECMDGOALS))),IMAKERPRE:cbk-HELPDYNAMIC:b-HELP:b,$(__i_steps))))
      $(eval IMAKER_PERLCMD := $(PERL) -x $(IMAKER_TOOL)\
        --cmdfile "$(CMDFILE)"\
        $(if $(LOGFILE),--logfile "$(if $(word 2,$(IMAKER_SUBMAKE))$(IMAKER_PERLCMD)$(MAKE_RESTARTS),>>$(LOGFILE:>>%=%),$(LOGFILE))")\
        $(call iif,$(PRINTCMD),--printcmd)\
        --step "$(__i_steps)"\
        $(if $(VERBOSE),--verbose "$(call select,$(VERBOSE),debug,127,$(VERBOSE))")\
        $(if $(WORKDIR),--workdir "$(WORKDIR)"))
      -$(PERL) -Xe '$(if $(wildcard $(WORKDIR)),,use File::Path; eval { mkpath(q$(ichar)$(WORKDIR)$(ichar)) };)\
        open(ICMD, q$(ichar)>$(CMDFILE)$(ichar));\
        $(eval __i_submake := $(words $(IMAKER_SUBMAKE)))\
        print(ICMD $(foreach var,IMAKER_VERSION IMAKER_CMDARG IMAKER_MAKECMD IMAKER_PERLCMD $(if $(IMAKER_SUBMAKE),IMAKER_SUBMAKE|__i_submake)\
          IMAKER_EXITSHELL SHELL MAKE MAKEFLAGS MAKECMDGOALS $$@|@ MAKELEVEL MAKE_RESTARTS MAKEFILE_LIST .INCLUDE_DIRS FEATVAR_IDIR CPPFILE_LIST\
          EPOCROOT ITOOL_DIR IMAKER_DIR ITOOL_PATH PATH,\
          sprintf(qq(\# %-17s),q($(word 1,$(subst |, ,$(var))))).q$(ichar)= `$($(or $(word 2,$(subst |, ,$(var))),$(var)))$'$(ichar).qq(\n),));\
        close(ICMD)'
      $(foreach step,$(subst -, ,$(__i_steps)),\
        $(eval __i_step := $(word 1,$(subst :, ,$(step))))$(eval __i_attrib := $(subst $(__i_step),,$(step)))\
        $(eval __i_clean := $(findstring c,$(__i_attrib)))$(eval __i_build := $(findstring b,$(__i_attrib)))\
        -$(PERL) -Xe 'open(ICMD, q$(ichar)>>$(CMDFILE)$(ichar));\
          print(ICMD qq(\n)\
            $(if $(eval __i_imgtype := $(IMAGE_TYPE))$(__i_imgtype),,\
              $(eval IMAGE_TYPE += $(foreach type,CORE ROFS2 ROFS3 ROFS4 ROFS5 ROFS6 UDA,$(findstring $(type),$(step))))\
              $(eval IMAGE_TYPE := $(word 1,$(IMAGE_TYPE))))\
            $(if $(__i_clean),.q$(ichar)CLEAN_$(__i_step)=$(CLEAN_$(__i_step))$(ichar).qq(\n))\
            $(if $(__i_build),.q$(ichar)BUILD_$(__i_step)=$(BUILD_$(__i_step))$(ichar).qq(\n)));\
            $(eval IMAGE_TYPE := $(__i_imgtype))\
          close(ICMD)'$(\n))
      $(IMAKER_PERLCMD)
      $(eval IMAKER_CMDARG :=))
  )
endef


###############################################################################
# Test if old variables are in use

define API_TEST
#  OLD_VARIABLE1     NEW_VARIABLE1
#  OLD_VARIABLEn     NEW_VARIABLEn

  CUSTVARIANT_MKNAME  VARIANT_MKNAME
  CUSTVARIANT_CONFML  VARIANT_CONFML
  CUSTVARIANT_CONFCP  VARIANT_CONFCP
endef

testnewapi = $(if $1,\
  $(if $(call defined,$(word 1,$1)),\
    warning | 1 | ***************************************\n |\
    warning | 1 | Old-style variable found: $(word 1,$1) ($(origin $(word 1,$1)))\n |\
    warning | 1 | Instead$(,) start using $(word 2,$1)\n |)\
  $(call testnewapi,$(call restwords,3,$1)))


###############################################################################
# Targets

.PHONY: version clean

.SECONDEXPANSION:
version: ;@$(DONOTHING)

clean: CLEAN     = 1
clean: BUILD     = 0
clean: KEEPGOING = 1
clean: LOGFILE   =
clean:\
  ;@$(call IMAKER,$$(ALL.CLEAN.STEPS))

print-%: ;@$(call IMAKER)

step-% : ;@$(call IMAKER,$(subst -, ,$*))

#==============================================================================

include $(addprefix $(IMAKER_DIR)/imaker_,$(addsuffix .mk,help image minienv public tools version))

-include $(IMAKER_DIR)/imaker_extension.mk


###############################################################################
#

else
ifeq ($(__IMAKER_MK__),1)
__IMAKER_MK__ := 2

-include $(IMAKER_DIR)/imaker_extension.mk


###############################################################################
#

else
$(error Do not include imaker.mk, it is handled by iMaker!)
endif

endif # __IMAKER_MK__

# END OF IMAKER.MK
