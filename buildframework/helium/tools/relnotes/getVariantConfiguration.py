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

#---------------------------------------------------------------------------------------------------------------------------------------------
# Name: getVariantConfiguration.py
# Synopsis: Extract the product variant configuration
#
# Requirements:
#        -Python 2.4
#
# History:
#     Version: 1.0  23/5/2007
#       First version
#---------------------------------------------------------------------------------------------------------------------------------------------


import localisation
import configuration
import codecs
import sys
import escapeddict

class VariantInfo(object):
    def __init__(self, variant, languagedb):
        self.__variant = variant
        self.__languagedb = languagedb
    
    def __str__(self):
        output = "%s (%s)" % (self.__variant['description'], self.__variant['variant.id']) + ","
        output += "%s (%s)" % (self.__languagedb.get_name(self.__variant['default']), self.__variant['default']) + ","
        output += "\"%s\"" % ",".join(map(lambda x: "%s (%s)" % (self.__languagedb.get_name(x), x), self.__variant['languages']))
        return output

def main():
    """ Main function create a csv file that defines the variant configuration.
    """
    product = sys.argv[1]
    languagefie = sys.argv[2]
    configfile = sys.argv[3]
    outputfile = sys.argv[4]
    
    try:
        languagedb = localisation.Languages(languagefie)
        builder = configuration.NestedConfigurationBuilder(open(configfile, 'r'))
        config_set = builder.getConfiguration()
        outfile = open(outputfile, "w+")
        outfile.write("Variant,Default language,Languages\n")
        for variant in config_set.getConfigurations(product):
            if variant.name == "languagepack":
                v = VariantInfo(variant, languagedb)
                outfile.write(str(v)+"\n")
        outfile.close()
    except Exception, exc:
        print "ERROR: %s" % exc
        sys.exit(-1)
    
    sys.exit(0)

if __name__ == "__main__":
    main()
