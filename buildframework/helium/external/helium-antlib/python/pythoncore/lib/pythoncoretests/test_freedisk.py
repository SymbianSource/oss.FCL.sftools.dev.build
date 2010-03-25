#============================================================================ 
#Name        : test_freedisk.py 
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

""" Acceptance tests for freedisk.py

"""

import unittest
import logging
import os, string
import sys

class FreeDiskTest(unittest.TestCase):
        
    def test_freedisk(self):
        import freedisk
        freedisk.print_space_report(os.getcwd(), 1)

if sys.platform == "win32":
    from win32api import GetLogicalDriveStrings
    
    logger = logging.getLogger('test_freedisk')
    
    ## MAKE SURE that the drive being tested MUST be there.
    class ToolTest(unittest.TestCase):
        """
        Setup and Tests for the script
        """
    
        def setUp(self):
            """
            All the settings related to the tests are defined here
            """
            self.drive_letter = next_free_label()
    
        def test_when_enough_space(self):
            """
            Both drive and space parameters are correct with minimum required space
            """
            output = os.system('python -m freedisk -d c: -s 1')
            assert(output==0)
                       
    
        def test_when_not_enough_space(self):
            """
            Both drive and space parameters are correct with maximum required space
            """
            output = os.system('python -m freedisk -d c: -s 10000000000')
            assert(output==-1)
    
        def test_wrong_drive_letter(self):
            """
            Tests with drive which does not exist
            """
            output = os.system('python -m freedisk -d %s: -s 10 ' % self.drive_letter)
            assert(output==-2)
            
        def test_missing_parameters(self):
            """
            Several cases to give invalid parameters
            """
    
            ##Required space parameter is missing
            output = os.system('python -m freedisk -d c:')
            assert(output==-3)
            ##Drive parameter is missing
            output = os.system('python -m freedisk -s 1')
            assert(output==-3)
            ##Both parameters are missing
            output = os.system('python -m freedisk')
            assert(output==-3)
    
        def test_wrong_drive_parameters(self):
            """
            Drive parameter is incorrect
            """
            output = os.system('python -m freedisk -d c -s 10')
            assert(output==0)
    
    
    def next_free_label():
        """
        Detects the next free drive letter for test_wrong_drive_letter
        """
        for letter in set(string.ascii_uppercase)-set(GetLogicalDriveStrings()):
            try:
                drv_letter = letter
                os.chdir(drv_letter + ':\\')
            except OSError:
                break
        else:
            raise ValueError("Out of drives")
        return drv_letter
    
    if __name__ == '__main__':
        unittest.main()