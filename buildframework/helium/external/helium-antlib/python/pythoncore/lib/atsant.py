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

# pylint: disable-msg=R0912,W0622
#R* remove dring refactoring
#W0622 => Redefining built-in 'filter'

import re
import sysdef.api
import os
import logging

_logger = logging.getLogger('atsant')

def files_to_test(canonicalsysdeffile, excludetestlayers, idobuildfilter, builddrive):
    """list the files to test"""
    sdf = sysdef.api.SystemDefinition(canonicalsysdeffile)

    modules = {}
    for layr in sdf.layers:
        if re.match(r".*_test_layer$", layr):
            try:
                if re.search(r"\b%s\b" % layr, excludetestlayers):
                    continue
            except TypeError, exp:
                pass

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
                                    for filter in unit.filters:
                                        if re.search(r"\b%s\b" % filter, idobuildfilter):
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
