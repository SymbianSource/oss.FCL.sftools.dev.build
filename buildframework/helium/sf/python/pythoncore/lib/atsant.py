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
import amara

_logger = logging.getLogger('atsant')

class IConfigATS(object):
    """ Class used to read configuration file iconfig.xml """
    def __init__(self, imagesdir, productname):
        self.imagesdir = imagesdir
        self.productname = productname
        self.config = self.getconfig()
        
    def getconfig(self, type_=None, productname=None):
        """get configuration"""
        noncust = None
        for root, _, files in os.walk(self.imagesdir, topdown=False):
            for fname in files:
                if 'iconfig.xml' in fname:
                    filePath = os.path.join(root, fname)
                    configBuilder = configuration.NestedConfigurationBuilder(open(filePath, 'r'))
                    configSet = configBuilder.getConfiguration()
                    for config in configSet.getConfigurations():
                        if type_ and productname:
                            if type_ in config.type and config['PRODUCT_NAME'].lower() in productname.lower():
                                return config
                        else:
                            noncust = config
        if type_:
            return None
        if noncust:
            return noncust
        raise IOError('iconfig not found in ' + self.imagesdir)
    
    def getimage(self, name):
        """get image"""
        for root, _, files in os.walk(self.imagesdir, topdown=False):
            for fname in files:
                if fname.lower() == name.lower():
                    return os.path.join(root, fname)
        raise IOError(name + ' not found in ' + self.imagesdir)
    
    def findimages(self): 
        """find images"""
        output = ''
        for imagetype, imagetypename in [('core', 'CORE'), ('langpack', 'ROFS2'), ('cust', 'ROFS3'), ('udaerase', 'UDAERASE'), ('emmc', 'EMMC')]:
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
                    raise IOError(image + ' not found')
            else:
                if imagetype == 'core':
                    raise IOError(imagetypename + '_FLASH not found in iconfig.xml in ' + self.imagesdir)
                print imagetypename + '_FLASH not found in iconfig.xml'
        return output

def get_boolean(string_val):
    """if parameter passed in is not present in the project it will produce 'none'
       as a result so this will be converted to boolean false as will all values
        except true."""
    retVal = False
    if (string_val == 'true'):
        retVal = True
    return retVal


def files_to_test(canonicalsysdeffile, excludetestlayers, idobuildfilter, builddrive, createmultipledropfiles, sysdef3=False):
    """list the files to test"""
    modules = {}
    if sysdef3 == True:
        sdf = amara.parse(open(canonicalsysdeffile))
        for package in sdf.SystemDefinition.systemModel.package:
            for collection in package.collection:
                if hasattr(collection, 'component'): 
                    for component in collection.component:
                        print component.id
                        if get_boolean(createmultipledropfiles):
                            group = 'singledropfile'
                        else:
                            group = 'default'
                        if hasattr(component, 'meta') and hasattr(component.meta, 'group'):
                            if not group.lower() == 'singledropfile':
                                group = component.meta.group[0].name                            
                        if hasattr(component, 'unit'):
                            for unit in component.unit:
                                if group not in modules:
                                    modules[group] = []
                                if os.sep == '\\':
                                    modules[group].append(builddrive + os.sep + unit.bldFile)
                                else:
                                    modules[group].append(unit.bldFile)
    else:
        sdf = sysdef.api.SystemDefinition(canonicalsysdeffile)
        
        single_key = 'singledropfile'       #default single drop file name
       
        for layr in sdf.layers:
            if re.match(r".*_test_layer$", layr):
                if excludetestlayers and re.search(r"\b%s\b" % layr, excludetestlayers):
                    continue
                layer = sdf.layers[layr]
                for mod in layer.modules:
                    if get_boolean(createmultipledropfiles):  #creating single drop file?
                        if single_key not in modules:       #have we already added the key to the dictionary?
                            modules[single_key] = []        #no so add it
                    elif mod.name not in modules:
                        modules[mod.name] = []
                        single_key = mod.name               #change the key name to write to modules
                    for unit in mod.units:
                        include_unit = True
                        if idobuildfilter != None:
                            if idobuildfilter != "":
                                include_unit = False
                                if hasattr(unit, 'filters'):
                                    if len(unit.filters) > 0:
                                        for afilter in unit.filters:
                                            include_unit = re.search(r"\b%s\b" % afilter, idobuildfilter)
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
                            modules[single_key].append(builddrive + os.sep + unit.path)
    return modules

