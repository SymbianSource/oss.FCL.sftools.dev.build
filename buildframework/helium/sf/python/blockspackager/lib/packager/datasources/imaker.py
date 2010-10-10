#============================================================================ 
#Name        : imaker.py 
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

from packager.datasources.api import DataSource, MissingProperty, DATASOURCES
from Blocks.Packaging.BuildData import PlainBuildData, BdFile
import logging
import re 
import os

logger = logging.getLogger('packager.datasources.imaker')

class ObyParser:
    """ Simplistic Oby file parser. """
    def __init__(self, epocroot, filename):
        self.epocroot = epocroot
        self.filename = filename

    def getSourceFiles(self):
        """ Return the list of source file needed to create the image. """
        result = []
        logger.debug("Analyzing %s" % self.filename)
        oby = open(self.filename, 'r')
        for line in oby:
            res = re.match(r'\s*(file|data|variant.+|bootbinary|primary.+|extension.+)\s*=\s*\"?(.+?)\"?\s+\".+\"', line)
            if res is not None:
                result.append(os.path.normpath(os.path.join(self.epocroot, res.group(2).strip().replace('\\', os.sep).replace('/', os.sep))))
        oby.close()
        return result


class IMakerDataSource(DataSource):
    """ Extract information from iMaker logs - iMaker integrated version """
    def __init__(self, epocroot, data=None):
        DataSource.__init__(self, epocroot, data)
    
    def getComponents(self):
        if 'name' not in self._data:
            raise Exception("The name property has not be defined.")
        if 'version' not in self._data:
            raise Exception("The version property has not be defined.")
        obys = [self._data[key] for key in self._data.keys() if key.startswith('oby')]
        targets = [os.path.normpath(self._data[key]) for key in self._data.keys() if key.startswith('target')]
        build_data = PlainBuildData()
        build_data.setComponentName(self._data['name'])
        build_data.setComponentVersion(self._data['version'])
        build_data.setSourceRoot(self.epocroot)
        build_data.setTargetRoot(self.epocroot)
        
        build_data.addTargetFiles([path[len(self.epocroot):].lstrip(os.sep) for path in targets])
        
        deps = []
        for oby in obys:        
            deps.extend(ObyParser(self.epocroot, oby).getSourceFiles())
        for target in targets:
            print target
            if target.endswith(".fpsx"):
                target = os.path.normpath(target)
                bdfile = BdFile(target[len(self.epocroot):].lstrip(os.sep))
                bdfile.setOwnerDependencies([path[len(self.epocroot):].lstrip(os.sep) for path in deps])
                build_data.addDeliverable(bdfile)
        return [build_data]

class IMakerRomDirDataSource(DataSource):
    """ Extract information from iMaker logs - guess content of the package from the rom output dir. """
    def __init__(self, epocroot, data=None):
        DataSource.__init__(self, epocroot, data)
    
    def getComponents(self):
        if 'name' not in self._data:
            raise MissingProperty("The name property has not be defined.")
        if 'version' not in self._data:
            raise MissingProperty("The version property has not be defined.")
        if 'dir' not in self._data:
            raise MissingProperty("The dir property has not be defined.")
        cdir = os.path.normpath(self._data['dir']) 
        obys = []
        targets = []
        for (path, dirpath, namelist) in os.walk(cdir):
            for name in namelist:
                if name.endswith(".oby"):
                    obys.append(os.path.join(path, name)[len(self.epocroot):].lstrip(os.sep))
                targets.append(os.path.join(path, name)[len(self.epocroot):].lstrip(os.sep))
        build_data = PlainBuildData()
        build_data.setComponentName(self._data['name'])
        build_data.setComponentVersion(self._data['version'])
        build_data.setSourceRoot(self.epocroot)
        build_data.setTargetRoot(self.epocroot)
        build_data.addTargetFiles(targets)
        return [build_data]
    
    def getHelp(self):
        return """
name            Defines the name of the component
version         Defines the version of the component
dir             Defines the root location of ROM images.
"""

        
DATASOURCES['imaker'] = IMakerDataSource
DATASOURCES['imaker-romdir'] = IMakerRomDirDataSource

