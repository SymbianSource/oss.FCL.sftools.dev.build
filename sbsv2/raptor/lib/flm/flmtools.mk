#
# Copyright (c) 2009-2010 Nokia Corporation and/or its subsidiary(-ies).
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
# Description: 
# Tools for use in FLMs - common macros and variables
#

ifeq ($(FLMTOOLS.MK),)
FLMTOOLS.MK:=included

CHAR_COMMA:=,
CHAR_SEMIC:=;
CHAR_COLON:=:
CHAR_BLANK:=
#the BLANK BLANK trick saves us from clever text editrors that remove spaces at the end of a line
CHAR_SPACE:=$(BLANK) $(BLANK)
CHAR_DQUOTE:="
CHAR_QUOTE:='
CHAR_LBRACKET:=(
CHAR_RBRACKET:=)
CHAR_DOLLAR:=$

#'" # This comment makes syntax highlighting work again. Leave it here please!

# A macro to ensure that the shell does not 
# interpret brackets in a command
define shEscapeBrackets
$(subst $(CHAR_LBRACKET),\$(CHAR_LBRACKET),$(subst $(CHAR_RBRACKET),\$(CHAR_RBRACKET),$(1)))
endef

# A macro to protect quotes from shell expansion
define shEscapeQuotes
$(subst $(CHAR_QUOTE),\$(CHAR_QUOTE),$(subst $(CHAR_DQUOTE),\$(CHAR_DQUOTE),$(1)))
endef

# Protect against shell expansion
define shEscape
$(call shEscapeBrackets,$(call shEscapeQuotes,$(1)))
endef

# A macro to escape spaces for use in rule targets or dependencies
define ruleEscape
$(subst $(CHAR_SPACE),\$(CHAR_SPACE),$(1))
endef

# A macro for turning a list into a concatenated string
# 1st parameter is the separator to use, second is the list
# e.g. $(call concat,:,/sbin /usr/sbin /usr/local/sbin /bin /usr/bin /usr/local/bin)
# would create the string
#   /sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin
# It has to be recursive to manage to create a string from a list
define concat
$(if $(word 2,$(2)),$(firstword $(2))$(1)$(call concat,$(1),$(wordlist 2,$(words $(2)),$(2))),$(2))
endef

# A macro for converting a string to lowercase
lowercase_TABLE:=A,a B,b C,c D,d E,e F,f G,g H,h I,i J,j K,k L,l M,m N,n O,o P,p Q,q R,r S,s T,t U,u V,v W,w X,x Y,y Z,z

define lowercase_internal
$(if $1,$$(subst $(firstword $1),$(call lowercase_internal,$(wordlist 2,$(words $1),$1),$2)),$2)
endef

define lowercase
$(eval lowercase_RESULT:=$(call lowercase_internal,$(lowercase_TABLE),$1))$(lowercase_RESULT)
endef

# A macro for converting a string to uppercase
uppercase_TABLE:=a,A b,B c,C d,D e,E f,F g,G h,H i,I j,J k,K l,L m,M n,N o,O p,P q,Q r,R s,S t,T u,U v,V w,W x,X y,Y z,Z

define uppercase_internal
$(if $1,$$(subst $(firstword $1),$(call uppercase_internal,$(wordlist 2,$(words $1),$1),$2)),$2)
endef

define uppercase
$(eval uppercase_RESULT:=$(call uppercase_internal,$(uppercase_TABLE),$1))$(uppercase_RESULT)
endef

# A macro for removing duplicate tokens from a list 
# whilst retaining the list's order
define uniq
$(if $(1),\
$(firstword $(1))$(call uniq,$(filter-out $(firstword $(1)),$(wordlist 2,$(words $(1)),$(1))))\
,)
endef

# A macro for enclosing all list elements in some kind of quote or bracket
define enclose
$(foreach ITEM,$(2),$(1)$(ITEM)$(1))
endef

# A macro enclosing all list elements in double quotes and removing escapes
define dblquote
$(subst \,,$(call enclose,$(CHAR_DQUOTE),$(1)))
endef

# A macro enclosing a single item in double quotes, so that spaces can be quoted
define dblquoteitem
$(if $(1),$(CHAR_DQUOTE)$(1)$(CHAR_DQUOTE),)
endef

# A macro to add a prefix to a list of items, while putting quotes around each
# item so prefixed, to allow spaces in the prefix.
define addquotedprefix
$(addprefix $(CHAR_DQUOTE)$(1),$(addsuffix $(CHAR_DQUOTE),$(2)))
endef

# A macro enclosing all list elements in single quotes and prepending a string
# basically to turn a list like:
#    LINUX TOOLS EXP=_declspec(export) NODEBUG
# into:
#    -D'LINUX' -D'TOOLS' -D'EXP=_declspec(export)' -DNODEBUG
define makemacrodef
$(strip $(patsubst %,$1'%',$2))
endef

# Make a (filename) string safe for use as a variable name
define sanitise
$(subst /,_,$(subst :,_,$(1)))
endef

# A variation on several macros implemented directly in FLMs, this takes a filename and a list
# of "words" and pumps groups of 10 words at a time into the file.  Its main use is the creation
# of command/response files for tools that need to avoid blowing command line length limits
# when referencing long lists of absolutely pathed files.
define groupin10infile
	$(if $2,@echo -e $(foreach L,$(wordlist 1,10,$2),"$(L)\\n") >>$1,)
	$(if $2,$(call groupin10infile,$1,$(wordlist 11,$(words $2),$2)),@true)
endef

## DEBUGGING Macros ######################################

