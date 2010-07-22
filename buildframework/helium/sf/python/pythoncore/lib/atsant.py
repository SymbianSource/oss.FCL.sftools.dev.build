# -*- encoding: latin-1 -*-

#============================================================================ 
#Name        : atsant.py 
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

""" get the files needed to test ATS"""

import re
import sysdef.api
import os
import logging
import configuration

_logger = logging.getLogger('atsant')

class IConfigATS(object):
    """ Class used to read configuration file iconfig.xml """
    def __init__(self, imagesdir, productname):
        self.imagesdir = imagesdir
        self.productname = productname
        self.config = self.getconfig()
        
    def getconfig(self, type=None, productname=None):
        """get configuration"""
        noncust = None
        for root, _, files in os.walk(self.imagesdir, topdown=False):
            for fname in files:
                if 'iconfig.xml' in fname:
                    filePath = os.path.join(root, fname)
                    configBuilder = configuration.NestedConfigurationBuilder(open(filePath, 'r'))
                    configSet = configBuilder.getConfiguration()
                    for config in configSet.getConfigurations():
                        if type and productname:
                            if type in config.type and config['PRODUCT_NAME'] in productname:
                                return config
                        else:
                            noncust = config
        if type:
            return None
        if noncust:
            return noncust
        raise Exception('iconfig not found in ' + self.imagesdir)
    
    def getimage(self, name):
        """get image"""
        for root, _, files in os.walk(self.imagesdir, topdown=False):
            for fname in files:
                if fname.lower() == name.lower():
                    return os.path.join(root, fname)
        raise Exception(name + ' not found in ' + self.imagesdir)
    
    def findimages(self): 
        """find images"""
        output = ''
        for imagetype, imagetypename in [('core', 'CORE'), ('langpack', 'ROFS2'), ('cust', 'ROFS3'), ('udaerase', 'UDAERASE')]:
            iconfigxml = self.getconfig(imagetype, self.productname)
            if iconfigxml == None:
                iconfigxml = self.config

            if iconfigxml.has_key(imagetypename + '_FLASH'):
                (drive, _) = os.path.splitdrive(self.imagesdir)
                image = os.path.join(drive, iconfigxml[imagetypename + '_FLASH'])
                if not os.path.exists(image):
                    image = self.getimage(os.path.basename(image))
                if os.path.exists(image):
                    output = output + image + ','
                else:
                    raise Exception(image + ' not found')
            else:
                if imagetype == 'core':
                    raise Exception(imagetypename + '_FLASH not found in iconfig.xml in ' + self.imagesdir)
                print imagetypename + '_FLASH not found in iconfig.xml'
        return output

def files_to_test(canonicalsysdeffile, excludetestlayers, idobuildfilter, builddrive):
    """list the files to test"""
    sdf = sysdef.api.SystemDefinition(canonicalsysdeffile)

    modules = {}
    for layr in sdf.layers:
        if re.match(r".*_test_layer$", layr):
# pylint: disable-msg=W0704
            try:
                if re.search(r"\b%s\b" % layr, excludetestlayers):
                    continue
            except TypeError:       #needed to catch exceptions and not have them printed
                pass
# pylint: enable-msg=W0704

            layer = sdf.layers[layr]
            for mod in layer.modules:
                if mod.name not in modules:
                    modules[mod.name] = []
                for unit in mod.units:
                    include_unit = True
                    if idobuildfilter != None:
                        if idobuildfilter != "":
                            include_unit = False
                            if hasattr(unit, 'filters'):
                                if len(unit.filters) > 0:
                                    for afilter in unit.filters:
                                        if re.search(r"\b%s\b" % afilter, idobuildfilter):
                                            include_unit = True
                                        else:
                                            include_unit = False
                                elif len(unit.filters) == 0:
                                    include_unit = True
                            else:
                                include_unit = False
                        else:
                            include_unit = False
                            if hasattr(unit, 'filters'):
                                if len(unit.filters) == 0:
                                    include_unit = True
                    if include_unit:
                        modules[mod.name].append(os.path.join(builddrive + os.sep, unit.path))

    return modules
