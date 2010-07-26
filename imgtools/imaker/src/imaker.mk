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
findword    = $(and $1,$2,$(if $(filter $1,$(word 1,$2)),$(words $3 +),$(call findword,$1,$(call restwords,$2),$3 +)))
substm      = $(eval __i_str := $3)$(strip $(foreach w,$1,$(eval __i_str := $(subst $w,$2,$(__i_str)))))$(__i_str)
substs      = $(subst $(ichar)\,$2,$(subst $1,$2,$(subst $2,$(ichar)\,$3)))
quote       = $(call substs,\t,\\t,$(call substs,\n,\\n,$1))
quoteval    = $(subst \#,\\#,$(subst $$,$$$$,$1))
sstrip      = $(subst $( ),,$(strip $1))

strlen = $(call _str2chars,$1)$(words $(__i_str))
substr = $(call _str2chars,$3)$(subst $(ichar), ,$(subst $( ),,$(wordlist $1,$(if $2,$2,$(words $(__i_str))),$(__i_str))))
_str2chars = $(strip\
  $(eval __i_str := $(subst $( ),$(ichar),$1))\
  $(foreach c,$(charset)$(ichar),$(eval __i_str := $(subst $c,$c ,$(__i_str)))))

tr =\
  $(strip $(eval __i_tr := $(subst $( ),$(ichar),$3))\
  $(foreach c,$(join $(addsuffix :,$1),$2),\
    $(eval __i_tr := $(subst $(word 1,$(subst :, ,$c)),$(word 2,$(subst :, ,$c)),$(__i_tr)))))$(subst $(ichar),$( ),$(__i_tr))

pquote    = q$(pchar)$1$(pchar)
peval     = @PEVAL{$(call substs,|,\|,$1)}LAVEP@
phex      = $(call peval,Int2Hex($(subst 0x0x,0x,$1),$2))
pfilesize = $(call peval,-s $(call pquote,$1) || 0)
prepeat   = $(call peval,$(call pquote,$2) x ($1))
pstr2xml  = $(call peval,Str2Xml(Quote($(call pquote,$1))))
pmatch    = $(call peval,$(call pquote,$1) =~ m$(pchar)$(subst \\,\,$2)$(pchar)m $(if $3,$3,&& $$1 || q(???)))
pgrep     = $(call peval,\
  $(eval __i_notfound := $(call pquote,$(if $4,$4,???)))\
  open(F, $(call pquote,$1)) or return($(__i_notfound));\
  $$_ = $(if $2,Uni2Ascii)(join(q(), <F>));\
  $$_ = Quote($(if $3,m$(pchar)$3$(pchar)m ? $$1 : $(__i_notfound),$$_));\
  close(F); return($$_))

getlastdir  = $(foreach file,$1,$(notdir $(patsubst %/,%,$(file))))
upddrive    = $(if $2,$2,$(EPOCDRIVE))$(if $(filter %:,$(call substr,1,2,$1)),$(call substr,3,,$1),$1)
updoutdrive = $(call upddrive,$1,$(OUTDRIVE))
dir2inc     = $(foreach dir,$1,-I$(call upddrive,$(dir)))
findfile    = $(foreach file,$1,$(eval __i_ffile := $(call _findfile,$(addsuffix /$(file),$(if $2,$2,$(FEATVAR_IDIR)))))$(if $(__i_ffile),$(__i_ffile),$(if $3,,$(file))))
_findfile   = $(if $1,$(eval __i_ffile := $(wildcard $(word 1,$1)))$(if $(__i_ffile),$(__i_ffile),$(call _findfile,$(call restwords,$1))))
isabspath   = $(if $(filter / \,$(if $(filter %:,$(call substr,1,2,$1)),$(call substr,3,3,$1),$(call substr,1,1,$1))),$1)
includechk  = $(foreach file,$(subst \ ,$(ichar),$1),\
  $(if $(wildcard $(subst $(ichar),\ ,$(file))),$(eval include $(subst $(ichar),\ ,$(file))),\
    $(error File `$(subst $(ichar), ,$(file))' not found.$(\n)MAKEFILE_LIST =$(MAKEFILE_LIST))))

filterwcard = $(shell $(PERL) -Xe '\
  (my $$re = q$(ichar)$1$(ichar)) =~ s/(.)/{q(*)=>q(.*),q(?)=>q(.),q([)=>q([),q(])=>q(])}->{$$1} || qq(\Q$$1\E)/ge;\
    print(map(qq( $$_), sort({lc($$a) cmp lc($$b)} grep(/^$$re$$/, split(/\s+/, q$(ichar)$2$(ichar))))))')

cppdef2var = $(if $(wildcard $1),\
  $(foreach assign,$(call getwords,$(shell $(CPP) -nostdinc -undef -dM $(call dir2inc,$2) $(call upddrive,$1) |\
    $(PERL) -Xne $(call iif,$(USE_UNIX),',")print(qq($$1?=) . ($$2 eq q() ? 1 : $$2) . q(|))\
      if /^\s*\#define\s+($(or $(call sstrip,$3),\S+))\s*(.*?)\s*$$/$(call iif,$(USE_UNIX),',"))),\
        $(eval $(call restoreelem,$(assign)))),\
  $(eval include $1))

mac2cppdef = $(foreach def,$1,$(if\
  $(filter -D% --D%,$(def)),$(eval __i_def := $(subst =, ,$(patsubst $(if $(filter --D%,$(def)),-)-D%,%,$(def))))\
    $(\n)$(if $(filter -D%,$(def)),\#undef  $(word 1,$(__i_def))$(\n)\#define,define ) $(word 1,$(__i_def)) $(word 2,$(__i_def)),\
  $(if $(filter -U%,$(def)),$(\n)\#undef $(patsubst -U%,%,$(def)))))

USE_UNIX    := $(if $(findstring cmd.exe,$(call lcase,$(SHELL)))$(findstring mingw,$(call lcase,$(MAKE))),0,1)
DONOTHING   := $(call iif,$(USE_UNIX),\#,rem)
NULL        := $(call iif,$(USE_UNIX),/dev/null,nul)
PATHSEPCHAR := $(call iif,$(USE_UNIX),:,;)
CURDIR      := $(CURDIR:/=/.)
EPOCDRIVE   := $(or $(filter %:,$(call substr,1,2,$(EPOCROOT))),$(filter %:,$(call substr,1,2,$(CURDIR))))
EPOC_ROOT   := $(patsubst %/,%,$(subst \,/,$(if $(filter %:,$(call substr,1,2,$(EPOCROOT))),,$(EPOCDRIVE))$(EPOCROOT)))
EPOC32      := $(EPOC_ROOT)/epoc32
E32ROM      := $(EPOC32)/rom
E32ROMCFG   := $(E32ROM)/config
E32ROMINC   := $(E32ROM)/include
E32ROMBLD   := $(EPOC32)/rombuild
E32INC      := $(EPOC32)/include
E32INCCFG   := $(E32INC)/config
E32TOOLS    := $(EPOC32)/tools
E32GCCBIN   := $(EPOC32)/gcc/bin
E32DATA     := $(EPOC32)/data
E32DATAZ    := $(E32DATA)/z

IMAKER_TOOL     := $(IMAKER_DIR)/imaker.pl
IMAKER_CONFMK    =
IMAKER_DEFAULTMK = $(call findfile,image_conf_default.mk,,1)

CPP    ?= cpp
PYTHON ?= python

YEAR  := $(call substr,1,4,$(TIMESTAMP))
YEAR2 := $(call substr,3,4,$(TIMESTAMP))
MONTH := $(call substr,5,6,$(TIMESTAMP))
DAY   := $(call substr,7,8,$(TIMESTAMP))
WEEK  := $(call substr,15,,$(TIMESTAMP))

.DEFAULT_GOAL = help
DEFAULT_GOALS =

TARGET      = $(word 1,$(subst [, [,$(MAKECMDGOALS)))
TARGETNAME  = $(word 1,$(subst -, ,$(TARGET)))
TARGETID    = $(subst $( ),_,$(call restwords,$(subst _, ,$(TARGETNAME))))
TARGETID1   = $(word 2,$(subst _, ,$(TARGETNAME)))
TARGETID2   = $(word 3,$(subst _, ,$(TARGETNAME)))
TARGETID2-  = $(subst $( ),_,$(call restwords,3,$(subst _, ,$(TARGETNAME))))
TARGETID3   = $(word 4,$(subst _, ,$(TARGETNAME)))
TARGETID3-  = $(subst $( ),_,$(call restwords,4,$(subst _, ,$(TARGETNAME))))
TARGETEXT   = $(addprefix -,$(subst $( ),-,$(call restwords,$(subst -, ,$(TARGET)))))
TARGETEXT2  = $(word 3,$(subst -, ,$(TARGET)))
TARGETEXT2- = $(addprefix -,$(subst $( ),-,$(call restwords,3,$(subst -, ,$(TARGET)))))
TARGETEXT3  = $(word 4,$(subst -, ,$(TARGET)))
TARGETEXT3- = $(addprefix -,$(subst $( ),-,$(call restwords,4,$(subst -, ,$(TARGET)))))

TOPTARGET     = $(TARGET)
TOPTARGETNAME = $(word 1,$(subst -, ,$(TOPTARGET)))
TOPTARGETID   = $(subst $( ),_,$(call restwords,$(subst _, ,$(TOPTARGETNAME))))
TOPTARGETEXT  = $(addprefix -,$(subst $( ),-,$(call restwords,$(subst -, ,$(TOPTARGET)))))

TARGET_EXPORT = TOPTARGET? IMAGE_TYPE

CLEAN     = 1
BUILD     = 1
FILTERCMD =
KEEPGOING = 0
KEEPTEMP  = 0
PRINTCMD  = 0
SKIPPRE   = 0
SKIPBLD   = 0
SKIPPOST  = 0
VERBOSE   = 1

NAME       = imaker
WORKDIR    = $(CURDIR)
WORKTMPDIR = $($(or $(addsuffix _,$(IMAGE_TYPE)),WORK)DIR)/temp# To be removed!

OUTDIR     = $(WORKDIR)
OUTPREFIX  = $(OUTDIR)/$(NAME)# Temporary?
OUTDRIVE   = $(or $(filter %:,$(call substr,1,2,$(OUTDIR))),$(filter %:,$(call substr,1,2,$(CURDIR))))
OUTTMPDIR  = $($(or $(addsuffix _,$(IMAGE_TYPE)),OUT)DIR)/temp

ALL.CLEAN.STEPS = $(ALL.IMAGE.STEPS)


###############################################################################
#

LOGFILE = $($(or $(addsuffix _,$(IMAGE_TYPE)),WORK)PREFIX)_imaker_$(call substm,* / : ? \,@,$(TARGET)).log

BUILD_EMPTY = echo-q | Empty target, nothing to build.

BUILD_IMAKERPRE =\
  $(BUILD_TOOLSET) |\
  logfile   | "$(LOGFILE)" |\
  filtercmd | $(FILTERCMD)

CLEAN_IMAKERPOST = $(call iif,$(KEEPTEMP),,deldir | "$(OUTTMPDIR)" |) del | "$(IMAKER_VARXML)"
BUILD_IMAKERPOST = $(and $(subst IMAKERPRE EMPTY IMAKERPOST,,$(IMAKER_STEPS)),$(IMAKER_VARXML),$(IMAKER_VARLIST),\
  write | "$(IMAKER_VARXML)" | $(call def2str,$(IMAKER_XMLINFO))\n)

IMAKER_VARXML  = $(if $(IMAGE_TYPE),$($(IMAGE_TYPE)_PREFIX)_$(TARGET).iconfig.xml)
IMAKER_VARLIST = PRODUCT_NAME TYPE\
  $(and $(IMAGE_TYPE),$(filter $(call lcase,$(IMAGE_TYPE) $(IMAGE_TYPE))-%,$@),\
    $(addprefix $(IMAGE_TYPE)_,NAME ID VERSION DIR IMG))

define IMAKER_XMLINFO
  <?xml version="1.0" encoding="utf-8"?>
  <build>
  \    <config type="$(MAKECMDGOALS)">
  $(foreach var,$(IMAKER_VARLIST),
  \        <set name="$(var)" value="$(call pstr2xml,$($(var)))"/>)
  \    </config>
  </build>
endef

IMAKER_EVAL = $(strip\
  $(LANGUAGE_EVAL)\
  $(foreach file,$(call getwords,$(value CPPFILE_LIST)),$(eval __i_file := $(call restoreelem,$(file)))$(call cppdef2var,$(__i_file),$(FEATVAR_IDIR),$(CPPFILE_FILTER))))

IMAKER_EXPORT   = PATH
IMAKER_PRINTVAR = 17 $$@|@ IMAKER_STEPS IMAKER_MKLEVEL IMAKER_MKRESTARTS MAKELEVEL MAKE_RESTARTS MAKEFILE_LIST CPPFILE_LIST FEATVAR_IDIR

__i_evaled :=
__i_tgtind :=

define IMAKER
  $(if $(and $(filter-out help-config,$(filter help-% print-%,$(MAKECMDGOALS))),$(__i_evaled)),,
    $(info #iMaker$(ichar)BEGIN)
    $(if $(__i_evaled),,$(IMAKER_EVAL))
    $(eval __i_evaled := 1)
    $(eval __i_steps := $(if $(MAKECMDGOALS),$1,$(or\
      $(if $(DEFAULT_GOALS),$(if $(PRODUCT_NAME),,$(TARGET_PRODUCT)) $(DEFAULT_GOALS)),$(filter help,$(.DEFAULT_GOAL)))))
    $(if $(call restoreelem,$(call getwords,$(__i_steps))),,$(eval __i_steps :=))
    $(if $(__i_tgtind),$(eval __i_steps := $(call getelem,$(__i_tgtind),$(__i_steps))))
    $(eval __i_tgts := $(subst $(__i_steps),,$(call ucase,$(__i_steps))))
    $(if $(or $(filter-out help-config,$(filter help-% print-%,$(MAKECMDGOALS))),$(call not,$(__i_tgts))),
      $(eval IMAKER_STEPS := $(if $(filter help% print-%,$(TARGET))$(__i_tgts),,IMAKERPRE )$(or $(strip\
        $(eval __i_ind := $(call findword,RESTART,$(__i_steps)))$(if $(__i_ind),$(call iif,$(IMAKER_MKRESTARTS),\
          $(call restwords,$(call restwords,$(__i_ind),$(__i_steps))),$(wordlist 1,$(__i_ind),$(__i_steps))),$(__i_steps))),EMPTY))
      $(if $(filter-out IMAKERPRE,$(word 1,$(IMAKER_STEPS)))$(filter RESTART,$(lastword $(IMAKER_STEPS))),,
        $(eval IMAKER_STEPS += IMAKERPOST))
      $(eval __i_steps := $(if $(filter print-%,$(MAKECMDGOALS)),PRINTVAR,\
        $(if $(filter-out help-config,$(filter help-%,$(MAKECMDGOALS))),HELP,$(IMAKER_STEPS))))
      ,
      $(if $(and $(__i_tgts),$(__i_tgtind)),$(eval IMAKER_STEPS := $(__i_steps)),
        $(eval __i_ind :=)
        $(eval IMAKER_STEPS :=)
        $(foreach step,$(call getwords,$(__i_steps)),
          $(eval __i_ind += +)
          $(eval __i_steps := $(call restoreelem,$(step)))
          $(if $(__i_steps),$(eval IMAKER_STEPS += $(if $(IMAKER_STEPS),|)\
            $(if $(subst $(__i_steps),,$(call ucase,$(__i_steps))),$(__i_steps),$(TARGETNAME)[$(words $(__i_ind))])))))
      $(eval __i_steps :=)
    )
    $(foreach var,VERBOSE IMAGE_TYPE KEEPGOING PRINTCMD,$(info #iMaker$(ichar)$(var)=$($(var))))
    $(foreach var,$(sort $(IMAKER_EXPORT)),$(info #iMaker$(ichar)env $(var)=$($(var))))
    $(foreach var,$(TARGET_EXPORT),$(info #iMaker$(ichar)var $(var)=$($(patsubst %?,%,$(or $(word 2,$(subst :, ,$(var))),$(var))))))
    $(foreach var,$(call restwords,$(IMAKER_PRINTVAR)),$(info #iMaker$(ichar)print $(word 1,$(IMAKER_PRINTVAR))\
      $(word 1,$(subst |, ,$(var)))=$($(or $(word 2,$(subst |, ,$(var))),$(var)))))
    $(info #iMaker$(ichar)STEPS=$(or $(__i_steps),target:$(IMAKER_STEPS)))
    $(foreach step,$(__i_steps),
      $(if $(call defined,INIT_$(step)),$(info #iMaker$(ichar)INIT_$(step)=$(INIT_$(step))))
      $(if $(call true,$(CLEAN)),$(info #iMaker$(ichar)CLEAN_$(step)=$(CLEAN_$(step))))
      $(if $(call true,$(BUILD)),
        $(info #iMaker$(ichar)BUILD_$(step)=$(BUILD_$(step)))
        $(if $(REPORT_$(step)),$(info #iMaker$(ichar)REPORT_$(step)=$(REPORT_$(step)))))
    )
    $(info #iMaker$(ichar)END)
  )-@$(DONOTHING)
endef


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

step-%: ;@$(call IMAKER,$(subst -, ,$*))

#==============================================================================

$(call includechk,$(addprefix $(IMAKER_DIR)/imaker_,$(addsuffix .mk,help image minienv tools version)))
include $(wildcard $(IMAKER_DIR)/imaker_extension.mk)
include $(wildcard $(IMAKER_EXPORTMK))

$(call includechk,$(LANGPACK_SYSLANGMK))
$(call includechk,$(IMAKER_DEFAULTMK))
$(call includechk,$(IMAKER_CONFMK))
$(call includechk,$(BUILD_INFOMK))
$(call includechk,$(BUILD_NAMEMK))
$(call includechk,$(LANGPACK_MK))
$(call includechk,$(VARIANT_MK))
$(call includechk,$(call select,$(USE_CONE),mk,$(if $(filter cone-pre,$(TARGET)),,$(subst $( ),\ ,$(CONE_MK)))))

.DEFAULT_GOAL := $(if $(DEFAULT_GOALS),help,$(.DEFAULT_GOAL))

%-dir: FILTERCMD = ^cd\|mkcd\|mkdir$$
%-dir: $$* ;

$(foreach ind,1 2 3 4 5 6 7 8 9,\
  $(eval %[$(ind)]: __i_tgtind = $(ind))\
  $(eval %[$(ind)]: $$$$* ;))

include $(wildcard $(IMAKER_DIR)/imaker_extension.mk)
include $(wildcard $(IMAKER_EXPORTMK))

$(sort $(MAKEFILE_LIST)): ;


###############################################################################
#

else
$(error Do not include imaker.mk, it is handled by iMaker!)

endif # __IMAKER_MK__


# END OF IMAKER.MK
