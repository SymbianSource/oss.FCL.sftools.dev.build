#============================================================================ 
#Name        : api.py 
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

import logging
logger = logging.getLogger("datasources.api")

class MissingProperty(Exception):
    """ An exception to indicate about a missing property """
    pass

class DataSource(object):
    """ This abstract class defines a DataSource for the packager application. """
    def __init__(self, epocroot, data=None):
        self.epocroot = epocroot
        self._data = data
        if data is None:
            self._data = {}
            
    def getComponents(self):
        """ The getComponents method must return a list of BuildData object (one per component).
            In case of error (e.g incomplete configuration) the method will raise an Exception.
        """
        raise NotImplementedError 

    def getHelp(self):
        return None
    
    help = property(lambda self: self.getHelp())


DATASOURCES = {}

def getDataSource(name, epocroot, data):
    if name in DATASOURCES:
        logger.debug("Creating datasource for %s." % name) 
        return DATASOURCES[name](epocroot, data)
    else:
        logger.info("Loading %s." % name)
        def class_import(name):
            try:
                components = name.split('.')
                klassname = components.pop()
                mod = __import__('.'.join(components), globals(), locals(), [klassname])
                return getattr(mod, klassname)
            except:
                raise Exception("Could not load %s" % name)
        return class_import(name)(epocroot, data)


def getDataSourceHelp():
    doc = ""
    for name in DATASOURCES:
        dshelp = DATASOURCES[name](None, None).help
        if dshelp is not None:
            doc = doc + "--- %s -----------------------------------\n" % name + dshelp +\
                    "\n------------------------------------------\n"
    return doc
