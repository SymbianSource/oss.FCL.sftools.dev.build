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
# Filter class for doing --what and --check operations
#

import os
import sys
import re
import filter_interface
import filter_what

class FilterCheck(filter_what.FilterWhat):

        def __init__(self): 
		super(filter_what.FilterWhat,self).__init__()
		self.check = True
		self.path_prefix_to_strip = None

