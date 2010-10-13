#============================================================================ 
#Name        : cli.py 
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
import sys
import re
import os
import xml.dom.minidom
from optparse import OptionParser
import Blocks
from packager.io import BuildDataSerializer, BuildDataMerger
from Blocks.Packaging.DependencyProcessors.DefaultProcessors import BuildDataDependencyProcessor
import packager.datasources
import logging
logging.basicConfig(level=logging.INFO)




class PackagerApp:
    """ The packager CLI implementation. """
    def __init__(self):
        self.logger = logging.getLogger("packager")
        self.cli = OptionParser(usage="%prog [options]")
        self.cli.add_option("--epocroot", metavar="DIR", help="Epocroot location (must be an absolute path)")
        self.cli.add_option("--config", metavar="DIR")
        self.cli.add_option("--outputdir", metavar="DIR")
        self.cli.add_option("--datasource", metavar="NAME")
        self.cli.add_option("--metadatadir", metavar="DIR")
        self.cli.add_option("--updateData", action="store_true", dest="action_update", default=False)
        self.cli.add_option("--createBundles", action="store_true", dest="action_bundle", default=False)
        self.cli.add_option("--help-datasource", action="store_true", dest="action_help_datasource", default=False)
        self.cli.add_option("--workers", type="int", dest="workers", default=4)
        self.cli.add_option("--writer", dest="writer", default='deb')
        self.cli.add_option("--sourceRules", dest="sourceRules")
        self.cli.add_option("--targetRules", dest="targetRules")
        self.cli.add_option("--pkgDirectives", dest="pkgDirectives")
        self.cli.add_option("--debug", action="store_true", default=False)
        self.cli.add_option("--interdeps", choices=['true', 'false'], dest="interdeps", default='false')
        self.__workers = 4
        self.__writer = "deb"
        self.__config = None
        self.__epocroot = None
        self.__datasource = None
        self.__update = False
        self.__bundle = False
        self.__help_datasource = False
        self.__outputdir = None
        self.__source_rules = None
        self.__target_rules = None
        self.__directives = None
        self.__metadatadir = None
        self.__interdeps = None
        self.__writerOptions = None
        self.__data = {}

    def __readoptions(self, argv=sys.argv):
        # removing -Dxxx=xxx
        args = []
        for arg in argv:
            res = re.match("-D(.+)=(.*)", arg)
            if res is not None:
                self.logger.debug("property: %s=%s" % (res.group(1), res.group(2)))
                self.__data[res.group(1)] = res.group(2)
            else:
                args.append(arg)
        
        opts, dummy_args = self.cli.parse_args(args)
        self.__config = opts.config
        self.__epocroot = opts.epocroot
        self.__outputdir = opts.outputdir
        self.__update = opts.action_update
        self.__bundle = opts.action_bundle
        self.__help_datasource = opts.action_help_datasource
        self.__datasource = opts.datasource
        self.__workers = opts.workers
        self.__writer = opts.writer
        self.__source_rules = opts.sourceRules
        self.__target_rules = opts.targetRules
        self.__directives = opts.pkgDirectives
        self.__metadatadir = opts.metadatadir
        self.__interdeps = opts.interdeps
        if opts.debug:
            logging.getLogger().setLevel(logging.DEBUG)

    def __update_data(self):
        if self.__config is None:
            raise Exception("--config argument is missing.")
        if self.__epocroot is None:
            raise Exception("--epocroot argument is missing.")
        if not os.path.exists(self.__config) or not os.path.isdir(self.__config):
            raise Exception("Could not find directory: %s." % self.__config)
        if not os.path.exists(self.__epocroot) or not os.path.isdir(self.__epocroot) or not os.path.isabs(self.__epocroot):
            raise Exception("Could not find directory: %s." % self.__epocroot)
        if self.__datasource is None:
            raise Exception("--datasource argument is missing.")
        
        self.logger.info("Retrieving components information...")
        datasource = packager.datasources.getDataSource(self.__datasource, self.__epocroot, self.__data)
        for component in datasource.getComponents():
            outfilename = os.path.join(self.__config, component.getComponentName() + ".blocks_component.xml")
            if os.path.exists(outfilename):
                bd = BuildDataSerializer().fromXml(open(outfilename).read())
                self.logger.info("Merging with previous data...")
                component = BuildDataMerger(bd).merge(component)
            serializer = BuildDataSerializer(component)
            self.logger.info("Writing %s" % outfilename)
            output = open(outfilename , 'wb')
            output.write(xml.dom.minidom.parseString(serializer.toXml()).toprettyxml())
            output.close()            
               
    def __create_bundles(self):
        if self.__config is None:
            raise Exception("--config argument is missing.")
        if self.__epocroot is None:
            raise Exception("--epocroot argument is missing.")
        if self.__metadatadir is None:
            raise Exception("--metadatadir argument is missing.")
        if not os.path.exists(self.__config) or not os.path.isdir(self.__config):
            raise Exception("Could not find directory: %s." % self.__config)
        if not os.path.exists(self.__epocroot) or not os.path.isdir(self.__epocroot) or not os.path.isabs(self.__epocroot):
            raise Exception("Could not find directory: %s." % self.__epocroot)
        if self.__outputdir is None:
            raise Exception("--outputdir argument is missing.")
        if not os.path.exists(self.__outputdir) or not os.path.isdir(self.__outputdir):
            raise Exception("Could not find directory: %s." % self.__epocroot)
        if not os.path.exists(self.__metadatadir) or not os.path.isdir(self.__metadatadir):
            raise Exception("Could not find directory: %s." % self.__metadatadir)
        
        if self.__interdeps == 'false':
            self.__writerOptions = {'STRONG_DEP_MAPPING': None}
        
        # Creating the packager.
        storage = Blocks.Packaging.OneoffStorage(self.__metadatadir)
        packager_obj = Blocks.Packaging.Packager(storage,
                                             self.__outputdir,
                                             maxWorkers = self.__workers,
                                             writer = self.__writer,
                                             targetRules = self.__target_rules,
                                             sourceRules = self.__source_rules,
                                             directives = self.__directives,
                                             writerOptions = self.__writerOptions
                                             #startNow=False
                                             )
        # Adding processors
        packager_obj.addProcessor(BuildDataDependencyProcessor)
        try:
            from Blocks.Packaging.DependencyProcessors.RaptorDependencyProcessor import DotDeeDependencyProcessor 
            packager_obj.addProcessor(DotDeeDependencyProcessor)
        except ImportError:
            logging.warning("Could not load DotDeeDependencyProcessor.")

        for filename in os.listdir(self.__config):
            filename = os.path.normpath(os.path.join(self.__config, filename))
            if not filename.endswith('.blocks_component.xml'):
                continue
            self.logger.info("Loading %s" % filename)
            packager_obj.addComponent(BuildDataSerializer().fromXml(open(filename, 'r').read()))
        
        packager_obj.wait()
    
    def execute(self, argv=sys.argv):
        """ Run the CLI. """
        try:
            self.__readoptions(argv)
            if self.__help_datasource: 
                print packager.datasources.getDataSourceHelp()
            elif self.__update:
                self.__update_data()
            elif self.__bundle:
                self.__create_bundles()
            else:
                self.cli.print_help()
        except IOError, exc:
            if self.logger.getEffectiveLevel() == logging.DEBUG:
                self.logger.exception(exc)
            self.logger.error(str(exc))
            return -1
        return 0
        
        
if __name__ == "__main__":
    app = PackagerApp()
    sys.exit(app.execute())

