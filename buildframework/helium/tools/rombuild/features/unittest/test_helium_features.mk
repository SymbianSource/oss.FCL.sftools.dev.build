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
# + helium_features.mk
#   + version string.
################################################

################################################
# Helper target
test_sw_version: TEST_IMAKER=imaker -p$(PRODUCT_NAME) -c$(COREPLAT_NAME) -f /epoc32/rom/config/helium_features.mk
test_sw_version:
	$(TEST_IMAKER) step-CORESWSTING
	$(TEST_IMAKER) step-ROFS2SWSTING
	$(TEST_IMAKER) step-ROFS3SWSTING
	
	
################################################
# test_autotraces
test_autotraces: TEST_IMAKER=imaker -p$(PRODUCT_NAME) -c$(COREPLAT_NAME) -f /epoc32/rom/config/helium_features.mk
test_autotraces: CORE_UDEBFILE_LIST=test.dll test2.exe
test_autotraces:
	$(TEST_IMAKER) step-AUTOTRACES

################################################
# test_COREPRE
test_COREPRE:
	@echo COREPRE ... $(if $(BUILD_COREPRE),ok,FAIL)

################################################
# Main target
unittest: test_COREPRE test_sw_version test_autotraces


################################################



