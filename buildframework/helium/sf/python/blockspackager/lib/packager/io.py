#============================================================================ 
#Name        : io.py 
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
import xml.dom.minidom
import logging
from Blocks.Packaging.BuildData import BdFile, PlainBuildData
logger = logging.getLogger('io')

class BdFileSerializer:
    """ Class used to serialize or deserialize the DBFile """
    def __init__(self, bdfile=None):
        self.bdfile = bdfile 

    def toXml(self):
        logger.debug("Serializing DBFile.")
        document = xml.dom.minidom.Document()
        component = document.createElement('bdfile')
        component.setAttribute('path', self.bdfile.getPath())
        if self.bdfile.variantType  is not None:
            component.setAttribute('variantType', self.bdfile.variantType)
        if self.bdfile.variantPlatform is not None:
            component.setAttribute('variantPlatform', self.bdfile.variantPlatform)
        # Owner reqs
        ownerReqs = document.createElement('ownerRequirements')
        for path in self.bdfile.ownerRequirements:
            req = document.createElement("ownerRequirement")
            req.setAttribute('path', path)
            ownerReqs.appendChild(req)
        component.appendChild(ownerReqs)
        # source Requirements
        srcReqs = document.createElement('sourceRequirements')
        for path in self.bdfile.sourceRequirements:
            req = document.createElement("sourceRequirement")
            req.setAttribute('path', path)
            srcReqs.appendChild(req)
        component.appendChild(srcReqs)
        return component.toxml()

    def fromXml(self, data):
        logger.debug("Deserializing DBFile.")
        node = xml.dom.minidom.parseString(data).childNodes[0]
        if self.bdfile == None:
            self.bdfile = BdFile(node.getAttribute('path'))
        
        self.bdfile.path = node.getAttribute('path')
        self.bdfile.variantPlatform = node.getAttribute('variantPlatform')
        self.bdfile.variantType = node.getAttribute('variantType')
        for src in node.getElementsByTagName('ownerRequirements')[0].getElementsByTagName('ownerRequirement'):
            self.bdfile.ownerRequirements.append(src.getAttribute('path'))
        for src in node.getElementsByTagName('sourceRequirements')[0].getElementsByTagName('sourceRequirement'):
            self.bdfile.sourceRequirements.append(src.getAttribute('path'))
        return self.bdfile
        
class BuildDataSerializer:
    """ Class used to serialize or deserialize the plain build data """
    def __init__(self, builddata=None):
        self.builddata = builddata
        if  self.builddata is None:
            self.builddata = PlainBuildData()
            
    def toXml(self):
        logger.debug("Serializing PlainBuildData.")
        document = xml.dom.minidom.Document()
        component = document.createElement('component')
        component.setAttribute('name', self.builddata.getComponentName())
        component.setAttribute('version', self.builddata.getComponentVersion())
        # sources
        sources = document.createElement('sources')
        sources.setAttribute('root', self.builddata.getSourceRoot())        
        for path in self.builddata.getSourceFiles():
            source = document.createElement("source")
            source.setAttribute('path', path)
            sources.appendChild(source)
        component.appendChild(sources)
        # targets
        targets = document.createElement('targets')        
        targets.setAttribute('root', self.builddata.getTargetRoot())
        for path in self.builddata.targetFiles.keys():
            target = document.createElement("target")
            target.setAttribute('path', path)
            if self.builddata.targetFiles[path] is not None:
                target.appendChild(document.importNode(xml.dom.minidom.parseString(BdFileSerializer(self.builddata.targetFiles[path]).toXml()).childNodes[0], deep=1))
            targets.appendChild(target)        
        component.appendChild(targets)
        return component.toxml()

    def fromXml(self, data):
        logger.debug("Deserializing PlainBuildData.")
        node = xml.dom.minidom.parseString(data).childNodes[0]
        self.builddata.setComponentName(node.getAttribute('name'))
        self.builddata.setComponentVersion(node.getAttribute('version'))
        self.builddata.setSourceRoot(node.getElementsByTagName('sources')[0].getAttribute('root'))
        self.builddata.setTargetRoot(node.getElementsByTagName('targets')[0].getAttribute('root'))
        files = []
        for src in node.getElementsByTagName('sources')[0].getElementsByTagName('source'):
            files.append(src.getAttribute('path'))
        self.builddata.addSourceFiles(files)

        files = []
        for target in node.getElementsByTagName('targets')[0].getElementsByTagName('target'):
            files.append(target.getAttribute('path'))
        self.builddata.addTargetFiles(files)
        for target in node.getElementsByTagName('targets')[0].getElementsByTagName('target'):
            for bdfile in target.getElementsByTagName('bdfile'):
                self.builddata.addDeliverable(BdFileSerializer().fromXml(bdfile.toxml()))
        return self.builddata


class BuildDataMerger:
    """ Class used to merge contents of build data """
    def __init__(self, output):
        self.output = output

    def merge(self, bd):
        """ Merge the content of bd into output. """
        if bd.getComponentName() != self.output.getComponentName():
            raise Exception("Trying to merger two different components (different name)")
        if bd.getComponentVersion() != self.output.getComponentVersion():
            raise Exception("Trying to merger two different components (different version)")        
        if bd.getSourceRoot() != self.output.getSourceRoot():
            raise Exception("Trying to merger two different components (different source root)")
        if bd.getTargetRoot() != self.output.getTargetRoot():
            raise Exception("Trying to merger two different components (different target root)")
        self.output.addSourceFiles(bd.getSourceFiles())
        self.output.addTargetFiles(bd.getTargetFiles())
        for dep in bd.getDependencies():
            self.output.addDeliverable(dep)
        return self.output
