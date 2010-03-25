#============================================================================ 
#Name        : xmlhelper.py 
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

import re
from xml.dom import Node

def node_scan(node, name):
    """
        Replacement function for node.xml_xpath('./name').
        name is a regular expression.
    """
    results = []
    for subnode in node.childNodes:
        if subnode.nodeType == Node.ELEMENT_NODE and re.match(name, subnode.nodeName) is not None:
            results.append(subnode)
    return results

def recursive_node_scan(node, name):
    """
        Replacement function for node.xml_xpath('.//name').
        name is a regular expression.
    """
    results = node_scan(node, name)
    for subnode in node.childNodes:        
        results.extend(recursive_node_scan(subnode, name))
    return results
