#============================================================================ 
#Name        : mappers.py 
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

""" Archive mappers that map how the input files are divided into archives.


"""

import buildtools
import os
import codecs
import fileutils
import logging
import symrec
import re
import csv
import shutil

_logger = logging.getLogger('logger.mappers')
_logger.setLevel(logging.INFO)

# Default value for missing/invalid policy files.
MISSING_POLICY = "9999"


class Mapper(object):
    """ Mapper Abstract class. Any custom implementation must derive it!.
    
    It handles metadata creation.
    """
    
    def __init__(self, config, tool):
        self._tool = tool
        self._config = config
        self._metadata = None
        if not os.path.exists(self._config['archives.dir']):
            os.makedirs(self._config['archives.dir'])
        if self._config.has_key("grace.metadata") and self._config.get_boolean("grace.metadata", False):
            if self._config.has_key("grace.template") and os.path.exists(self._config["grace.template"]) and \
             not os.path.exists(os.path.join(self._config['archives.dir'], self._config['name'] + ".metadata.xml")):
                shutil.copy(config["grace.template"], os.path.join(self._config['archives.dir'], self._config['name'] + ".metadata.xml"))
            self._metadata = symrec.ReleaseMetadata(os.path.join(self._config['archives.dir'], self._config['name']+ ".metadata.xml"),
                                       service=self._config['grace.service'],
                                       product=self._config['grace.product'],
                                       release=self._config['grace.release'])
            self._metadata.save()            
        
    def declare_package(self, filename, extract="single"):
        """ Add a package to the metadata file. """
        if self._metadata is None:
            return
        self._metadata.add_package(os.path.basename(filename), extract=extract, filters=self._config.get_list('grace.filters', None), default=self._config.get_boolean('grace.default', True))
        self._metadata.save()
    
    def create_commands(self, manifest):
        """ Return a list of command list. """
        return [[self._tool.create_command(self._config['name'], manifests=[manifest])]]
        
    
class DefaultMapper(Mapper):
    """ The default mapper. It splits the content based on size characteristics.
    
    'the max.files.per.archive' and 'max.uncompressed.size' properties define how the input files
    are split between a number of part zips.
    """
    def __init__(self, config, archiver):
        """ Initialization. """
        Mapper.__init__(self, config, archiver)

    def create_commands(self, manifest):
        """ Return a list of command lists. """
        result = []

        _logger.info("  * Input manifest: " + manifest)
        manifests = self._split_manifest_file(self._config['name'], manifest)
        if not os.path.exists(self._config['archives.dir']):
            _logger.info("  * Mkdir " + self._config['archives.dir'])
            os.makedirs(self._config['archives.dir'])

        for manifest in manifests:
            _logger.info("  * Creating command for manifest: " + manifest)
            filename = os.path.join(self._config['archives.dir'], os.path.splitext(os.path.basename(manifest))[0])
            if len(manifests) == 1:
                filename = os.path.join(self._config['archives.dir'], self._config['name'])
            _logger.info("  * " + filename + self._tool.extension())
            self.declare_package(filename + self._tool.extension(), self._config.get('grace.extract', 'single'))
            result.extend(self._tool.create_command(self._config.get('zip.root.dir', self._config['root.dir']), filename, manifests=[manifest]))
        
        return [result]

    def _split_manifest_file(self, name, manifest_file_path):
        """ This method return a list of files that contain the content of the zip parts to create. """
        filenames = []
        
        if (self._config.has_key('max.files.per.archive') or self._config.has_key('max.uncompressed.size')):
            size = 0
            files = 0
            part = 0
            filename = ""
            output = None
                        
            if os.path.exists(self._config['root.dir']) and os.path.isdir(self._config['root.dir']):
                curdir = os.path.abspath(os.curdir)
                os.chdir(self._config.get('zip.root.dir', self._config['root.dir']))            
                maxfiles = self._config.get('max.files.per.archive', 100000000)
                _logger.info("Max number of files per archive: " + str(maxfiles))
                max_uncompressed_size = self._config.get('max.uncompressed.size', 100000000)
                _logger.info("Max uncompressed size per archive: " + str(max_uncompressed_size))
                
                file_handle = codecs.open(manifest_file_path, "r", "utf-8" )
        
                for line in file_handle.readlines():
                    line = line.rstrip()
        
                    if(os.path.isfile(line)):
                        if part == 0 or files == int(maxfiles) or size + os.path.getsize(line) >= int(max_uncompressed_size):
                            if output != None:
                                output.close()
        
                            size = 0
                            files = 0
                            part += 1
        
                            filename = "%s_part%02d" % (name, part)
                            filenames.append(os.path.join(self._config['temp.build.dir'], filename + ".txt"))
        
                            output = codecs.open(os.path.join(self._config['temp.build.dir'], filename + ".txt"), 'w', "utf-8" )
        
                        files += 1
                        size += os.path.getsize(line)
        
                        output.write(u"".join([line, u'\n']))
                    elif(os.path.isdir(line)):
                        if (len(os.listdir(line)) == 0):
                            if part == 0 or files == int(maxfiles):
                                if output != None:
                                    output.close()
        
                                size = 0
                                files = 0
                                part += 1
        
                                filename = "%s_part%02d" % (name, part)
                                filenames.append(os.path.join(self._config['temp.build.dir'], filename + ".txt"))
                                
                                output = open(os.path.abspath(os.path.join(self._config['temp.build.dir'], filename + ".txt")), 'w')
        
                            files += 1
        
                            output.write(u"".join([line, u'\n']))
                    else:
                        _logger.warning('Not recognized as file or directory: %s' % line)
        
                if output != None:
                    output.close()
        
                file_handle.close()
                os.chdir(curdir)
        else:
            filenames.append(manifest_file_path)
        
        return filenames


