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
# raptor version information module

# replace CHANGESET with the Hg changeset for ANY release

version=(2,14,1,"2010-06-03","symbian build system","CHANGESET")

def numericversion():
	"""Raptor version string"""
	return "%d.%d.%d" % version[:3]

def fullversion():
	"""Raptor version string"""
	return "%d.%d.%d [%s %s %s]" % version
