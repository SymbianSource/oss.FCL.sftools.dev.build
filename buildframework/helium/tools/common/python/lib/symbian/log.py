#============================================================================ 
#Name        : log.py 
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

"""
Library that support Symbiam log parsing:

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
...
"""
import re
import logging
import StringIO

# Uncomment this line to enable logging in this module, or configure logging elsewhere
#logging.basicConfig(level=logging.DEBUG)
_logger = logging.getLogger('symbian.log')

class Parser(object):
    """ Generic Symbian log parser. You just need to derive that class an override few methods
     from the interface to implement your own functionnalities.
    """
    
    def __init__(self, fileobject):
        """ The constructor, it accepts a file object:
            parser = Parser(open('output.log', 'r'))
        """
        self.__file = fileobject

    def parse(self):
        """ Function that run the parsing of the log.        
        """
        #=== Stage=1 started Fri Apr 18 21:09:55 2008
        match_stage = re.compile(r"===\s+(?:Stage=)?(.+)\s+(started|finished)\s+(.+)")

        # === Stage=1 == ncp_psw 
        match_component_start = re.compile(r"===\s+(?:Stage=)?(.+?)\s+==\s+(.+)")
        match_component_finished = re.compile(r"\+\+\s+Finished\s+at")        
        # === Stage=1 == ncp_psw 
        match_component_cmdline = re.compile(r"--\s+(.+)")
        match_component_chdir = re.compile(r"Chdir\s+(.+)|cd\s+(.*?)\s+.*")
        component_name =  None
        cmdline =  None
        chdir =  None
        content = StringIO.StringIO()
        
        # parsing the content
        for line in self.__file:
            line = line.strip()
            _logger.debug(line)
            if component_name == None:
                _logger.debug("Searching stage")            
                m = match_stage.match(line)
                _logger.debug(m)
                if m != None:
                    _logger.debug("Found stage %s, %s" % (m.group(2), m.group(3)))
                    if m.group(2) == "started":
                        self.start_stage(m.group(1), m.group(3))
                    else:                        
                        component_name = None  
                        cmdline = None
                        chdir = None
                        content = StringIO.StringIO()
                        self.end_stage(m.group(1), m.group(3))
                else:
                    _logger.debug("Searching for component")
                    m = match_component_start.match(line)
                    if  m != None:
                        _logger.debug("Found component: %s" % m.group(2))
                        component_name = m.group(2)
            else:
                _logger.debug("Searching for component end")
                m = match_component_finished.match(line)
                if m != None:
                    self.task(component_name, cmdline, chdir, content.getvalue())
                    component_name = None  
                    cmdline = None
                    chdir = None
                    content = StringIO.StringIO()                
                if cmdline == None:
                    _logger.debug("Searching for component command line")
                    m = match_component_cmdline.match(line)
                    if m != None:
                        _logger.debug("Found command line: %s" % m.group(1))
                        cmdline = m.group(1)
                else:
                    _logger.debug("Searching for component dir")
                    if chdir == None:
                        m = match_component_chdir.match(line)
                        if m != None:
                            chdir = m.group(1)
                            if chdir == None:
                                chdir = m.group(2)
                            _logger.debug("Found dir: %s" % chdir)
                            continue
                    if not line.startswith("++ ") and not line.startswith("+++ "):                            
                        _logger.debug("Adding content")
                        content.write(line + "\n")
                
    def start_stage(self, name, date):
        """ Method to override to catch the start stage event. """
        pass
    
    def end_stage(self, name, date):
        """ Method to override to catch the end stage event. """
        pass
    
    def task(self, name, cmdline, dir, output):
        """ Method to override to catch the task event. """
        pass
    