class PolicyMapper(Mapper):
    """ Implements a policy content mapper.
    
    It transforms a list of files into a list of commands with their inputs.
    All files with policy 0 will be under the main archive.
    All other files will get backed up by policy and then store into an second archive. 
    """
    
    def __init__(self, config, archiver):
        """ Initialization. """
        Mapper.__init__(self, config, archiver)
        self._policies = {}
        self._policy_cache = {}
        self._binary = {}
        # Load csv
        if self._config.has_key('policy.csv'):
            if os.path.exists(self._config['policy.csv']):
                self.load_policy_binary(self._config['policy.csv'])
            else:
                _logger.error("POLICY_ERROR: File not found '%s'." % self._config['policy.csv'])

    def load_policy_binary(self, csvfile, column=1):
        """ Loads the binary IDs from the CSV file. """
        _logger.info("POLICY_INFO: Loading policy definition '%s'." % csvfile)
        reader = csv.reader(open(csvfile, "rU"))
        for row in reader:
            if re.match(r"^((?:\d+)|(?:0842[0-9a-zA-Z]{3}))$", row[0].strip()):                
                _logger.info("POLICY_INFO: Adding policy: '%s' => '%s'" % (row[0].strip(), row[column].strip().lower()))
                self._binary[row[0].strip()] = row[column].strip().lower()
            else:
                _logger.warning("POLICY_WARNING: Discarding policy: '%s'." % row[0].strip())

    def zip2zip(self):
        """ Should the non public zip be zipped up under a specific zip. """
        return self._config.get_boolean('policy.zip2zip', False)
    
    def create_commands(self, manifest):
        """ Generates a list of build commands. """
        result = []
        stages = []

        # Create the archive output directory
        if not os.path.exists(self._config['archives.dir']):
            _logger.info("  * Mkdir " + self._config['archives.dir'])
            os.makedirs(self._config['archives.dir'])
        
        # Sort the manifest content, splitting it by policy
        file_handle = codecs.open(manifest, "r", "utf-8")
        for line in file_handle.readlines():
            line = line.rstrip()
            self._sort_by_policy(line)
        file_handle.close()
        
        # Generating sublists.
        for key in self._policies.keys():
            self._policies[key].close()
            manifest = os.path.join(self._config['temp.build.dir'], self._config['name'] + "_%s" % key + ".txt")
            filename = os.path.join(self._config['archives.dir'], self._config['name'] + "_%s" % key)
            _logger.info("  * " + filename + self._tool.extension())
            result.extend(self._tool.create_command(self._config.get('zip.root.dir', self._config['root.dir']), filename, manifests=[manifest]))
        stages.append(result)
        
        # See if any internal archives need to be created
        content = []
        for key in self._policies.keys():
            if not self.zip2zip():
                self.declare_package(self._config['name'] + "_%s" % key + self._tool.extension())
            else:
                if key != "0":
                    content.append(os.path.join(self._config['archives.dir'], self._config['name'] + "_%s" % key + self._tool.extension()))
                else:
                    self.declare_package(self._config['name'] + "_%s" % key + self._tool.extension())

        # Creating zip that contains each policy zips.
        if self.zip2zip() and len(content) > 0:
            manifest = os.path.join(self._config['temp.build.dir'], self._config['name'] +  ".internal.txt")
            file_handle = codecs.open( manifest, "w+", "utf-8" )
            file_handle.write(u"\n".join(content))
            file_handle.close()
            internal = "internal"
            if self._config.has_key('policy.internal.name'):
                internal = self._config['policy.internal.name']
            filename = os.path.join(self._config['archives.dir'], self._config['name'] +  "_" + internal)
            _logger.info("  * " + filename + self._tool.extension())
            self.declare_package(filename + self._tool.extension(), "double")
            stages.append(self._tool.create_command(self._config['archives.dir'], filename, manifests=[manifest]))

            cmds = []
            for filename in content:
                cmds.append(buildtools.Delete(filename=filename))
            stages.append(cmds)
        return stages
    
    def get_dir_policy(self, dirname):
        """ Get policy value for a specific directory. """
        dirname = os.path.normpath(dirname)
        if not self._policy_cache.has_key(dirname):
            policyfile = None
            for name in self.get_policy_filenames():
                if os.sep != '\\':
                    for filename in os.listdir(dirname):
                        if filename.lower() == name.lower():
                            policyfile = os.path.join(dirname, filename)
                            break
                elif os.path.exists(os.path.join(dirname, name)): 
                    policyfile = os.path.join(dirname, name)
                    break
            
            value = self._config.get('policy.default.value', MISSING_POLICY)
            if policyfile != None:      #policy file present
                try:
                    value = fileutils.read_policy_content(policyfile)
                    if value not in self._binary.keys():    #check policy file is valid
                        _logger.error("POLICY_ERROR: policy file found %s but policy %s value not exists in csv" % (policyfile, value))
                except Exception, exc:
                    _logger.error("POLICY_ERROR: %s" % exc)         
                    value = self._config.get('policy.default.value', MISSING_POLICY)
            else:       #no policy file present
                filePresent = False
                dirPresent = False
                for ftype in os.listdir(dirname):   #see if files or directories are present
                    if os.path.isdir(os.path.join(dirname, ftype)):
                        dirPresent = True
                    if os.path.isfile(os.path.join(dirname, ftype)):
                        filePresent = True
                        
                if filePresent:    #files present : error     
                    _logger.error("POLICY_ERROR: could not find a policy file under: '%s'" % dirname)
                elif dirPresent and not filePresent:  #directories only : warning
                    _logger.error("POLICY_WARNING: no policy file, no files present, but sub-folder present in : '%s'" % dirname)
                else:       #no files no dirs : warning
                    _logger.error("POLICY_WARNING: empty directory at : '%s'" % dirname)
                
            # saving the policy value for that directory.
            self._policy_cache[dirname] = value
        return self._policy_cache[dirname]
        
    def get_policy_filenames(self):
        """ Returns the list of potential policy filenames. """
        return self._config.get_list('policy.filenames', ['Distribution.policy.s60'])
        
    def _sort_by_policy(self, filename):
        """ Store the input file sorted by its policy number. """
        path = os.path.join(self._config['root.dir'], filename)
        parentdir = os.path.dirname(path)
        if os.path.isdir(path):
            parentdir = path
        value = self.get_dir_policy(parentdir)
        if not value in self._policies:
            self._policies[value] = codecs.open( os.path.join(self._config['temp.build.dir'], self._config['name'] + "_%s" % value + ".txt"), "w+", "utf-8" )
        self._policies[value].write(u"%s\n" % filename)


