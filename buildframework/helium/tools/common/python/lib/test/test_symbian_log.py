#============================================================================ 
#Name        : test_symbian_log.py 
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
import logging
import StringIO
import symbian.log


# Uncomment this line to enable logging in this module, or configure logging elsewhere
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('test.symbian.log')

test_output = """
===-------------------------------------------------
=== Stage=1
===-------------------------------------------------
=== Stage=1 started Fri Apr 18 21:09:55 2008
=== Stage=1 == ncp_psw
-- xcopy *.*  \\ /F /R /Y /S
--- Client0 Executed ID 1
++ Started at Fri Apr 18 21:09:55 2008
+++ HiRes Start 1208542195.09307
Chdir \\psw\\ncp_psw\\psw
S:\\psw\\ncp_psw\\psw\\s60\\tools\\customizationtool\\ct.ini -> S:\\s60\\tools\\customizationtool\\ct.ini
S:\\psw\\ncp_psw\\psw\\s60\\tools\\customizationtool\\xml_data\\NCPAudioEqualizer_settings.xml -> S:\\s60\\tools\\customizationtool\\xml_data\\NCPAudioEqualizer_settings.xml
S:\\psw\\ncp_psw\\psw\\s60\\tools\\customizationtool\\xml_data\\NCPHWGeneral_settings.xml -> S:\\s60\\tools\\customizationtool\\xml_data\\NCPHWGeneral_settings.xml
S:\\psw\\ncp_psw\\psw\\s60\\tools\\customizationtool\\xml_data\\NCPLight_settings.xml -> S:\\s60\\tools\\customizationtool\\xml_data\\NCPLight_settings.xml
S:\\psw\\ncp_psw\\psw\\s60\\tools\\customizationtool\\xml_data\\NCPSysAp_settings.xml -> S:\\s60\\tools\\customizationtool\\xml_data\\NCPSysAp_settings.xml
S:\\psw\\ncp_psw\\psw\\s60\\tools\\customizationtool\\xml_data\\VariantFeatures.xml -> S:\\s60\\tools\\customizationtool\\xml_data\\VariantFeatures.xml
6 File(s) copied
+++ HiRes End 1208542195.28056
++ Finished at Fri Apr 18 21:09:55 2008
=== Stage=1 finished Fri Apr 18 21:09:55 2008
===-------------------------------------------------
=== Stage=2
===-------------------------------------------------
=== Stage=2 started Fri Apr 18 21:29:33 2008
=== Stage=2 == localconnectivityextensions
-- abld export -keepgoing
--- Client2 Executed ID 213
++ Started at Fri Apr 18 21:29:33 2008
+++ HiRes Start 1208543373.36786
Chdir \s60\osext\localconnectivityextensions\group
  make -r  -k -f "\EPOC32\BUILD\s60\osext\localconnectivityextensions\group\EXPORT.make" EXPORT VERBOSE=-s KEEPGOING=-k
copy "\s60\osext\localconnectivityextensions\lcext_dom\bluetooth_audio_adaptation_api\inc\btaudiostreaminputbase.h" "\epoc32\include\domain\osextensions\btaudiostreaminputbase.h"
        1 file(s) copied.
copy "\s60\osext\localconnectivityextensions\lcext_dom\bluetooth_power_management_api\inc\btpm.h" "\epoc32\include\domain\osextensions\btpm.h"
        1 file(s) copied.
+++ HiRes End 1208543373.72723
++ Finished at Fri Apr 18 21:29:33 2008
=== Stage=2 == messagingextensions
-- abld export -keepgoing
--- Client6 Executed ID 217
++ Started at Fri Apr 18 21:29:33 2008
+++ HiRes Start 1208543373.36786
Chdir \s60\osext\messagingextensions\group
  make -r  -k -f "\EPOC32\BUILD\s60\osext\messagingextensions\group\EXPORT.make" EXPORT VERBOSE=-s KEEPGOING=-k
Creating \epoc32\include\domain\osextensions\loc\sc
Creating \epoc32\rom\include\language\osext
copy "\s60\osext\messagingextensions\msgbranched\rom\messageserver_rsc.iby" "\epoc32\rom\include\language\osext\messageserver_rsc.iby"
        1 file(s) copied.
copy "\s60\osext\messagingextensions\msgbranched\rom\gtemailmtmResources.iby" "\epoc32\rom\include\language\osext\gtemailmtmResources.iby"
        1 file(s) copied.
copy "\s60\osext\messagingextensions\msgbranched\messaging\email\clientmtms\loc\imcm.loc" "\epoc32\include\domain\osextensions\loc\sc\imcm.loc"
        1 file(s) copied.
copy "\s60\osext\messagingextensions\msgbranched\messaging\email\clientmtms\loc\imcm_default_charset.loc" "\epoc32\include\domain\osextensions\loc\sc\imcm_default_charset.loc"
        1 file(s) copied.
copy "\s60\osext\messagingextensions\msgbranched\messaging\framework\server\loc\msgs.loc" "\epoc32\include\domain\osextensions\loc\sc\msgs.loc"
        1 file(s) copied.
+++ HiRes End 1208543373.80535
++ Finished at Fri Apr 18 21:29:33 2008
=== Stage=2 finished Fri Apr 18 21:09:55 2008
"""



class Parser(symbian.log.Parser):
    def __init__(self, content=StringIO.StringIO(test_output)):        
        symbian.log.Parser.__init__(self, content)
        self.stages = []
        self.tasks = []

    def start_stage(self, name, time):
        logger.debug(name) 
        self.stages.append(name)

    def task(self, name, cmdline, dir, output):
        logger.debug("%s, %s, %s, %s" % (name, cmdline, dir, output)) 
        self.tasks.append({'name': name, 'cmdline': cmdline, 'dir': dir, 'output': output})


class TestSymbianLog(unittest.TestCase):
    """ Test cases for Helium Symbian log parser. """
    
    def test_parser(self):
        """ Test the parser
        """
        parser = Parser()
        parser.parse()
        assert len(parser.stages) == 2
        assert len(parser.tasks) == 3
        
