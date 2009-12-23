#============================================================================ 
#Name        : test_relnotes.py 
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

""" Unit tests for the relnotes tool.

"""
import unittest
import StringIO
import rtfutils
import logging
import os

def test_initialization():
    "Modules are imported properly, i.e. PyRTF is there etc."
    import PyRTF

def test_pyrtf():
    import PyRTF
    
    DR = PyRTF.Renderer()
    doc     = PyRTF.Document()
    ss      = doc.StyleSheet
    section = PyRTF.Section()
    doc.Sections.append( section )
    
    string = StringIO.StringIO()
    DR.Write(doc, string)
    assert string.getvalue() != ""
    string.close()
    
class RelNotesTest( unittest.TestCase ):
    
    def setUp(self):
        self.helium_home = os.environ["HELIUM_HOME"]
        self.logger = logging.getLogger('test.relnotes')
        logging.basicConfig(level=logging.INFO)
      
    def test_rtfconvert(self):
        props = {r'my.val1=hello world' : r'my.val1=hello world',
        r'my.val2=http://www.company.com/a' : r'my.val2={\\field{\\*\\fldinst HYPERLINK http://www.company.com/a}}',
        r'my.val3=ftp://ftp.company.com/a' : r'my.val3={\\field{\\*\\fldinst HYPERLINK ftp://ftp.company.com/a}}',
        r'my.val4=\\server\share1\dir' : r'my.val4={\\field{\\*\\fldinst HYPERLINK \\\\\\\\\\\\\\\\server\\\\\\\\share1\\\\\\\\dir}}',
        r'my.val5=.\projects' : r'my.val5={\\field{\\*\\fldinst HYPERLINK .\\\\\\\\projects}}'}
        
        for p, output in props.iteritems():
            self._check_rtfconvert(p, output)
        
    def _check_rtfconvert(self, value, correctoutput):
        output = StringIO.StringIO()
        rtfu = rtfutils.RTFUtils('')
        rtfu._rtfconvert([value], output)
        self.logger.info(output.getvalue())
        self.logger.info(correctoutput) 
        assert output.getvalue() == correctoutput #.strip()
        output.close()

    def test_rtftable(self):
        output = StringIO.StringIO()
        errors = ["component,error,warning", "app2,1,2"]
        input = ["text <tag> text"]
        
        rtfu = rtfutils.RTFUtils('')
        rtfu._rtftable(errors, output, '<tag>', input)
        
        self.logger.info(output.getvalue())
        output.close()
        
    def test_rtfimage(self):
        output = StringIO.StringIO()
        image = os.path.join(self.helium_home, 'extensions', 'nokia', 'config', 'relnotes', 'logo.png')
        input = ["text <tag> text"]
        
        rtfu = rtfutils.RTFUtils('')
        rtfu._rtfimage(image, output, '<tag>', input)
        
        self.logger.info(output.getvalue())
        output.close()
