#============================================================================ 
#Name        : ecore.py 
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

""" Implements few eclipse ecore XML parser helpers. """
import re

class Reference(object):
    """ Reference to real instance. """
    
    def __init__(self, node, reference):
        """ The constructor. """
        self.reference = reference
        self.node = node
    
    def __getattr__(self, name):
        """ Delegate to the reference object.
            So the reference object can behave the
            same way as the real object.
        """
        return getattr(self.instance(), name)
        
    def instance(self):
        """ Retrieve the real object instance from the object hierarchy. """
        ref = self.reference
        cnode = self.node
        if ref.startswith("//"):
            cnode = self.node.get_root()    
            ref = ref[2:]
        for pel in ref.split("/"):
            res = re.match(r"@([^.]+)(?:\.(\d+))?", pel)
            if res != None:
                name = res.group(1)
                
                if res.group(2) != None:
                    cnode = getattr(cnode, name)[int(res.group(2))]
                else:
                    cnode = getattr(cnode, name)
            else:
                raise Exception("Invalid reference %s" % ref)
        return cnode


class ContainerBase(object):
    """ Container class that implements a parent relationship. """
    def __init__(self, parent=None):
        self.parent = parent
    
    def get_root(self):
        """ Retrieving the root container. """
        if self.parent == None:
            return self
        else:
            return self.parent.get_root()
