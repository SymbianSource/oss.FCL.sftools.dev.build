#============================================================================ 
#Name        : __init__.py 
#Part of     : Helium 

#Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
#All rights reserved.
#This component and the accompanying materials are made available
#under the terms of the License "Eclipse Public License v1.0"
#which accompanies this distribution, and is available
#at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
#Initial Contributors:
#Nokia Corporation - initial contribution.
#
#Contributors:
#
#Description:
#===============================================================================

""" iMaker framework. """
from imaker.api import * #this needs to remain here even though pylint throws it as 
                         #a warning 'unused' due to being needed by what imports this AGH!!! 
                         #can't the thing that imports this import the api file?