class PolicyRemoverMapper(PolicyMapper):
    """ This class implements a variant of the policy mapper.
        
    It removes the internal source. Only binary flagged content is kept.
    """
    
    def __init__(self, config, archiver):
        """ Initialization. """
        PolicyMapper.__init__(self, config, archiver)
        self._rm_policy_cache = {}

    def get_policy_root_dir(self):
        """ Return the policy.root.dir or root.dir if not set or not under root.dir."""
        if not self._config.has_key("policy.root.dir"):
            return os.path.normpath(self._config['root.dir'])
        else:
            if fileutils.destinsrc(self._config['root.dir'], self._config['policy.root.dir']):
                return os.path.normpath(self._config['policy.root.dir'])
            else:
                return os.path.normpath(self._config['root.dir'])

    def get_rmdir_policy(self, dirname):
        """ check if the directory should be dropped or not"""
        dirname = os.path.normpath(dirname)
        # check if parent is banned...
        prootdir = os.path.normpath(self.get_policy_root_dir())
        rootdir = os.path.normpath(self._config['root.dir'])
        if os.sep == '\\':
            dirname = dirname.lower()
            prootdir = prootdir.lower()
            rootdir = rootdir.lower()        
        
        # else get real value...
        if not self._rm_policy_cache.has_key(dirname):
            self._rm_policy_cache[dirname] = self.get_dir_policy(dirname)
        
        return self._rm_policy_cache[dirname]
        
    def create_commands(self, manifest):
        """ Generates a list of build commands. """
        stages = PolicyMapper.create_commands(self, manifest)
        
        if not self._config.has_key('policy.csv'):
            _logger.error("POLICY_ERROR: Property 'policy.csv' not defined everything will get removed.")
        cmds = []
        file_handle = codecs.open( manifest, "r", "utf-8" )
        for line in file_handle.readlines():
            line = line.rstrip()
            filepath = os.path.normpath(os.path.join(self._config.get('zip.root.dir', self._config['root.dir']), line))
            value = self.get_rmdir_policy(os.path.dirname(filepath))            
            delete = True
            if value in self._binary.keys():
                if self._binary[value] == "yes":
                    _logger.info("POLICY_INFO: Keeping %s (%s=>yes)!" % (filepath, value))
                    delete = False
                elif self._binary[value] == "bin":
                    _logger.info("POLICY_INFO: Keeping %s (%s=>bin)!" % (filepath, value))
                    delete = False
            else:
                _logger.error("POLICY_ERROR: %s value for %s not in csv file. Will be removed!!" % (value, filepath))
               
            if delete:
                _logger.info("POLICY_INFO: File %s will be removed!" % filepath)
                cmds.append(buildtools.Delete(filename=filepath))
        file_handle.close()
        if len(cmds) > 0:
            stages.append(cmds)
        return stages


