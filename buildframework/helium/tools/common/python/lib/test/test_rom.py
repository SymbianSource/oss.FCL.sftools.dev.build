#============================================================================ 
#Name        : test_rom.py 
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


import unittest, amara, os
from rom import *
import configuration



class ImageTest( unittest.TestCase ):
    def setUp( self ):
        pass #productConfig = amara.parse( PRODUCT_CONFIG )
    
    def test_mytraces(self):
        """ mytraces.txt file can be added and deleted. """
        config = configuration.Configuration({'rom.output.dir': '',
                                            'rommake.mytraces.file': 'mytraces.txt',
                                            'mytraces.binaries': ['foo.dll', 'bar.dll']})
        image = Image(config)
        image._clean_mytraces()
        
        image._process_my_traces()
        assert os.path.exists('mytraces.txt')
        
        # Check content
        mytraces_lines = open( 'mytraces.txt', 'r' ).readlines()
        print mytraces_lines[0]
        assert mytraces_lines[0] == 'foo.dll\n'
        assert mytraces_lines[1] == 'bar.dll\n'
        
        image._clean_mytraces()
        assert not os.path.exists('mytraces.txt')

    def test_mytraces_not_needed(self):
        """ mytraces.txt file not used if config does not define. """
        config = configuration.Configuration({'rom.output.dir': '',
                                            'rommake.mytraces.file': 'mytraces.txt'})
        image = Image(config)
        image._clean_mytraces()
        
        image._process_my_traces()
        assert not os.path.exists('mytraces.txt')