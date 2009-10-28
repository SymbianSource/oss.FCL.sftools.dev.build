#============================================================================ 
#Name        : sis.py 
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

import configuration
import buildtools


class SisPreBuilder(buildtools.PreBuilder):
    """"""
    def __init__(self, config):
        buildtools.PreBuilder.__init__(self, config)

    def write(self, buildFilePath):
        sisConfigs = self.configSet.getConfigurations()
        commandList = buildtools.CommandList()
        for config in sisConfigs:
            sis_filename = config['name'] + '.sis'
            if config.get('sis.name', None) != None:
                sis_filename = config['sis.name'] + '.sis'
            makeSisArgs = ['-v', config['name'] + '.pkg', sis_filename]
            makeSisCommand = buildtools.Command(config['makesis.tool'], config['path'], makeSisArgs)
            commandList.addCommand(makeSisCommand)
            
            if config.get_boolean('publish.unsigned', False):
                # This is hardcoded xcopy operation that should be replaced by a more generic
                # definition of tasks that can be created in build files
                srcFile = os.path.join(config['path'], sis_filename)
                todir = config['build.sisfiles.dir']
                copyCommand = buildtools.Copy(srcFile, todir)
                commandList.addCommand(copyCommand, newstage=True)

            sisx_filename = sis_filename + 'x'
            signSisArgs = ['-v', sis_filename, sisx_filename, config['cert'], config['key']]
            signSisCommand = buildtools.Command(config['signsis.tool'], config['path'], signSisArgs)
            commandList.addCommand(signSisCommand, newstage=True)

            # This is hardcoded xcopy operation that should be replaced by a more generic
            # definition of tasks that can be created in build files
            srcFile = os.path.join(config['path'], sisx_filename)
            todir = config['build.sisfiles.dir']
            copyCommand = buildtools.Copy(srcFile, todir)
            commandList.addCommand(copyCommand, newstage=True)

        self.writeBuildFile(commandList, buildFilePath)
