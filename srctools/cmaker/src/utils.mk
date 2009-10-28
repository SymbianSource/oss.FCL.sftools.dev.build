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
# Description:
# cmaker utils, stack functions (push,pop,popout,peek,length).
# print function to echo data on several lines.
#

ichar := 
pchar := 

comma := ,
space :=
space +=
squot := '\''

[A-Z] := A B C D E F G H I J K L M N O P Q R S T U V W X Y Z #
[a-z] := a b c d e f g h i j k l m n o p q r s t u v w x y z #
[0-9] := 0 1 2 3 4 5 6 7 8 9 #

charset := $([A-Z])$([a-z])$([0-9])! " \# $ % & ' ( ) * + , - . / : ; < = > ? @ [ \ ] ^ _ ` { | } ~

# substr(startIndex, endIndex,text)
substr = \
  $(strip $(eval __i_str := $(subst $(space),$(ichar),$3)) \
  $(foreach c,$(charset) $(ichar),$(eval __i_str := $(subst $c,$c ,$(__i_str)))) \
  )$(subst $(ichar), ,$(subst $(space),,$(wordlist $1,$2,$(__i_str))))


tr = \
  $(strip $(eval __i_tr := $3)    \
  $(foreach c,                    \
    $(join $(addsuffix :,$1),$2), \
    $(eval __i_tr := $(subst $(word 1,$(subst :, ,$c)),$(word 2,$(subst :, ,$c)),$(__i_tr))))$(__i_tr))

lcase       = $(call tr,$([A-Z]),$([a-z]),$1)
ucase       = $(call tr,$([a-z]),$([A-Z]),$1)


# Remove Cygwin from PATH if EXCLCYGWIN is true
PATH        := $(shell $(PERL) -e 'print(q—$(EXCLCYGWIN)— ? join(";",grep(!/\\cygwin\\/i,split(/;+/,$$ENV{PATH}))) : $$ENV{PATH})')

# remove_trail(dir)
# remove the trailing backslash
define remove_trail
$(patsubst %/,%,$(patsubst %\,%,$1))
endef

MAKEFILEDIR = $(dir $(call peek,MAKEFILE_STACK))

#Global variable for all export directories
EXPORTDIRECTORIES ?= 

#println(line)
# function to print one line of data inside other defines
# param line the data line
define println
	@echo $1

endef

define pop2
  $(word 1,$(1)) $(word 2,$(1))
endef

# tail(n, list)
#
# param n is the starting word
# param list is the input data list
# returns the tail from list starting from word n
define tail
  $(wordlist $1,$(words $2),$2)
endef

# Adds the directory to the global export directories 
# list if it is not already existing in it
define add_export_dir
  $(if $(filter $1,$(EXPORTDIRECTORIES)),,\
    $(eval EXPORTDIRECTORIES+=$1)\
    $(eval $1 : ; @$(PERL) -e 'use File::Path; mkpath(q($$@))'))
endef

# addeval(list)
#
# Adds the items from the list as dependencies 
# List format from to from to ..
# param list is the input data list
define addeval
  $(if $(strip $1),\
    $(if $(PHONY_ACT),$(eval .PHONY : $(word 2,$1)))\
    $(eval $(word 1,$1) : $(call getdir, $(dir $(word 2,$1))))\
    $(eval $(word 2,$1) : $(word 1,$1) ; $$(FUNCTION))\
    $(eval $2 :: $(word 2,$1))\
    $(call add_export_dir,$(call getdir,$(dir $(word 2,$1))))\
    $(call addeval, $(call tail,3,$1),$2))
endef

# getdir(dir)
# returns a directory entry in lower case without trailing slash
define getdir
$(call remove_trail,$(strip $(call lcase,$1)))
endef
#$(call remove_trail,

# expand a single source target definition
# param source(s), the source file or files (wildcard)
# param target target file or folder
# E.g. 1. src/*.h /epoc32/config/
#      2. src/aa.h /epoc32/config/bb.h
define expand_wilds
  $(if $(notdir $2),$(if $(filter-out 0 1,$(words $(wildcard $1))),$(error a file target must have a single source file, in $2,$1)) )\
  $(if $(notdir $2),$(eval TARGET=$$2),$(eval TARGET=$$2$$(notdir $$(source))))\
  $(foreach source,$(wildcard $1),$(source)  $(TARGET)) 
endef

# expand_all_wilds(inputlist, concatlist)
#
# expands all wildcard entries from the input list and appends them 
# to the concatlist
# param intputlist is the input data list (from/*.* to from to ..)
# param concatlist is the list where the expanded data is appended
# returns a full concatenated list
define expand_all_wilds
  $(if $(strip $1),\
    $(call expand_all_wilds,\
      $(call tail,3,$1),\
      $2 $(call expand_wilds,$(word 1,$1),$(word 2,$1))\
    ),$2\
  )
endef

# addfiles(inputlist, dependant_target)
#
# adds the export targets and dependancies 
# param intputlist is the input data list (from/*.* to from to ..)
# param dependant_target is the target which will have a dependency to these dynamic targets
define addfiles
  $(call addeval,$(subst /,\,$(call expand_all_wilds,$1,)),$2)
endef


# push(list, value)
#
# adds the value to the given list
# param intput list where the data is appended
# param value that is added
define push
  $(if $(findstring $2,$($1)),$(error ERROR: Item $2 already exists in the list!!!))\
  $(eval $1 += $2)
endef

# pop(list)
#
# pops out the value from the given list
# param list where the data is popped out
# returns the value from the list
define pop
$(strip $(eval value=$(lastword $($1)))\
$(eval $1:=$(filter-out $(value),$($1)))\
$(value))
endef

# popout(list)
#
# pops out the last item from the given list
# param list where the data is popped out
# returns nothing
define popout
$(eval value=$(lastword $($1)))\
$(eval $1:=$(filter-out $(value),$($1)))
endef

# peek(list)
#
# peek the last element from the list without popping it out
# param list which is peaked
# returns the value of the last element of the list
define peek
$(lastword $($1))
endef

# length(list)
#
# returns the lenght of the stack
# param list which is length is queried
# returns the lenght as integer value 
define length
$(words $($1))
endef
