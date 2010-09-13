#
# Copyright (c) 2006-2010 Nokia Corporation and/or its subsidiary(-ies).
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
# Utility makefile 
#

# Build Python for Raptor

RAPTOR_PYTHON_VER:=2.7

PYTHON_SOURCEDIR:=$(OUTPUTPATH)/Python-$(RAPTOR_PYTHON_VER)
PYTHON_TAR:=$(SBS_HOME)/util/ext/Python-$(RAPTOR_PYTHON_VER).tar.bz2
PYINSTALLROOT:=$(INSTALLROOT)/python$(subst .,,$(RAPTOR_PYTHON_VER))

define b_python
.PHONY:: python

all:: python

python: $(PYINSTALLROOT)/bin/python
	
$(PYINSTALLROOT)/bin/python: $(PYTHON_TAR) 
	rm -rf $(PYTHON_SOURCEDIR) && \
	cd $(OUTPUTPATH) && \
	tar -xjf $(PYTHON_TAR) && \
	(  \
	cd $(PYTHON_SOURCEDIR) && \
	CFLAGS="-O3 $(GCCTUNE) -s" ./configure --prefix=$(PYINSTALLROOT) --enable-shared --with-threads --enable-bzip2 && \
	$(MAKE) -j8 && $(MAKE) install \
	)

CLEANFILES:=$(PYINSTALLROOT)/bin/python
$(cleanlog)

endef

$(eval $(b_python))

