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
# cmaker makefile installation.
#

# Set perl executable if it is not set by the environment. 
PERL ?= perl
INSTALLDIR    = $(subst \,/,$(EPOCROOT))epoc32/tools
INSTALLDIRSRC = $(INSTALLDIR)/cmaker
INSTALLDIRBIN = $(INSTALLDIR)/rom
SRCFILES = $(wildcard src/*.mk)
TRGFILES = $(patsubst src/%.mk,$(INSTALLDIRSRC)/%.mk,$(SRCFILES))

.PHONY: install clean

install: $(TRGFILES) $(INSTALLDIRBIN)/mingw_make.exe $(INSTALLDIR)/cmaker.cmd ; @

src/cmaker.cmd: $(INSTALLDIR)
$(INSTALLDIR)/cmaker.cmd : src/cmaker.cmd
	$(call copy,$<,$@)

src/*.mk: $(INSTALLDIRSRC)
$(INSTALLDIRSRC)/%.mk: src/%.mk
	$(call copy,$<,$@)
 
bin/mingw_make.exe :$(INSTALLDIRBIN)
$(INSTALLDIRBIN)/mingw_make.exe: bin/mingw_make.exe
	$(call copy,$<,$@)

$(INSTALLDIR):
	$(call makedir,$@)

$(INSTALLDIRSRC):
	$(call makedir,$@)

$(INSTALLDIRBIN):
	$(call makedir,$@)

clean:
	$(call remove,$(INSTALLDIRSRC))
	$(call remove,$(INSTALLDIR)/cmaker.cmd)

############################################################################################	
# Create some perl specific operations to make the install operation platform independent
define makedir
  $(PERL) -e 'use File::Path; mkpath(q($1))'

endef

define copy
  $(PERL) -e 'use File::Copy; copy(q($1),q($2))'

endef

define remove
  $(PERL) -e 'use File::Remove qw(remove); remove \1,q($1)'

endef
