#============================================================================ 
#Name        : iqrf.py 
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
    Implements iQRF model.
    
    How to use it:
    import imaker.iqrf
    root = imaker.iqrf.load(filename)
    root.result
"""
import amara
import logging
from  imaker.ecore import ContainerBase, Reference       

logging.basicConfig()
logger = logging.getLogger("iqrf.model")
#logger.setLevel(logging.DEBUG)

        
class IMaker(ContainerBase):
    """ IMaker container. """
    def __init__(self, parent=None):
        ContainerBase.__init__(self, parent)
        self.result = None

    def load(self, node):
        """ Load data from XML node. """
        if hasattr(node, 'result'):
            logger.debug("IMaker has result attribute.")
            self.result = Result(self)
            self.result.load(node.result)


class Result(ContainerBase):
    """ Result container. """
    def __init__(self, parent=None):
        ContainerBase.__init__(self, parent)
        self.interfaces = []
        self.configurations = []
        self.targets = []

    def load(self, node):
        """ Load data from XML node. """
        logger.debug("Loading Result")
        for elem in node.interfaces:
            interface = Interface(self)
            interface.load(elem)
            self.interfaces.append(interface)
        for elem in node.configurations:
            configuration = Configuration(self)
            configuration.load(elem)
            self.configurations.append(configuration)
        for elem in node.targets:
            target = Target(self)
            target.load(elem)
            self.targets.append(target)

class Configuration(ContainerBase):
    """ Configuration container. """

    def __init__(self, parent=None):
        ContainerBase.__init__(self, parent)
        self.name = None
        self.settings = []
        self.filePath = None
        self.targetrefs = []

    def load(self, node):
        """ Load data from XML node. """
        logger.debug("Loading Configuration")
        self.name = node.name        
        self.filePath = node.filePath
        for elem in node.xml_xpath('./settings'):
            setting = Setting(self)
            setting.load(elem)
            self.settings.append(setting)
            
        for ref in node.targetrefs.split(" "):
            self.targetrefs.append(Reference(self, ref))

class Setting(ContainerBase):

    def __init__(self, parent=None):
        ContainerBase.__init__(self, parent)
        self.name = None
        self.value = None
        self.ref = None

    def load(self, node):        
        logger.debug("Loading Setting")
        self.name = node.name        
        self.value = node.value        
        self.ref = Reference(node.ref)        

    
class Interface(ContainerBase):
    """ Interface container. """
    def __init__(self, parent=None):
        ContainerBase.__init__(self, parent)
        self.name = None
        self.configurationElements = []

    def load(self, node):
        """ Load data from XML node. """
        logger.debug("Loading Interface")
        self.name = node.name        
        for cel in node.configurationElements:
            conf = ConfigurationElement(self)
            conf.load(cel)
            self.configurationElements.append(conf)
    
class ConfigurationElement(ContainerBase):
    """ ConfigurationElement container. """
    def __init__(self, parent=None):
        ContainerBase.__init__(self, parent)
        self.name = None
        self.description = None
        self.values = None

    def load(self, node):
        """ Load data from XML node. """
        logger.debug("Loading ConfigurationElement")
        self.name = node.name        
        self.description = node.description
        self.values = node.values

class Target(ContainerBase):
    """ Target container. """

    def __init__(self, parent=None):
        ContainerBase.__init__(self, parent)
        self.name = None
        self.description = None

    def load(self, node):
        """ Load data from XML node. """
        logger.debug("Loading Target")
        self.name = node.name        
        self.description = node.description

        


def load(filename):
    """ Load IMaker serialized ecore configuration. """
    doc = amara.parse(open(filename, 'r'))
    imaker = IMaker()    
    imaker.load(doc.IMaker)
    return imaker
    
        