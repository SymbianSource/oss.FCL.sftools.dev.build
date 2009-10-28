#============================================================================ 
#Name        : bsf.py 
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

""" Helper module to read bsf files.
"""
import dircache
import os.path
import re

class BSF(object):
    """ Class that parse and abstract a bsf file.
    """    
    def __init__(self, filename, bsflist):
        self._filename = filename
        self._is_variant = False
        self._is_virtual_variant = False
        self._customize = None
        self._compile_with_parent = False
        self._list = bsflist
        self.parse()
        
    def parse(self):
        """ Parse the bsf file
        """ 
        bsffile = open(self._filename)
        for line in bsffile.readlines():
            # skipping empty lines and comment
            if re.match(r"^(\s*|\s*#.*)$", line) != None:
                continue

            res = re.search(r"^^\s*(?P<key>\w+)\s+(?P<value>\w+)\s*$", line)
            if res != None:
                if res.groupdict()['key'].lower() == "customizes":
                    self._customize = res.groupdict()['value']
            
            if re.match(r"^^\s*VARIANT\s*$", line) != None:
                self._is_variant = True
            if re.match(r"^^\s*VIRTUALVARIANT\s*$", line) != None:
                self._is_virtual_variant = True
            if re.match(r"^^\s*COMPILEWITHPARENT\s*$", line) != None:
                self._compile_with_parent = True
                
         
        bsffile.close()

    def is_variant(self):
        """ I am a variant
        """
        return self._is_variant

    def is_virtual_variant(self):
        """ I am a virtual variant
        """
        return self._is_virtual_variant
    
    def customize(self):
        """ who am I customizing?
        """
        return self._customize.lower()
    
    def compile_with_parent(self):
        """ who am I customizing?
        """
        return self._compile_with_parent

    def get_name(self):
        """ get my name...
        """
        return os.path.splitext((os.path.basename(self._filename)))[0].lower()
    
    def get_path_as_array(self):        
        """ return myself plus my parents
        """
        result = [self.get_name()]      
        parent = self._list[self.customize()]
        while not parent.is_virtual_variant():
            result.append(parent.get_name())
            parent = self._list[parent.customize()]
        result.reverse()
        return result
  
    def get_path(self):        
        """ return the path section
        """
        path = self.get_name()      
        parent = self._list[self.customize()]
        while not parent.is_virtual_variant():
            path = parent.get_name()+'/'+path
            parent = self._list[parent.customize()]
        return path
            

def read_all(path="/epoc32/tools"):   
    """ Read all bsfs from a directory
    """
    result = {}
    for bsf in dircache.listdir(path):
        if os.path.splitext(bsf)[1]==".bsf":
            bsf = BSF(path+"/"+bsf, result)
            result[bsf.get_name()] = bsf
    return result

def get_includes(bsfs, product):
    """ Return an array representing all include path from specific path (product) to generic (platform)
    """
    result = []
    configs = bsfs[product].get_path_as_array()
    configs.reverse()
    for customisation in configs:
        result.append(bsfs[customisation].get_path())
    return result
