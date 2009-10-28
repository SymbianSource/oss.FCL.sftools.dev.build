#============================================================================ 
#Name        : test_pathaddition_relative.py 
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

""" path/match.py module tests. """

import pathaddition.relative
import os


def test_commonprefix():
    paths = ['E:/Build_E/ido_wa/ido_lcdo_mcl_product_52_ec/LC_Domain/LC_Domain/localconnectivity',
             'E:/Build_E/ido_wa/ido_lcdo_mcl_product_52_ec/LC_Domain_osext/LC_Domain_osext/localconnectivityextensions',
             'E:/Build_E/ido_wa/ido_lcdo_mcl_product_52_ec/LC_Domain_osext/LC_Domain_osext/localconnectivityextensions/src',
             'E:/Build_E/ido_wa/different_root/LC_Domain_osext/LC_Domain_osext/localconnectivityextensions/src',
             ]

    paths2 = ['Y:/Build_E']
    paths2.extend(paths)

    # basic tests
    # empty list => empty string 
    assert pathaddition.relative.commonprefix([]) == ''
    # one element list => return the element
    assert pathaddition.relative.commonprefix(['foo']) == 'foo'
    
    print pathaddition.relative.commonprefix([paths[0], paths[1]])
    assert os.path.normpath(pathaddition.relative.commonprefix([paths[0], paths[1]])) == os.path.normpath('E:/Build_E/ido_wa/ido_lcdo_mcl_product_52_ec')

    assert os.path.normpath(pathaddition.relative.commonprefix(paths)) == os.path.normpath('E:/Build_E/ido_wa')

    assert pathaddition.relative.commonprefix(paths2) == ''
    