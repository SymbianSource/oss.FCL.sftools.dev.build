#============================================================================ 
#Name        : joinsysdef_mock.py 
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

import sys
import shutil

print "Command run:"
print " ".join(sys.argv)

includes = []
if '-config' in sys.argv:
    config = sys.argv[sys.argv.index('-config') + 1]
    src = sys.argv[-1]
    
    if '-output' in sys.argv:
        dst = sys.argv[sys.argv.index('-output') + 1]
        shutil.copyfile(src, dst)
    