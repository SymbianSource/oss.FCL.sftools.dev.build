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
###############################################################################
# Evaluate iMaker variables or expressions in a file
TYPE=prd
TEMPLATE=
EVALUATED_FILE_NAME=$(TEMPLATE).parsed

PERL_SCRIPT=open FILE, $$ARGV[0]; foreach (<FILE>) {s/\t/\\t/g; s/\n/\\n/g;print $$_;} close FILE;

CLEAN_EVAL_VARIABLES = del | $(EVALUATED_FILE_NAME)
BUILD_EVAL_VARIABLES = \
	$(eval EVALUATED_STR=$(shell perl -e "$(PERL_SCRIPT)" $(TEMPLATE))) | \
	write | $(EVALUATED_FILE_NAME) | $(EVALUATED_STR)
###############################################################################
