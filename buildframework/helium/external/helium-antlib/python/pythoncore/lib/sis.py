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
import buildtools


class SisPreBuilder(buildtools.PreBuilder):
    """ Generates a set of build commands for processing a SIS/X build
    configuration file. """
    def __init__(self, config_set, config_name=None):
        """ Initialisation. """
        buildtools.PreBuilder.__init__(self, config_set)
        self._config_name = config_name

    def write(self, buildFilePath):
        """ Generate the build file that will run the actual commands. """
        sisConfigs = self.configSet.getConfigurations(self._config_name)
        commandList = buildtools.CommandList()
        for config in sisConfigs:
            if 'input' in config:
                SisPreBuilder._write_v2(config, commandList)
            else:
                SisPreBuilder._write_v1(config, commandList)
                
        self.writeBuildFile(commandList, buildFilePath)
                
    @staticmethod
    def _write_v1(config, commandList):
        """ v1 config that uses name and path properties. """
        sis_filename = config['name'] + '.sis'
        if config.get('sis.name', None) != None:
            sis_filename = config['sis.name'] + '.sis'
        makeSisArgs = ['-v', config['name'] + '.pkg', sis_filename]
        makeSisCommand = buildtools.Command(config['makesis.tool'], config['path'], makeSisArgs)
        commandList.addCommand(makeSisCommand)
        
        if config.get_boolean('publish.unsigned', False):
            srcFile = os.path.join(config['path'], sis_filename)
            todir = config['build.sisfiles.dir']
            copyCommand = buildtools.Copy(srcFile, todir)
            commandList.addCommand(copyCommand, newstage=True)

        sisx_filename = sis_filename + 'x'
        signSisArgs = ['-v', sis_filename, sisx_filename, config['cert'], config['key']]
        signSisCommand = buildtools.Command(config['signsis.tool'], config['path'], signSisArgs)
        commandList.addCommand(signSisCommand, newstage=True)

        # Copy content to SIS files directory
        srcFile = os.path.join(config['path'], sisx_filename)
        todir = config['build.sisfiles.dir']
        copyCommand = buildtools.Copy(srcFile, todir)
        commandList.addCommand(copyCommand, newstage=True)

    @staticmethod
    def _write_v2(config, commandList):
        """ v2 config that uses input and output properties. """ 
        # Check for invalid old parameters
        v1_properties = ['name', 'path', 'sis.name']
        for property_ in v1_properties:
            if property_ in config:
                raise Exception("Invalid property %s if using new 'input' SIS configuration" % property_)
        
        input_ = config['input']
        (input_path, input_name) = os.path.split(input_)
        (input_root, input_ext) = os.path.splitext(input_)
        valid_extensions = ['.pkg', '.sis', '.sisx']
        if input_ext not in valid_extensions:
            raise Exception('Invalid extension for SIS configuration.')
        
        # See if makesis needs to be run
        if input_ext == '.pkg':
            output = config.get('output', input_root + '.sis')
            if output.endswith('.sisx'):
                output = output[:-1]
            # Set input for the next stage
            makesis_args = ['-v', input_, output]
            makesis_command = buildtools.Command(config['makesis.tool'], input_path, makesis_args)
            commandList.addCommand(makesis_command)
            input_ = output
            
        # See if signsis needs to be run
        if 'key' in config:
            output = config.get('output', input_root + '.sisx')
            signsis_args = ['-v', input_, output, config['cert'], config['key']]
            signsis_command = buildtools.Command(config['signsis.tool'], input_path, signsis_args)
            commandList.addCommand(signsis_command, newstage=True)
            
        # Copy content to SIS files directory
        copyCommand = buildtools.Copy(output, config['build.sisfiles.dir'])
        commandList.addCommand(copyCommand, newstage=True)
        



