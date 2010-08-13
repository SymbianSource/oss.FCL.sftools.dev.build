#============================================================================ 
#Name        : test_buildtools.py 
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
"""test ANTwriter """

import os.path
import shutil
import unittest

from buildtools import *


class AntWriterTest(unittest.TestCase):
    """ Unit test case for AntWriter """
    def setUp(self):
        """called before all tests run to setup variables etc."""
        self.temp = "temp"
        if not os.path.exists(self.temp):
            os.makedirs(self.temp)
    
    def tearDown(self):
        """ called after tests have run to clear anything left hanging around"""
        shutil.rmtree(self.temp)

    def testOutput(self):
        """tests AntWriter output """
        writer = AntWriter(os.path.join(self.temp, "buildtools_antwriter_test.ant.xml"))
        commands = CommandList()
        commands.addCommand(Command(self.temp, "foo"))
        writer.write(commands)
        writer.close()

class MakerWriterTest(unittest.TestCase):
    """ Unit test case for MakerWriter """
    def setUp(self):
        """called before any tests are run to setup variables etc."""
        self.temp = "temp"
        os.makedirs(self.temp)
    
    def tearDown(self):
        """ called after tests have run to clear anything left hanging around"""
        shutil.rmtree(self.temp)

    def testOutput(self):
        """test output AntWriter"""
        writer = AntWriter(os.path.join(self.temp, "buildtools_makewriter_test.mk"))
        commands = CommandList()
        commands.addCommand(Command(self.temp, "foo"))
        writer.write(commands)
        writer.close()

if __name__ == "__main__":
    unittest.main()
