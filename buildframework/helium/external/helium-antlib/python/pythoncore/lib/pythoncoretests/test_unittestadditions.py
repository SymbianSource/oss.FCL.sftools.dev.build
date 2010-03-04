#============================================================================ 
#Name        : test_unittestadditions.py 
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
import unittest
from unittestadditions import skip

class TestSkipDecorator(unittest.TestCase):

    def test_skip_false(self):
        """ A skip(False) decorated function is executed properly """
        @skip(False)
        def func(data):
            return data
        
        self.assert_(func("test") == "test")
    
    def test_skip_true(self):
        """ A skip(True) decorated function is executed properly """
        @skip(True)
        def func(data):
            return data
        
        self.assert_(func("test") == None)


    def test_skip_true_default_return(self):
        """ A skip(True, 'some return value') decorated function is executed properly """
        @skip(True, "stub")
        def func(data):
            return data
        
        self.assert_(func("test") == "stub")
