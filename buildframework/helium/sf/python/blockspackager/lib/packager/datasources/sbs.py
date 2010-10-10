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

import xml.sax
import time
import os
import re
import fileutils
import sys
from packager.datasources.api import DataSource, MissingProperty, DATASOURCES
from Blocks.Packaging.DataSources.LinkInfoToBuildData import LinkInfoXmlReader # pylint: disable=F0401
try:
    from Blocks.Packaging.DataSources.SbsLinkInfoReader import LinkInfoReader # pylint: disable=E0611
except ImportError:
    if os.path.sep == '\\': 
        raptor_cmd = fileutils.which("sbs.bat")
    else:
        raptor_cmd = fileutils.which("sbs")
    sbs_home = os.path.dirname(os.path.dirname(raptor_cmd))
    os.environ['SBS_HOME'] = sbs_home
    sys.path.append(os.path.join(sbs_home, 'python'))
    sys.path.append(os.path.join(sbs_home, 'python', 'plugins'))
    # loading as raptor plugin - loading also raptor.
    if os.path.sep == '\\': 
        os.environ['HOSTPLATFORM'] = 'win 32'
        os.environ['HOSTPLATFORM_DIR'] = 'win32'
    else:
        os.environ['HOSTPLATFORM'] = 'linux'
        os.environ['HOSTPLATFORM_DIR'] = 'linux'
    from filter_blocks import LinkInfoReader # pylint: disable=F0401
 
from Blocks.Packaging.BuildData import PlainBuildData
from Blocks.Packaging.DataSources.WhatLog import WhatLogReader as LogReader
import logging
from Queue import Queue
from threading import Thread

class ComponentNotFound(Exception):
    """ Error raised in case of not found component. """
    
    def __init__(self, message):
        Exception.__init__(self, message)

class SysdefComponentList(xml.sax.ContentHandler):
    """ Simplistic sysdef data extractor, it will only get data from unit elements."""
    
    def __init__(self, epocroot, version="1"):
        xml.sax.ContentHandler.__init__(self)
        self.__data = {}
        self.__epocroot = epocroot
        self.__version = version
        self.__component = None
    
    def startElement(self, tag, attributes):
        if tag == "component" and attributes.get("id"):
            self.__component = attributes.get("id")
        elif tag == "unit" and self.__component and not attributes.get("unitID") and not attributes.get("name") and attributes.get("bldFile"):
            data = {}
            data['path'] = os.path.normpath(os.path.join(self.__epocroot, attributes.get("bldFile")).replace('\\', os.sep).replace('/', os.sep))
            if attributes.get("version") is None:
                data['version'] = self.__version
            else:
                data['version'] = attributes.get("version")
            data['name'] = self.__cleanup_name(self.__component) 
            self.__data[self.__component + attributes.get("bldFile").replace('\\', '_').replace('/', '_')] = data
        elif tag == "unit" and attributes.get("name") is not None and attributes.get("bldFile") is not None:
            data = {}
            data['path'] = os.path.normpath(os.path.join(self.__epocroot, attributes.get("bldFile")).replace('\\', os.sep).replace('/', os.sep))
            if attributes.get("version") is None:
                data['version'] = self.__version
            else:
                data['version'] = attributes.get("version")
            data['name'] = self.__cleanup_name(attributes.get("name")) 
            self.__data[self.__cleanup_name(attributes.get("name"))] = data

    def endElement(self, tag):
        if tag == "component":
            self.__component = None
        
    def __cleanup_name(self, name):
        return re.sub(r'[^a-zA-Z0-9_-]', '', re.sub(r'\.', '_', name))
    
    def keys(self):
        return self.__data.keys()
    
    def __getitem__(self, key):
        return self.__data[key]

    def __contains__(self, key):
        for data in self.__data:
            if key in data['name']:
                return True
        return False
    
    def __len__(self):
        return self.__data.__len__()

    def get_component_name_by_path(self, dir_):
        dir_ = os.path.normpath(dir_)
        for key in self.__data.keys():
            if dir_.lower() == self.__data[key]['path'].lower():
                return key
        raise ComponentNotFound("Could not find component name for dir %s" % dir_)

    def __str__(self):
        return "<%s: %s>" % (type(self), self.__data)


class BldInfWorker(Thread):
    """ SBS component worker. """
    def __init__(self, inqueue, outqueue, datasource, whatlog, cl, link_info):
        Thread.__init__(self)
        self.logger = logging.getLogger(self.__class__.__name__)
        self.inqueue = inqueue
        self.outqueue = outqueue
        self.whatlog = whatlog
        self.cl = cl
        self.link_info = link_info
        self.datasource = datasource
    
    def run(self):
        """ Thread implementation. """
        while True:
            tag, bldinf = self.inqueue.get()
            if tag == 'STOP':
                self.logger.debug("Builder thread exiting..." )
                return
            else:
                try:
                    tick = time.time()
                    self.outqueue.put(self.datasource.getBuildData(bldinf, self.whatlog, self.cl, self.link_info))
                    tock = time.time()
                    self.logger.info("Analyzed component %s in %s seconds" % (bldinf, tock - tick))
                except IOError, exc:
                    self.logger.error('Error happened in thread execution %s' % exc)
                    import traceback
                    self.logger.debug(traceback.format_exc())
                    

