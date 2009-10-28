#============================================================================ 
#Name        : get_variant_dirs.py 
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

""" Script that return the  list of variant directory to include. """
import configuration
import bsf
import localisation
import codecs
import sys
import os
import re
import shutil

def get_hierarchy(config):
    """ return the variant hierarchy. """
    result = [config]  
    while (config.parent != None):
        if (config.parent.parent != None):
            result.append(config.parent)
        config = config.parent
    return result

def clean_array(array):
    """ Remove all None element from an array. """
    result = []
    for item in array:
        if item != None:
            result.append(item)
    return result

def main():
    """ Main function. """
    configfile = sys.argv[1]
    product = sys.argv[2]
    vid = sys.argv[3]
    vtype = sys.argv[4]
    vkey = sys.argv[5]
    try:
        builder = configuration.NestedConfigurationBuilder(open(configfile, 'r'))
        config_set = builder.getConfiguration()
    
        bsfs = bsf.read_all()
        if not bsfs.has_key(product):
            raise Exception("Product not defined, could not find %s.bsf" % product)
    
        for variant in config_set.getConfigurations(product):
            if not (variant.type == vtype):
                continue
            if not variant.has_key(vkey):
                continue
            if (vid != variant[vkey]):
                continue
            print " ".join(clean_array(map(lambda x:localisation.find_variant_path(x, "%s.id" % x.type), get_hierarchy(variant))))
            sys.exit(0)
           
    except IOError, exc:
        print "ERROR: %s" % exc
        sys.exit(-1)
    
    sys.exit(0)

if __name__ == "__main__":
    main()
