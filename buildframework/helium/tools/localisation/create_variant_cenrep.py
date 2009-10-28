#============================================================================ 
#Name        : create_variant_cenrep.py 
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

""" MC Localisation Framework
    Generate cenrep for all declared variants
"""
import configuration
import bsf
import localisation
import sys
import os
import shutil
import re

def main():
    """ Main function, run customisation tools on all found variants.
    """
    if len(sys.argv)<3:
        print("create_variant_cenrep.py productname configfile.xml type id")
        sys.exit(-1)
    
    product = sys.argv[1]
    configfile = sys.argv[2]
    vtype = sys.argv[3]
    vid = None
    if len(sys.argv)>4:
        vid = sys.argv[4]

    try:
        builder = configuration.NestedConfigurationBuilder(open(configfile, 'r'))
        config_set = builder.getConfiguration()    
    
        bsfs = bsf.read_all()
        if not bsfs.has_key(product):
            raise Exception("Product not defined, could not find %s.bsf" % product)
    
        for variant in config_set.getConfigurations(product):
            if variant.type != vtype:
                continue
            if vid != None and vid != variant["%s.id" % variant.type]:
                continue
            vpath = localisation.find_variant_path(variant, "%s.id" % variant.type)
            if vpath is not None and os.path.exists(os.path.join(vpath, 'data')):
                print "Generating Cenrep for %s variant %s in %s" % (variant.type, variant["%s.id" % variant.type], vpath)
                os.system("perl \\tools\\cenrep_scripts\\CTCenrep.pl -p %s -output %s" % (os.path.basename(vpath), vpath))
                # os.system("set VARIANTFOLDER=%s & \\s60\\tools\\CustomizationTool\\CustomizationTool.exe generate -%s -%s" % (os.path.dirname(vpath), os.path.splitdrive(os.getcwd())[0], os.path.basename(vpath)))
                for filename in os.listdir(os.path.join(vpath, 'data')):
                    result = re.match(r"(.+)_%s.iby" % variant["%s.id" % variant.type], filename)
                    if result != None:                        
                        shutil.copyfile(os.path.join(vpath, 'data', filename), os.path.join(vpath, "%s.iby" % result.groups(1)))
            else:
                print "Could not find %s variant %s variation path" % (variant.type, variant["%s.id" % variant.type])
    except IOError, exc:
        print "ERROR: %s" % exc
        sys.exit(-1)
    sys.exit(0)

if __name__ == "__main__":
    main()