class SFPolicyRemoverMapper(PolicyRemoverMapper):
    """ Implement an SFL column based policy remover. """

    def __init__(self, config, archiver):
        """ Initialization. """
        PolicyRemoverMapper.__init__(self, config, archiver)

    def load_policy_binary(self, csvfile):
        """ Loading the policy using the 3rd column. """
        _logger.info("POLICY_INFO: Loading actions from the 3rd column")
        PolicyRemoverMapper.load_policy_binary(self, csvfile, column=3)

class EPLPolicyRemoverMapper(PolicyRemoverMapper):
    """ Implement an EPL column based policy remover. """
    def __init__(self, config, archiver):
        """ Initialization. """
        PolicyRemoverMapper.__init__(self, config, archiver)

    def load_policy_binary(self, csvfile):
        """ Loading the policy using the 4th column. """
        _logger.info("POLICY_INFO: Loading actions from the 4th column")
        PolicyRemoverMapper.load_policy_binary(self, csvfile, column=4)
        
        
MAPPERS = {'default': DefaultMapper,
             'policy': PolicyMapper,
             'policy.remover': PolicyRemoverMapper,
             'sfl.policy.remover': SFPolicyRemoverMapper,
             'epl.policy.remover': EPLPolicyRemoverMapper,}

def get_mapper(name, config, archiver):
    """ Get mapper instance from its string id. """
    if name in MAPPERS:
        return MAPPERS[name](config, archiver)
    raise Exception("ERROR: Could not find mapper '%s'." % name)
