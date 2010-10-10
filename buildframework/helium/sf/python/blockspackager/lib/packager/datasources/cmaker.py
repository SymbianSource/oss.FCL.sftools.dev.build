#============================================================================ 
#Name        : cmaker.py 
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

import os
import re
from packager.datasources.api import DataSource, MissingProperty, DATASOURCES
from Blocks.Packaging.BuildData import PlainBuildData
import logging

logger = logging.getLogger('packager.datasources.cmaker')

class CMakerDataSource(DataSource):
    """ Extract information from cMaker logs """ 
    def __init__(self, epocroot, data):
        DataSource.__init__(self, epocroot, data)
        
    def getComponents(self):
        if 'whatlog' not in self._data:
            raise MissingProperty("The whatlog property has not be defined.")
        if 'configdir' not in self._data:
            raise MissingProperty("The configdir property has not be defined.")        
        component_name = "cmaker"
        if 'name' in self._data:
            component_name = self._data['name']
        version = "1"
        if 'version' in self._data:
            version = self._data['version']

        # validating the inputs
        if not os.path.exists(self._data['whatlog']) or not os.path.isfile(self._data['whatlog']):
            raise Exception("Could not find %s file." % self._data['whatlog'])        
        cdir = os.path.abspath(self._data['configdir'])
        if not os.path.exists(cdir) or not os.path.isdir(cdir):
            raise Exception("Could not find %s directory." % cdir)
            
            
        build_data = PlainBuildData()
        build_data.setComponentName(component_name)
        build_data.setComponentVersion(version) # need to get it from a the sysdef file
        build_data.setSourceRoot(self.epocroot)
        build_data.setTargetRoot(self.epocroot)
        
        targets = [path[len(self.epocroot):].lstrip(os.sep) for path in self.getExportedFiles()]
        build_data.addTargetFiles(targets)
        sources = [path[len(self.epocroot):].lstrip(os.sep) for path in self.getSourceFiles()]
        build_data.addSourceFiles(sources)
        return [build_data]
        

    def getExportedFiles(self):
        """ Get the list of exported file from the log. The parser will recognize cMaker what output and
            cMaker install log. The usage of xcopy will get warn to the user as its output will not be consider
            and the target file will get dismissed. """
        log = open(self._data['whatlog'], 'r')
        for line in log:
            line = line.rstrip()
            rcopy = re.match(r'^.*\s+copy\(q\((.+)\),q\((.*)\)\)\'', line)
            rxcopy = re.match(r'^(.*)\s+\-\>\s+(.+)$', line)
            if ':' not in line and line.startswith(os.sep):
                yield os.path.normpath(os.path.join(self.epocroot, line))
            elif rcopy is not None:
                yield os.path.normpath(os.path.join(self.epocroot, rcopy.group(2)))
            elif rxcopy is not None:
                logger.warning('This looks like an xcopy output! Make sure you use cmaker correctly: %s' % line)

    
    def getSourceFiles(self):
        """ Get the list of source file using the call dir and the whatdeps log if available. """
        cdir = os.path.abspath(self._data['configdir'])
        for (path, dirpath, namelist) in os.walk(cdir):
            for name in namelist:
                yield os.path.join(path, name)                
        if 'whatdepslog' in self._data:
            log = open(self._data['whatdepslog'], 'r')
            for line in log:
                line = line.rstrip()
                if ':' not in line and line.startswith(os.sep):
                    yield os.path.normpath(os.path.join(self.epocroot, line))

    def getHelp(self):
        help_ = """This datasource will gather information from the cMaker output logs.
Plugin property configuration:
whatlog                Defines the location of the whatlog.
configdir              Defines cMaker calling location.
whatdepslog            Defines the location of the cMaker whatdeps log (optional).
        """
        return help_


DATASOURCES['cmaker'] = CMakerDataSource
