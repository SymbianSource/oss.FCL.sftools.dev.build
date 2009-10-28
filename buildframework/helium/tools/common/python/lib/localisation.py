#============================================================================ 
#Name        : localisation.py 
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

""" Localisation related function. 
        * Parsing of languages.xml
"""
import re
import amara
import os
import bsf
import os.path

class Languages:
    """ Languages.xml file parser. """

    def __init__(self, filename):
        self.__filename = filename
        self.__xml = amara.parse(open(filename,"r"))        
    
    def get_language_ids(self):
        """ returns languages id list """
        result = []
        for language in self.__xml.xml_xpath("/languages/language"):
            result.append(language.id.strip())
        return result
            

    def get_name(self, lid):
        """ returns languages id list """
        for language in self.__xml.xml_xpath("/languages/language[@id='%s']" % lid):
            return language.name.strip()

    def get_attribute(self, lid, name, default=None):
        """ returns the value for a specific language attribute name. It returns default if not found. """
        for language in self.__xml.xml_xpath("/languages/language[@id='%s']/%s" % (lid, name)):
            return language.xml_child_text.strip()
        return default
    
    
    def get_fallbacks(self, lid):        
        """ Return the list of available fallbacks
            None if not any.
        """
        string = self.get_attribute(lid, 'fallbacks')
        if (string != None):
            return string.split(',')
        return None
    
    def find_first_fallback(self, lid, exists):
        """ Find recursively the first reasonable alternative
            lid the language id
            exists an existance function that takes a language id
            as parameter and return a boolean
        """
        
        if (exists(lid)):
            return lid
        
        # get fallback list
        fallbacks = self.get_fallbacks(lid)
        if fallbacks == None:
            return None
        
        for fallback in fallbacks:
            if exists(fallback):
                return fallback
        
        for fallback in fallbacks:
            ffallback = self.find_first_fallback(fallback)
            if ffallback != None:
                return ffallback

        return None
        


def get_all_variations(languages_xml):
    """ Returns a list of all regional variations supported by platform. """
    variations = {'western':1}
    xml = Languages(languages_xml)
    for lid in xml.get_language_ids():
        variations[xml.get_attribute(lid, 'core', 'western')] = 1
    return variations.keys()

def get_languages_for_variation(languages_xml, variation='western'):
    """ Returns alist of all supported languages for a specific region. """
    xml = Languages(languages_xml)
    result = []
    for lid in xml.get_language_ids():
        if (xml.get_attribute(lid, 'core', 'western') == variation):
            result.append(lid)
    return result


def _apply_override(overrides, line):
    res = re.match(r'\s*(data|file)=\s*(\S+)\s+(\S+)', line)
    if res != None and overrides.has_key(res.group(3).lower()):
        print "OVERRIDE: %s => %s" % (res.group(2), overrides[res.group(3).lower()])         
        return "%s=%s %s" % (res.group(1), overrides[res.group(3).lower()], res.group(3))
    return line 
        

