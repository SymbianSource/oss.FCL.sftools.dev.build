#============================================================================ 
#Name        : test_ant.py 
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

""" ant.py module tests. """


import ant


def test_get_property():
    """ Test get_property function. """
    assert ant.get_property('') == ''
    
    # Property was not defined in Ant
    assert ant.get_property('${foo}') == None
    
    # Property was defined, should provide value
    assert ant.get_property('foo') == 'foo'


def test_get_property_macro():
    """ Test the support of get_property inside macro. """
    # Property was not defined in Ant
    assert ant.get_property('@{foo}') == None
    
    # Property was defined, should provide value
    assert ant.get_property('foo') == 'foo'
    
    
def test_get_previous_build_number():
    """ Test get_previous_build_number function. """
    assert ant.get_previous_build_number('01') == ''
    
    assert ant.get_previous_build_number('02') == '01'
    
    assert ant.get_previous_build_number('oci.01') == ''
    
    assert ant.get_previous_build_number('t.02') == 't.01'
    
    assert ant.get_previous_build_number('oci.02') == 'oci.01'
    
    assert ant.get_previous_build_number('oci.002') == 'oci.001'
    
    assert ant.get_previous_build_number('oci.12') == 'oci.11'
    
    assert ant.get_previous_build_number('oci.patch.02') == 'oci.patch.01'
    
    assert ant.get_previous_build_number('oci.patch.10') == 'oci.patch.9'

    assert ant.get_previous_build_number('oci.patch.010') == 'oci.patch.009'
    