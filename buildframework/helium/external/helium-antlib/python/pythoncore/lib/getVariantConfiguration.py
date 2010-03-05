#============================================================================ 
#Name        : getVariantConfiguration.py 
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

import configuration
import sys
import os
import relnotes.variants

class VariantInfo(object):
    def __init__(self, variantdir):
        self.__variantdir = variantdir
        self.__cachestr = None
    
    def __str__(self):
        if self.__cachestr:
            return self.__cachestr
        self.__cachestr = ""
        if not os.path.exists(self.__variantdir):
            return self.__cachestr
        for filename in os.listdir(self.__variantdir):
            filename = os.path.join(self.__variantdir, filename)
            if filename.endswith("_info.txt"):
                print "Reading info from %s" % filename
                data = relnotes.variants.parseInfo(filename)
                if len(data) == 4:
                    output = "%s" % (data['name']) + ","
                    output += "%s" % (data['default']) + ","
                    output += "\"%s (%s)\"" % (",".join(data['languages']), ",".join(data['language.ids']))
                    self.__cachestr = output
                    return output
        return self.__cachestr

def main():
    """ Main function create a csv file that defines the variant configuration.
    """
    product = sys.argv[1]
    configfile = sys.argv[2]
    outputfile = sys.argv[3]
    
    try:
        alreadyDone = {}
        builder = configuration.NestedConfigurationBuilder(open(configfile, 'r'))
        config_set = builder.getConfiguration()
        outfile = open(outputfile, "w+")
        outfile.write("Variant,Default language,Languages\n")
        for variant in config_set.getConfigurations():
            if variant.type and variant.type.startswith("langpack_"):
                if variant['PRODUCT_NAME'] not in alreadyDone:
                    alreadyDone[variant['PRODUCT_NAME']] = {}
                if variant.type not in alreadyDone[variant['PRODUCT_NAME']] and variant['PRODUCT_NAME'] == product:
                    alreadyDone[variant['PRODUCT_NAME']][variant.type] = True
                    v = VariantInfo(variant['ROFS2_DIR'])
                    if len(str(v)) > 0:
                        outfile.write(str(v)+"\n")
        outfile.close()
    except Exception, exc:
        print "ERROR: %s" % exc
        sys.exit(-1)
    
    sys.exit(0)

if __name__ == "__main__":
    main()
