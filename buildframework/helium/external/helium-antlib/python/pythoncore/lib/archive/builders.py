#============================================================================ 
#Name        : builders.py 
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
This modules contains the archive builders.
An archive builder is a class that is able to use data from a configuration
and generate a set of shell commands.
"""
import archive.tools
import archive.selectors
import archive.mappers
import archive.scanners
import logging
import pathaddition
import buildtools
import os
import codecs
import fileutils

_logger = logging.getLogger('archive')
_logger.setLevel(logging.INFO)

class ArchivePreBuilder(buildtools.PreBuilder):
    """ Processes an archive build specification. """
    def __init__(self, config_set, config_name, writerType='ant', index = None):
        buildtools.PreBuilder.__init__(self, config_set)
        self.configs = config_set.getConfigurations()
        self.spec_name = config_name
        self.index = index
        self.writerType = writerType
        self.listToFindPrefix = []

    def build_manifest(self, config):
        """ Generate a manifest file from the a configuration. """
        _logger.info('Processing archive config: ' + config['name'])
        _scanners = archive.scanners.get_scanners(config.get_list('scanners', ['default']), config)
        
        content_list = {}
    
        if not os.path.exists(config['temp.build.dir']):
            os.makedirs(config['temp.build.dir'])
        manifest_file_path = os.path.abspath(os.path.join(config['temp.build.dir'], config['name'] + '_includefile.txt'))
        out = codecs.open(manifest_file_path, 'w+', 'utf-8')
        
        # zip.root.dir can be set to root.dir so that when zipping from another dir,
        # the manifest is relative to that dir
        (drive, root_dir) = os.path.splitdrive(os.path.normpath(config.get('zip.root.dir', config['root.dir'])))
        _logger.info("   * Scanning")
        for scanner in _scanners:
            _logger.debug("Scanner %s" % scanner)
            for subpath in scanner.scan():
                (drive, subpath) = os.path.splitdrive(subpath)
                if pathaddition.relative.abs2rel(subpath, root_dir):
                    _logger.debug(subpath)
                    subpath = subpath[len(root_dir):]
                    if subpath.startswith(os.sep):
                        subpath = subpath[1:]
                # normpath is to remove any occurances of "..\.." before checking for duplicates
                subpath = os.path.normpath(subpath)
                if subpath not in content_list:
                    out.write(u"".join([subpath, u'\n']))
                    content_list[subpath] = True
    
        out.close()
        return manifest_file_path

    def manifest_to_commands(self, config, manifest):
        """ Generate return a command list. Commands are stored in a two dimension array."""
        _logger.info("   * Generating commands")
        tool = archive.tools.get_tool(config['archive.tool'])
        mapper_name = 'default'
        if config.has_key('mapper'):
            mapper_name = config['mapper']
        mapper = archive.mappers.get_mapper(mapper_name, config, tool)
        return mapper.create_commands(manifest)
    
    def create_command_list(self, commands):
        """ Convert a two dimensions array of command to a CommandList object. """
        stages = buildtools.CommandList()
        newstage = False
        for cmds_stage in commands:
            _logger.debug("Stage: %s" % cmds_stage)
            for cmd in cmds_stage:
                stages.addCommand(cmd, newstage)
                newstage = False
            newstage = True
        return stages
    
    def writeTopLevel(self, build_file_path, output_path, xml_file):
        """Creates a build tool config makefile that executes archieve build."""
        config_name_list = []
        for config in self.configs:
            config_name_list.append(config['name'])
            if not os.path.exists(config['archives.dir']):
                os.makedirs(config['archives.dir'])
            
        writer = buildtools.get_writer(self.writerType, build_file_path)
        writer.writeTopLevel(config_name_list, self.spec_name, output_path, xml_file)
        writer.close()

    def getCommonUncRoots(self, uncPaths):
        commonRoots = {}
        for p in uncPaths:
            commonRoots["\\\\" + os.sep.join(p[2:].split(os.sep)[0:2]) + os.sep] = 1
        return commonRoots.keys()

    def getPrefix(self, dir, commonUncRoots):
        for root in commonUncRoots:
            if dir.startswith(root):
                return root
        raise Exception("Could not find root for %s." % dir)
    
    def checkRootDirValue(self, builder, parse_xml_file, build_drive, config_type):
        """Checks UNC path in root.dir and adds the substituted drive into EMAKEROOT."""
        substDrives = []
        if build_drive:
            substDrives.append(build_drive + os.sep)
        
        # Read all the config's root.dir to get UNC Path if any
        # Of course this is only on windows platform
        if os.sep == '\\':
            for config in self.configs:
                (drive, root_dir) = os.path.splitdrive(os.path.normpath(config['root.dir']))
                _logger.debug("drive=%s, root_dir=%s" % (drive, root_dir))
                if drive == "":
                    self.listToFindPrefix.append(root_dir)
        
            commonUncRoots = self.getCommonUncRoots(self.listToFindPrefix)
            _logger.debug("Common roots %s" % (commonUncRoots))
            driveMapping = {}
            for root in commonUncRoots:
                _logger.info("Substing %s" % (root))
                driveMapping[root] = self.substUncPath(root)
                _logger.debug("%s subst as %s" % (root, driveMapping[root]))
                substDrives.append(driveMapping[root] + os.sep)

            for config in self.configs:
                (drive, root_dir) = os.path.splitdrive(os.path.normpath(config['root.dir']) + os.sep) 
                if drive == "":
                    for root in driveMapping:
                        if root_dir.startswith(root):
                            config['root.dir'] = os.path.normpath(driveMapping[root] + os.sep + root_dir[len(root):len(root_dir)])
                            _logger.info("Updated %s in %s" % (root_dir, config['root.dir']))
                            config['unsubst.dir'] = driveMapping[root]
                            break                
                elif drive != build_drive:
                    if config['root.dir'] not in substDrives:
                        substDrives.append(config['root.dir'])
        else:
            for config in self.configs:
                if config['root.dir'].startswith('\\\\'):
                    _logger.error("UNC path are not supported under this platform: %s" % (config['root.dir']))
        builder.writeToXML(parse_xml_file, self.configs, config_type)
        return os.path.pathsep.join(substDrives)
       

    def substUncPath(self, path):
        freedrive = fileutils.get_next_free_drive()
        fileutils.subst(freedrive, path)
        return freedrive

    def cleanupSubstDrives(self):
        # Read all the config's root.dir to get UNC Path if any
        drives = {}
        for config in self.configs:
            _logger.debug("Checking configuration...")
            _logger.debug("unsubst.dir: %s" % 'unsubst.dir' in config)
            _logger.debug("drives: %s" % drives)
            if 'unsubst.dir' in config and not config['unsubst.dir'] in drives:
                _logger.debug("Found drive to unsubst %s" % (config['unsubst.dir']))
                self.unSubStituteDrives(config['unsubst.dir'])
                drives[config['unsubst.dir']] = config['unsubst.dir']
                    
    def unSubStituteDrives(self, drive):
        _logger.info("Unsubsting %s" % (drive))
        fileutils.unsubst(drive)
        
    def write(self, outputname):
        """Creates a build tool configuration file that executes archive build operations.

        The input to each archive build operation is an includefile that lists
        all the files to be included in the archive. These text files are
        generated before the build file by scanning the filesystem.
        """
        stages = buildtools.CommandList()

        commands = []
        if self.index > len(self.configs):
            raise Exception("index not found in configuration")
        config = self.configs[self.index]
        stages = self.manifest_to_commands(config, self.build_manifest(config))
                
        # merging the commands            
        while len(commands) < len(stages):
            commands.append([])
        for i in range(len(stages)):
            commands[i].extend(stages[i])

        writer = buildtools.get_writer(self.writerType, outputname)
        writer.write(self.create_command_list(commands))
        writer.close()
