#============================================================================ 
#Name        : test_logger.py 
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

import logging
import os
import unittest

import helium.logger
import helium.outputer


# Uncomment this line to enable logging in this module, or configure logging elsewhere
#logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('test.helium.logger')


class TestHeliumLogger(unittest.TestCase):
            
    def test_mc_logger_xml_generation(self):
        """ Test simple XML logging generation. """
        mclogger = helium.logger.Logger()
        mclogger.SetInterface("http://fawww.europe.company.com/isis/isis_interface/")
        mclogger.SetTitle("Validate Overlay")
        mclogger.SetSubTitle("Validating: ")
        mclogger.OpenMainContent("test")
        mclogger.PrintRaw("<a href=\"google.com\">test</a>")
        mclogger.Print("test")
        mclogger.Print(u"\u00A9")
        mclogger.error("test")
        mclogger.CloseMainContent()
        mclogger.OpenMainContent("test2")
        mclogger.OpenEvent("test2")
        mclogger.Print("test2")
        mclogger.error("test2")
        mclogger.CloseEvent()
        mclogger.CloseMainContent()
        mclogger.WriteToFile('log.xml')
        
        logger.info(mclogger)
        
        os.unlink('log.xml')
        
        #out = helium.outputer.XML2XHTML("log.xml")
        #out.generate()
        #out.WriteToFile("log.html")

    def test_helium_logger_unicode_handling(self):
        """ Test simple XML logging generation with unicode handling. """
        mclogger = helium.logger.Logger()
        mclogger.SetInterface("http://fawww.europe.company.com/isis/isis_interface/")
        mclogger.SetTitle("Validate Overlay")
        mclogger.SetSubTitle("Validating: ")
        mclogger.OpenMainContent("test")
        mclogger.Print(u"Test unicode handling: \u00A9")
        mclogger.CloseMainContent()
        mclogger.WriteToFile('log.xml')
        
        logger.info(mclogger)
        
        os.unlink('log.xml')

    def test_helium_logger_outputer(self):
        """ Test simple XML logging generation with unicode handling and XHTML generation. """
        mclogger = helium.logger.Logger()
        mclogger.SetInterface("http://fawww.europe.company.com/isis/isis_interface/")
        mclogger.SetTitle("Validate Overlay")
        mclogger.SetSubTitle("Validating: ")
        mclogger.OpenMainContent("test")
        mclogger.Print(u"Test unicode handling: \u00A9")
        mclogger.CloseMainContent()
        mclogger.WriteToFile('log.xml')
        
        logger.info(mclogger)
        
        out = helium.outputer.XML2XHTML('log.xml')
        out.generate()
        out.WriteToFile('log.html')
        
        os.unlink('log.xml')
        os.unlink('log.html')


if __name__ == '__main__':
    unittest.main()