def create_locales_iby(product, lid, flags=None, prefix='', suffix=''):
    """ Function that generates locales_xx.iby into rom product folder.
    """
    if flags is None:
        flags = []
    bsfs = bsf.read_all()
    if not bsfs.has_key(product):
        raise Exception("Product not defined, could not find %s.bsf" % product)
    
    variantpath = bsfs[product].get_path()
    if lid == "sc":
        return
    outputfile = "/epoc32/rom/%s/locales_%s.iby" % (variantpath, lid)
    
    print ("Generating %s..." % outputfile)

    
    output = open (outputfile, "w+")
    output.write("#ifndef __LOCALES_%s_IBY__\n" % lid)
    output.write("#define __LOCALES_%s_IBY__\n" % lid)
    
    args = ''
    configs = bsfs[product].get_path_as_array()
    configs.reverse()
    for customisation in configs:
        args += "-I \"./%s\" " % bsfs[customisation].get_path()
        args += "-I \"../include/%s\" " % bsfs[customisation].get_path()
    
    args += "-I ..\\include\\oem"
    for flag in flags:
        args = args + " -D%s" % flag
    
    cdir = os.curdir
    os.chdir ("/epoc32/rom")
    cmd = "cpp -nostdinc -u %s %s include\\locales_sc.iby -include .\\include\\header.iby %s" % (prefix, args, suffix)
    print ("Calling %s\n" % cmd)
    stdin, stdout, stderr = os.popen3(cmd)
    stdin.close()
    result = stdout.read()
    errors =  stderr.read()
    stderr.close()
    status = stdout.close() or 0
    
    print errors

    # parsing overrides first    
    overrides = {}
    for line in result.splitlines():
        res = re.match(r'^\s*(?:ROM_IMAGE\[\d+\]\s+)?data-override\s*=\s*(\S+)\s+(\S+)', line)
        if res != None:
            print "Found override directive %s -> %s" % (res.group(2).lower(), res.group(1))
            overrides[res.group(2).lower()] = res.group(1)
        
    for line in result.splitlines():        
        if re.match(r'^\s*(ROM_IMAGE\[\d+\]\s+)?data-override\s*=\s*(\S+)\s+(\S+)', line):            
            pass
        else:
            line = _apply_override(overrides, line)
            if re.match("^\\s*data\\s*=\\s*MULTI_LINGUIFY", line):
                res = re.search(r"MULTI_LINGUIFY\s*\(\s*(\S+)\s+(\S+)\s+(\S+)\s*\)", line)
                if res.group(1).lower() == "rsc":
                    ext = "r%s" % lid
                    output.write("data=%s.%s %s.%s\n" % (res.group(2), res.group(1), res.group(3), ext))
                else:
                    print "WARNING: Cannot extract '%s'" % line
            
            elif re.search(r"\.rsc", line, re.I) != None:
                output.write(re.sub(r"\.[rR][sS][cC]", r".r%s" % lid, line) + "\n")
            elif re.search(r"\.dbz", line, re.I):
                output.write(re.sub(r"\.[dD][bB][zZ]", r".d%s" % lid, line) + "\n")
            elif re.search(r"\.hlp", line, re.I):
                output.write(re.sub(r"\.[hH][lL][pP]", r".h%s" % lid, line) + "\n")
            elif re.search(r"Content\\01", line, re.I):
                #rename Content\01 to Content\xx (where xx is language id). This is for handlng DTD files
                output.write(re.sub(r"Content\\01", r"Content\\%s" % lid, line) + "\n")
            elif re.search(r"\.o0001", line, re.I):
                lang = lid
                while (len(lang)<4):
                    lang = "0%s" % lang
                output.write(re.sub(r"\.[oO]\d+", ".o%s" % lang, line) + "\n")
            elif re.search(r"elocl\.dll", line, re.I):
                output.write(re.sub(r"\.[lL][oO][cC]|\.[dD][lL][lL]", ".%s" % lid, line) + "\n")
            elif re.search(r"^\s*(data|file)=", line, re.I):
                print ("WARNING: This should not be included in resource.iby '%s'\nThis file should be included using an 'applicationnameVariant.iby' file.\n" % line)
    output.write("#endif\n")
    output.close()
    os.chdir(cdir)
    return status    



VARIANT_ID_KEY = 'variant.id'
VARIATION_DIR_KEY = 'variation.dir'

def find_variant_path(config, key=VARIANT_ID_KEY):
    """ This function helps to find the variant directory
        using variant configuration
    """
    if config.has_key(VARIATION_DIR_KEY) and os.path.exists(config[VARIATION_DIR_KEY]):
        for directory in os.listdir(config[VARIATION_DIR_KEY]):
            if (config.has_key(key) and re.match(r".*_%s$" % config[key], directory) != None):
                return os.path.join(config[VARIATION_DIR_KEY], directory)
    return None
