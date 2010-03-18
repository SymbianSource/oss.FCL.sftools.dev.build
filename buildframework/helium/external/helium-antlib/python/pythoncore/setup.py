#============================================================================ 
#Name        : .py 
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
import os
from setuptools import setup, find_packages
pyfiles = []
for x in os.listdir('lib'):
    if x.endswith('.py'):
        pyfiles.append(x.replace('.py', ''))
setup(
    name = 'pythoncore',
    version = '0.1',
    description = "pythoncore",
    license = 'EPL',
    package_dir = {'': 'lib'},
    py_modules = pyfiles,
    packages = find_packages('lib', exclude=["*tests"]),
    test_suite = 'nose.collector',
    package_data = {'': ['*.xml', '**/*.xml', '*.pl']},
    )