# A macro to help with debugging FLMs by printing out variables specified in the FLMDEBUG variable
define flmdebug
$(if $(FLMDEBUG),@echo -e "<flmdebug>\\n $(foreach VAR,$(FLMDEBUG),$(VAR):=$($(VAR))\\n)</flmdebug>",)
endef

define flmdebug2
flmdebug2_OUT:=$(if $(FLMDEBUG),$(shell echo -e "<flmdebug>\\n $(foreach VAR,$(FLMDEBUG),$(VAR):=$($(VAR))\\n)</flmdebug>" 1>&2),)
endef

## Path handling tools ###################################

ifeq ($(OSTYPE),cygwin)

SPACESLASH:=$(CHAR_SPACE)/
SPACESLASH2:=$(CHAR_SPACE)\/
SPACEDSLASH:=$(CHAR_SPACE)//
# How lists of directories are separated on this OS:
DIRSEP:=$(CHAR_SEMIC)

define slashprotect
$(subst $(SPACESLASH),$(SPACESLASH2),$(1))
endef

define pathprep
$(subst $(SPACESLASH),$(SPACEDSLASH),$(1))
endef

else

# How lists of directories are separated on this OS:
DIRSEP:=$(CHAR_COLON)

define slashprotect
$(1)
endef

define pathprep
$(1)
endef

endif

# Path separator (always / in make)
PATHSEP=/

## Source to object file mapping #########################

## Converting a list of source files to a list of object files without altering their
## relative order.  Also deals with multiple file types mapping to the same object type
## e.g. .CPP and .cpp and .c++ all map to .o
define allsuffixsubst_internal
$(if $1,$$(patsubst %$(firstword $1),%$2,$(call allsuffixsubst_internal,$(wordlist 2,$(words $1),$1),$2,$3)),$3)
endef

# $1 - the list of suffixes to replace
# $2 - the suffix to replace them with
# $3 - the list of strings to perform the replacement on
define allsuffixsubst
$(eval allsuffixsubst_RESULT:=$(call allsuffixsubst_internal,$1,$2,$3))$(allsuffixsubst_RESULT)
endef

## extractfilesoftype ##
# $(1) is the list of types to extract e.g. cpp cxx CPP
# $(2) is the list of files to select from
define extractfilesoftype
$(foreach EXT,$(1),$(filter %$(EXT),$(2)))
endef

## extractandmap ##
# $(1) is the list of types e.g. cpp cxx CPP
# $(2) is the extension to map to e.g. .o or .ARMV5.lst oe _.cpp
# $(3) is the list of files to select from
# This functon turns a list like 'fred.cpp bob.c++' into 'fred.o bob.o'
define extractandmap
$(foreach EXT,$(1),$(patsubst %$(EXT),%$(2),$(filter %$(EXT),$(3))))
endef

## relocatefiles ##
# $(1) directory to relocate them in
# $(2) list of files to relocate
define relocatefiles
$(patsubst %,$(1)/%,$(notdir $(2)))
endef


## Get stack handling code (for calls to FLMS which don't destroy variables)
include $(FLMHOME)/stack.mk

## Allow flm rules to be tagged and enable FORCESUCCESS feature etc
include $(FLMHOME)/taggedrules.mk

## Get boolean tools e.g. that implement the equals macro.
include $(FLMHOME)/booleanlogic.mk

## Macros for writing recipes without needing to know eval
#
# an ordinary recipe, for example,
#
# $(call raptor_recipe,name,$(TARGET),$(PREREQUISITES),$(COMMAND))
#
define raptor_recipe
$(eval $2: $3
	$(call startrule,$1) $4 $(call endrule,$1)
)
endef
#
# a phony recipe (double colon rule). Making a separate macro with an uglier
# name will hopefully discourage people from using this unless they need to,
# for example,
#
# $(call raptor_phony_recipe,name,ALL,,$(COMMAND))
#
define raptor_phony_recipe
$(eval $2:: $3
	$(call startrule,$1) $4 $(call endrule,$1)
)
endef

################################################################################
## Test code to allow this makefile fragment to be tested in a standalone manner
##
## example:
##   FLMHOME=./ make -f flmtools.mk  STANDALONE_TEST=1 
##

ifneq ($(STANDALONE_TEST),)

test::
	@echo "macros"
	test  "$(call concat,:,CON CAT EN ATED)" == "CON:CAT:EN:ATED" 
	test  "$(call enclose,$(CHAR_QUOTE),THESE WORDS ARE QUOTED)" == "'THESE' 'WORDS' 'ARE' 'QUOTED'" 
	echo $(SHELL)
	test  '$(call dblquote,THESE WORDS ARE DOUBLEQUOTED)' == '"THESE" "WORDS" "ARE" "DOUBLEQUOTED"'
	echo  $(call dqnp,/c/fred /d/alice /blah/blah)
	@echo ""


test::
	@echo lowercase macro
	test '$(call lowercase,ABCDEFGHIJKLMNOPQRSTUVWXYZ AA BB CC)' == 'abcdefghijklmnopqrstuvwxyz aa bb cc'

define lowercase_internal
$(if $1,$$(subst $(firstword $1),$(call lowercase_internal,$(wordlist 2,$(words $1),$1),$2)),$2)
endef

define lowercase
$(eval lowercase_RESULT:=$(call lowercase_internal,$(lowercase_TABLE),$1))$(lowercase_RESULT)
endef

	test '$(call pathprep,--apcs /inter)' == '--apcs //inter'
	
test::
	@echo "pathprep macro"
	test '$(call pathprep,--apcs /inter)' == '--apcs //inter'
	test '$(call pathprep,blah theone/or/theother)' == 'blah theone/or/theother'

endif
endif

