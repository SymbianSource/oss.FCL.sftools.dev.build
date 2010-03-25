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
# Description: 
#
#
# Some makefile helper functionality to simplify SDF to Makefile conversion.  
#

# Special reserved character (ASCII 31)
ichar := 
comma := ,
exclamation := !
empty :=
space := $(empty) $(empty)
squot := '\''

getwords     = $(subst |, ,$(subst \|,$(ichar):,$(subst $(space),$(ichar)_,$1)))
restoreelem  = $(strip $(subst $(ichar):,\|,$(subst $(ichar)_, ,$1)))
getelem      = $(call restoreelem,$(word $1,$(call getwords,$2)))
true         = $(if $(filter-out 0,$(subst 0,0 ,$1)),1)
false        = $(if $(call true,$1),,1)
not          = $(if $1,,$1)
iif          = $(if $(call true,$1),$2,$3)
equal        = $(if $(strip $(subst $(strip $1),,$2)$(subst $(strip $2),,$1)),,1)

# helpers
get_unit_name=$(call getelem,1,$(UNIT_$1))
get_unit_path=$(call getelem,2,$(UNIT_$1))
get_unit_filters=$(call getelem,3,$(UNIT_$1))


# unit filtering
is-negate-filter=$(if $(call equal,$1,$(subst $(exclamation),,$1)),,1)
hasword=$(call equal,$1,$(filter $1,$2))
hasnotword=$(if $(call hasword,$1,$2),,1)
filter-in-unit=$(if $(strip $(foreach filter,$(call get_unit_filters,$1),$(if $(call is-negate-filter,$(filter)),$(call hasword,$(subst !,,$(filter)),$(FILTERS)),$(call hasnotword,$(filter),$(FILTERS))))),,1)
filter-unitlist=$(foreach unit,$1,$(if $(call filter-in-unit,$(unit)),$(unit)))

# helper to execute sequentially the targets rather than in parallel
define serialize
-@$(MAKE) -k $1

endef

# debug functionnality
define echo-string
@echo $1

endef

define show-filter-unitlist
$(foreach unit,$1,$(call echo-string,$(call get_unit_name,$(unit)): $(call get_unit_filters,$(unit)): $(if $(call filter-in-unit,$(unit)),IN,OUT)))
endef


MAKEFILE_CMD_LINE:=$(foreach makefile,$(MAKEFILE_LIST), -f $(makefile))

%/abld.bat : %/bld.inf
	@echo === automatic == $*
	@echo -- bldmake_bldfiles-v-k
	-@perl -e "print '++ Started at '.localtime().\"\n\""
	-@python -c "import time; print '+++ HiRes Start ',time.time();"
	@echo Error 42 abld command issued when bldmake was not done first
	@echo Error 42 This is a serious error in your build configuration and must be fixed.
	@echo Error 42 In this build the error has been fixed automatically.
	cd $* && bldmake bldfiles -v -k
	-@python -c "import time; print '+++ HiRes End ',time.time();"
	-@perl -e "print '++ Finished at '.localtime().\"\n\""

