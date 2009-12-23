#============================================================================ 
#Name        : packageiad.py 
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

""" packageIAD.py module """

import os
import sys
import xml.dom.minidom
import iadinfo
import zipfile
import encodings.utf_8


class IADPackager :
    """ package IAD class "
    """
    
    def __init__(self) :
        """ class init method """
        self.hasStub = False

    def getBldDirs(self, layer, bldDirs) :
        """ get the list of build directories """
        units = layer.getElementsByTagName ("unit")
        for unit in units :
            dir = unit.getAttribute ("bldFile").rstrip ('\\/')
            i = dir.rfind ("\\")
            if i == - 1 :
                i = dir.rfind ("/")
            bldDirs.append (dir[:i + 1])
    
    def getLayer(self, configuration, layers, bldDirs) :
        """ get each layer info """
        layerRef = configuration.getElementsByTagName ("layerRef")[0].getAttribute ("layerName")
        for layer in layers :
            if layer.getAttribute ("name") == layerRef :
                self.getBldDirs (layer, bldDirs)
    
    def createInfoFiles(self, sisInfo) :
        """ create the INfo files depends.xml etc."""
        depends = xml.dom.minidom.parse ("depends.xml")
        info = xml.dom.minidom.parseString (sisInfo)
        
        infoFile = file ("sisinfo.xml", "w")
        packageDeps = info.getElementsByTagName("package_dependency")
        for packageDep in packageDeps :
            pack = depends.createElement ("package")
            depends.childNodes[1].appendChild (pack)
            for child in packageDep.childNodes :
                pack.appendChild (child)
        infoFile.write (info.toxml ())
        infoFile.close()
        depFile = file ("depends.xml", "w")
        depFile.write (depends.toxml ())
        depFile.close()
    
    def createSis(self, packageDir, packageName, makesis) :
        """ create the .sis file """
        sisReader = iadinfo.IADHandler()
        os.chdir (packageDir)
        sisPackage = packageName + ".sis"
        stubPackage = packageName + "_stub.sis"
        print "Creating", sisPackage
        cmd = makesis + " package.pkg " + sisPackage
        os.system (cmd)
        self.createInfoFiles (sisReader.getInfo(sisPackage))
        if os.path.exists(stubPackage) :
            print "Creating stub SIS file", stubPackage
            self.hasStub = True
            cmd = makesis + " -s package.pkg " + stubPackage
            os.system (cmd)
        
    def createPackage(self, topDir, packageName) :
        """ create the Data Package """
        print "Creating package", packageName
        os.chdir (topDir)
        zipFile = packageName + ".zip"
        sisFile = packageName + '/' + packageName + ".sis"
        infoFile = packageName + "/sisinfo.xml"
        depFile = packageName + "/depends.xml"
        zip = zipfile.ZipFile (zipFile, "w")
        zip.write (sisFile, sisFile.encode ("utf-8"))
        zip.write (infoFile, infoFile.encode ("utf-8"))
        zip.write (depFile, depFile.encode ("utf-8"))
        if self.hasStub :
            stubFile = packageName + '/' + packageName + "_stub.sis"
            zip.write (stubFile, stubFile.encode ("utf-8"))
        zip.close()
        
    
    def processSisDir(self, sisDir, makesis) :
        """ handle the directory used to create the .sis file """
        for root, dirs, _ in os.walk (sisDir):
            for name in dirs :
                self.createSis (os.path.join (root, name), name, makesis)
                self.createPackage (root, name)

def main(sysdefFile, sysdefconfigs, bldDrive):
    """ main to called when imported """
    makesis = bldDrive + "\\epoc32\\tools\\makesis.exe"
    
    sysdef = xml.dom.minidom.parse (sysdefFile)
    configurations = sysdef.getElementsByTagName ("configuration")
    layers = sysdef.getElementsByTagName ("layer")
    bldDirs = []
    
    packager = IADPackager()
    
    for configuration in configurations :
        if configuration.getAttribute ("name") == sysdefconfigs :
            packager.getLayer (configuration, layers, bldDirs)
     
    
    for bldDir in bldDirs :
        packager.processSisDir (bldDrive + bldDir + "sis\\", makesis)

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