class SBSDataSource(DataSource):
    """ That class implements the DataSource API"""
    
    def __init__(self, epocroot, data=None):
        DataSource.__init__(self, epocroot, data)
        self.logger = logging.getLogger(self.__class__.__name__)
        
    def _get_sysdef_info(self):
        """ Returns a SysdefComponentList containing the result of sysdef parsing. """
        self.logger.debug("Reading the component information from the sysdef (%s)." % self._data['sysdef'])
        p = xml.sax.make_parser()
        cl = SysdefComponentList(self.epocroot)
        p.setContentHandler(cl)
        p.parse(open(self._data['sysdef']))
        return cl

    def _get_whatlog(self):
        self.logger.debug("Extracting whatlog data (%s)..." % self._data['sbslog'])
        parser = xml.sax.make_parser()
        lr = LogReader()
        parser.setContentHandler(lr)
        file_ = open(self._data['sbslog'])
        while True:
            data = file_.read()
            if not data:
                break
            parser.feed(data)
        file_.close()
        parser.close()
        return lr

    def _generate_link_info(self, output=None):
        """ Generate the link.info file from the build log. It returns the generated xml filename. """
        self.logger.info("Generating the link information from the %s log." % self._data['sbslog'])
        parser = xml.sax.make_parser()
        reader = LinkInfoReader(self.epocroot)
        parser.setContentHandler(reader)
        parser.parse(open(self._data['sbslog'], 'r'))
        if output is None:
            output = self._data['sbslog'] + ".link.xml"
        self.logger.info("Writing %s." % output)
        out = open(output, 'wb')
        reader.writeXml(out=out)
        out.close()
        return output

    def getComponents(self):
        if 'sbslog' not in self._data:
            raise MissingProperty("The sbslog property has not be defined.") 
        if 'sysdef' not in self._data:
            raise MissingProperty("The sysdef property has not be defined.")
        
        # generating link info
        link_info = LinkInfoXmlReader.getBuildData(self._generate_link_info())

        # Read the component list
        cl = self._get_sysdef_info()
    
        # Get the whatlog
        whatlog = self._get_whatlog()
        
        result = []
        if 'threads' in self._data and self._data['threads'].isdigit():
            inqueue = Queue()
            outqueue = Queue()
            workers = []
            # Work to be done
            
            for bldinf in whatlog.getInfs():
                inqueue.put(('', bldinf))
            # Creating the builders 
            for i in range(int(self._data['threads'])):
                b = BldInfWorker(inqueue, outqueue, self, \
                              whatlog, cl, link_info)
                workers.append(b)
                b.start()
            # Waiting the work to finish.
            for w in workers:
                inqueue.put(('STOP', None))
            for w in workers:
                w.join()
            self.logger.info("All done.")
            while not outqueue.empty():
                result.append(outqueue.get())
        else:
            for bldinf in whatlog.getInfs():
                result.append(self.getBuildData(bldinf, whatlog, cl, link_info))
        return result
    
    def getBuildData(self, bldinf, whatlog, cl, link_info):
        """ Get the build data from a bldinf name. """
        tick = time.time()
        src_walk_path = ""
        abs_bldinf = os.path.abspath(bldinf)
        self.logger.debug("component location:   %s" % abs_bldinf)
        component_name = cl.get_component_name_by_path(os.path.normpath(os.path.dirname(abs_bldinf)))
        build_data = PlainBuildData()
        self.logger.debug("component name:       %s" % cl[component_name]['name'])
        build_data.setComponentName(cl[component_name]['name'])
        self.logger.debug("component version:    %s" % cl[component_name]['version'])
        build_data.setComponentVersion(cl[component_name]['version']) # need to get it from a the sysdef file
        build_data.setSourceRoot(self.epocroot)
        build_data.setTargetRoot(self.epocroot)
        
        targets = [path[len(self.epocroot):].lstrip(os.sep) for path in whatlog.getFilePaths(abs_bldinf)]
        build_data.addTargetFiles(targets)
        
        # If path contains group folder then parent to parent is required else parent folder is enough
        if os.path.dirname(abs_bldinf).endswith("group"):
            src_walk_path = os.path.dirname(os.path.dirname(abs_bldinf))
        else:
            src_walk_path = os.path.dirname(abs_bldinf)

        sources = []
        for (path, dirpath, namelist) in os.walk(src_walk_path):
            for name in namelist:
                sources.append(os.path.join(path, name)[len(self.epocroot):].lstrip(os.sep))
        build_data.addSourceFiles(sources)
        tock = time.time()
        self.logger.info(" + Content analysis %s in %s seconds" % (bldinf, tock - tick))
    
        tick = time.time()
        key_bldinf = abs_bldinf.replace(os.sep, '/')
        if link_info.has_key(key_bldinf):
            self.logger.debug("Found deps for %s" % key_bldinf)
            for bdfile in link_info[key_bldinf].getDependencies():
                if bdfile.getPath() in build_data.getTargetFiles():
                    # no dependency data above, only paths - OK to overwrite
                    build_data.addDeliverable(bdfile)
                else:
                    self.logger.warning("Link data from %s has unlisted target %s" % (abs_bldinf, bdfile.getPath()))
        tock = time.time()
        self.logger.info(" + Dependency analysis for %s in %s seconds" % (bldinf, tock - tick))
        return build_data

    def getHelp(self):
        help_ = """The sbs datasource will extract component information from the sbs logs. You need a recent version of raptor: e.g 2.8.4.
Plugin property configuration:
sbslog                 Location of the sbs log.
sysdef                 Location of the canonical system definition file.
        """
        return help_

DATASOURCES['sbs'] = SBSDataSource
