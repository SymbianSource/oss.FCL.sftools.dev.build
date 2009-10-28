#============================================================================ 
#Name        : create_language_pack.py 
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
"""
import configuration
import localisation
import bsf
import codecs
import sys
import escapeddict

class VariantIBYBuilder:
    """  Create variant_xx.iby
    """
    
    def __init__(self, name, config):
        self._name = name
        self._config = escapeddict.EscapedDict(config)
    
    def build(self):        
        bsfs = bsf.read_all()
        if not bsfs.has_key(self._name):
            raise Exception("Product not defined, could not find %s.bsf" % self._name)
        filename = "/epoc32/rom/%s/variant_%s.iby" % (bsfs[self._name].get_path(), self._config['languagepack.id'])
        print "Generating %s" % filename
        output = open(filename, "w+")
        output.write("// DO NOT EDIT - FILE AUTOMATICALLY GENERATED\n")
        output.write("// MC variant configuration tool (C) Nokia - 2007\n\n")
        
        output.write("#ifndef VARIANT_%s_IBY\n" % self._config['languagepack.id'])
        output.write("#define VARIANT_%s_IBY\n" % self._config['languagepack.id'])
        
        for lid in str(self._config['languages']).split(' '):
            if lid != '':
                output.write("#include <locales_%s.iby>\n" % lid)
            
        output.write("#endif // VARIANT_%s_IBY\n" % self._config['languagepack.id'])
        output.close()                
        
class LanguageTxtBuilder:
    """  Creates product languages.productname.vid.txt
    """

    def __init__(self, name, config):
        self._name = name
        self._config = escapeddict.EscapedDict(config)
    
    def build(self):
        filename = "/epoc32/data/z/Resource/BootData/languages.%s.%s.txt" % (self._name, self._config['languagepack.id'])
        print "Generating %s" % filename
        output = open( filename, "w+b")        
        output.write(codecs.BOM_UTF16_LE)
        default = self._config['default']
        for lid in str(self._config['languages']).split(' '):
            if lid != '':
                line = "%s\n" % lid
                if lid == default:
                    line = "%s,d\n" % lid
                output.write(line.encode("utf-16-le"))
        output.close()

class LangTxtBuilder:
    """  Creates product lang.productname.vid.txt
    """

    def __init__(self, name, config):
        self._name = name
        self._config = escapeddict.EscapedDict(config)
    
    def build(self):        
        filename = "/epoc32/data/Z/Resource/versions/lang.%s.%s.txt" % (self._name, self._config['languagepack.id'])
        print "Generating %s" % filename
        output = open(filename, "w+b")
        output.write( codecs.BOM_UTF16_LE )
        output.write(self._config['languagepack.id'].encode("utf-16-le"))
        output.close()

def main():
    """ Main function create the whole language pack files.
        variant_xx.iby
        languages.pn.vid.iby
        lang.pn.vid.iby
    """
    product = sys.argv[1]
    configfile = sys.argv[2]
    
    
    try:
        builder = configuration.NestedConfigurationBuilder(open(configfile, 'r'))
        config_set = builder.getConfiguration()
    
        for variant in config_set.getConfigurations(product):
            if variant.type == "languagepack":
                VariantIBYBuilder(product, variant).build()
                LanguageTxtBuilder(product, variant).build()
                LangTxtBuilder(product, variant).build()
    except Exception, exc:
        print "ERROR: %s" % exc
        sys.exit(-1)
    
    sys.exit(0)

if __name__ == "__main__":
    main()
