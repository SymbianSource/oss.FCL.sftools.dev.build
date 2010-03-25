#============================================================================ 
#Name        : io.py 
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
# pylint: disable-msg=W0212,W0141
""" IO module for SystemDefinitionFile.
    - Allow convertion to m,a 
"""
import re
import sys
import os
import sysdef.api

class FlashImageSizeWriter(object):
    """ Writes a .csv file listing the content of the flash images. """
    def __init__(self, output):
        """ Initialisation. """
        self.output = output
        self._out = file(output, 'w')
        
    def write(self, sys_def, config_list):
        """ Write the .csv data to a file for the given System Definition and configuration name. """
        self._out.write('component,binary,rom,rofs1,rofs2,rofs3\n')
        for configuration in sys_def.configurations.values():
            #print configuration.name  
            if configuration.name in config_list:
                for unit in configuration.units:
                    #print str(unit.name) + '  ' + str(unit.binaries)
                    for binary in unit.binaries:
                        # Only print out the binaries for which there is size information
                        if hasattr(binary, 'size'):
                            rom_types = {'rom': 0, 'rofs1': 1, 'rofs2': 2, 'rofs3': 3}
                            rom_type_values = ['', '', '', '']
                            rom_type_values[rom_types[binary.rom_type]] = str(binary.size)
                            rom_type_text = ','.join(rom_type_values)
                            self._out.write('%s,%s,%s\n' % (unit.name, binary.name, rom_type_text))
                    
    def close(self):
        """ Closing the writer. """
        self._out.close()
    
    
    
