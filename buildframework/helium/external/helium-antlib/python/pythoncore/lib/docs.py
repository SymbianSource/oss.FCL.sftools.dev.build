#============================================================================ 
#Name        : docs.py 
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

""" Modules related to documentation """

from __future__ import with_statement
import re
import os
import amara

def find_python_dependencies(setpath, dbPath, dbPrj):
    """ Search python dependencies """
    for root, dirs, files in os.walk(setpath, topdown=False):
        for fname in files:
            filePattern = re.compile('.ant.xml$')
            fileMatch = filePattern.search(fname)
            modulelist = []
            if (fileMatch):
                filePath = os.path.abspath(os.path.join(root, fname))
                with open(filePath) as f:
                    filePathAmara = 'file:///'+ filePath.replace('\\','/')
                    curPrj=amara.parse(filePathAmara)
                    for line in f:
                        linePattern = re.compile('^import')
                        lineMatch = linePattern.search(line)
                        if ((lineMatch) and (line.find('.')==-1)):
                            newLine = line.replace('import','')
                            newLine = newLine.replace(',','')
                            moduleArray = newLine.split()
                            for curModule in moduleArray:
                                try:
                                    importModule = __import__(curModule)
                                    if hasattr(importModule, '__file__'):
                                        modulePath=importModule.__file__
                                        if 'helium' in modulePath:
                                            for projectList in dbPrj.antDatabase.project:
                                                if (projectList.name == curPrj.project.name):
                                                    if not (curModule in modulelist):
                                                        print " Python module : " + curModule
                                                        moduleElement = projectList.pythonDependency.xml_create_element(u'module', content=u''+curModule)
                                                        projectList.pythonDependency.xml_append(moduleElement)
                                                    modulelist = modulelist + [curModule]
                                except ImportError, e:
                                    pass