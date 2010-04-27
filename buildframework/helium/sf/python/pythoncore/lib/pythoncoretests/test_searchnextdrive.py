#============================================================================ 
#Name        : test_searchnextdrive.py 
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

""" Test searchnextdrive module. """
import os
from tempfile import mkdtemp

if os.sep == '\\':
    from searchnextdrive import search_next_free_drive
    from fileutils import subst, unsubst
import unittest

class SearchNextDriveTest(unittest.TestCase):
    """ Test search next drive script... """

    def test_searchnextdrive(self):
        """ Testing search next drive script... """
        if os.sep == '\\':
            freedrive1 = search_next_free_drive()
            if freedrive1 != "Error: No free drive!":
                mytmpdir = mkdtemp()
                subst(freedrive1, mytmpdir)
                freedrive2 = search_next_free_drive()
                unsubst(freedrive1)
                os.rmdir(mytmpdir)
                if freedrive2 != "Error: No free drive!":
                    self.assertNotEqual(freedrive1, freedrive2, "searchnextdrive.py couldn't find a valid free drive")
                else:
                    raise Exception("Couldn't find a valid free drive")
            else:
                raise Exception("Couldn't find a valid free drive")
