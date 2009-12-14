#
# Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# operators for boolean logic, including a case 
# sensitive equality operator
#


define not
$(if $1,,1)
endef

define xor
$(and $(or $1,$2),$(call not,$1,$2))
endef

define equal
$(if $(1:$(2)=),,$(if $(2:$(1)=),,1))
endef

define equal_debug
$(info equal $1 $2 )$(if $(1:$(2)=),,$(if $(2:$(1)=),,1))
endef

# $(call isoneof,fred, alice bob james fred joe)  # returns 1
define isoneof
$(if $2,$(or $(call equal,$1,$(word 1,$2)),$(call isoneof,$(1),$(wordlist 2,$(words $(2)),$(2)))),)
endef

define isoneof_debug
$(info one:$1 LIST: $2 nextCAR: $(word 1,$2) nextCDR: $(wordlist 2,$(words $2),$2))$(if $2,$(or $(call equal,$1,$(word 1,$2)),$(call isoneof,$(1),$(wordlist 2,$(words $(2)),$(2)))),)
endef

#testboolean::
#	@echo -e "(call equal,dll,dll)            :  $(call equal,dll,dll)"
#	@echo -e "(call equal,,dll)               :  $(call equal,,dll)"
#	@echo -e "(call equal,thingdllthing,dll)  :  $(call equal,thingdllthing,dll)"
#	@echo -e "(call equal,dll,thingdllthing)  :  $(call equal,dll,thingdllthing)"
#	@echo -e "(call equal,dll,)               :  $(call equal,dll,)"
#	@echo -e "(call equal,,)                  :  $(call equal,,)"
#	@echo -e "(call equal,dlldlldll,dll)      :  $(call equal,dlldlldll,dll)"
#	@echo -e "(call equal,dll,dlldlldll)      :  $(call equal,dll,dlldlldll)"
#	@echo ""
#	@echo -e '(call isoneof,fred, nobby cheery fred detritus ) :  $(call isoneof,fred, nobby cheery fred detritus) '
#	@echo -e '(call isoneof,nobby, cheery fred carrot angiur)  :  $(call isoneof,nobby, cheery fred carrot angiur) '
#	@echo -e '(call isoneof,vimes,vetinari) :  $(call isoneof,vimes,vetinari) '
#	@echo -e '(call isoneof,vetinari,) :  $(call isoneof,vetinari,) '
#	@echo -e '(call isoneof,vetinari,vetinari) :  $(call isoneof,vetinari,vetinari) '


