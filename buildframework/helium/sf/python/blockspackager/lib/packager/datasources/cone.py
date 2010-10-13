#============================================================================ 
#Name        : conftool.py 
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

from packager.datasources.api import DataSource, DATASOURCES
from Blocks.Packaging.BuildData import PlainBuildData
import logging
import re 
import os

logger = logging.getLogger('packager.datasources.conftool')

class ConEDataSource(DataSource):
    """ Extract information from ConE logs """
    def __init__(self, epocroot, data=None):
        DataSource.__init__(self, epocroot, data)
    
    def getTargetFiles(self):
        """ Get the generated files from the log output. """
        result = []
        txtFile = open(self._data['filename'], 'r')
        matcher = re.compile(r"^\s*Generating file '(.+)'\.\.\.\s*$")
        for line in txtFile:
            res = matcher.match(line)
            if res:
                result.append(os.path.normpath(os.path.join(self.epocroot, 
                                                            res.group(1))))
        txtFile.close()
        return result

    def getComponents(self):
        """ Get the components list from the cli input. """
        if 'name' not in self._data:
            raise Exception("The name property has not be defined.")
        if 'version' not in self._data:
            raise Exception("The version property has not be defined.")

        if 'filename' not in self._data:
            raise Exception("The input conftool log file is not defined")

        #todo: add the source iby / path for conftool input
        build_data = PlainBuildData()
        build_data.setComponentName(self._data['name'])
        build_data.setComponentVersion(self._data['version'])
        build_data.setSourceRoot(self.epocroot)
        build_data.setTargetRoot(self.epocroot)
        build_data.addTargetFiles([path[len(self.epocroot):].lstrip(os.sep) for path in self.getTargetFiles()])
        return [build_data]

    def getHelp(self):
        """ Returns the help. """
        return """
name            Defines the name of the component
version         Defines the version of the component
filename        Defines the log file name of ctool
"""

        
DATASOURCES['cone'] = ConEDataSource