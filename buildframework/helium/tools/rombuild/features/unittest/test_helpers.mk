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
################################################
# Unit-testing Helium Makefile functionalities.
################################################

# Including Helium specific additional features.
include helium_features.mk

################################################
# Helper target
test_helpers:
	@echo test_helpers
	@echo foo$(call removedrive,Z:\output\logs)bar
	@echo Remove drive from a path that contains a drive ... $(if $(subst /output/logs,,$(call removedrive,Z:\output\logs)),FAIL,ok)
	@echo Remove drive from a path that does not contain a drive ... $(if $(subst /output/logs,,$(call removedrive,\output\logs)),FAIL,ok)
	

################################################
# Main target
unittest: test_helpers


################################################


