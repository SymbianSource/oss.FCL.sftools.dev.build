#============================================================================ 
#Name        : generate_iby_32.py 
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

""" Helper script to generate S60 3.2 help IBY.
"""
import os
import sys
import re
import optparse
import logging
import pathaddition.match

logging.basicConfig()
logger = logging.getLogger('integration.help32')
logger.setLevel(logging.INFO)

# Adding hiddenness testing function.
try:
    import win32api
    import win32con
    USE_WIN32 = 1
except:
    USE_WIN32 = 0

def is_hidden(filename):
    """ Return True if a file is hidden, False otherwise. """
    if USE_WIN32:
        try:            
            if bool(win32api.GetFileAttributes(filename) & win32con.FILE_ATTRIBUTE_HIDDEN):
                return True
        except Exception, e:
            logger.error(e)    
    else:
        if filename[0] == '.':
            return True
    return False

class Basket:
    """
        This class represents a basket which will contains the list of files
        that will be added the the IBY.
    """
    def __init__(self, rootdir, tag='', excludes=None):
        if excludes is None:
            excludes = []
        self.rootdir = rootdir
        self.common = []
        self.language = {}
        self.tag = tag
        self.excludes = excludes
        self.content_scanner(rootdir)

    def add_content(self, filename, language):
        """ Add a file to the basket. """
        if language == None:
            self.common.append(filename)            
        else:
            if not self.language.has_key(language):
                self.language[language] = []
            self.language[language].append(filename)            

    def content_scanner(self, rootdir, path="", language=None):
        """ Parse the help delivery to get content. """
        for name in os.listdir(rootdir):
            abspath = os.path.abspath(os.path.join(rootdir, name))
            # Skipping hidden file and folders.
            if is_hidden(abspath):
                continue
            if name.startswith('.'):
                continue
            if os.path.isdir(abspath):
                logger.debug("Analysing directory: %s" % abspath)
                # only check language if it not yet found, found something that start with numbers
                if  language == None and re.match(r'^\d+', name) != None:
                    result = re.match(r'^(\d+)(?:%s)?$' % self.tag, name, re.I)
                    if result != None:
                        logger.debug("Language directory detected: %s" % name)
                        self.content_scanner(abspath, os.path.join(path, name), result.group(1))                        
                    else:
                        logger.info("Prunning %s directory, because it doesn't match %s tag." % (name, self.tag))
                elif language == None:
                    logger.debug("Directory considered a languageless %s" % name)
                    self.content_scanner(abspath, os.path.join(path, name))
                
                elif language != None:
                    logger.debug("Adding directory %s to %s language" % (name, language))
                    self.content_scanner(abspath, os.path.join(path, name), language)
            else:
                if not self.__is_excluded(os.path.join(path, name)):
                    logger.debug("Adding file %s to %s language" % (name, language))
                    self.add_content(os.path.join(path, name), language)
                else:
                    logger.info("Excluding file %s" % (os.path.join(path, name)))
                    
    
    def __is_excluded(self, filename):
        for exc in self.excludes:
            if pathaddition.match.ant_match(filename, exc, False):
                return True
        return False

    def generate_iby(self, ibyfilename, rootdest=None):
        """ Generates the IBY that should be included by the rom image creation process. """
        if rootdest == None:
            rootdest = self.rootdir
        out = open(ibyfilename, "w")
        out.write("// Generated file please DO NOT MODIFY!\n")
        out.write("#ifndef __PRODUCT_HELPS__\n")
        out.write("#define __PRODUCT_HELPS__\n\n")        
        out.write("\n//Common content.\n")
        for filename in self.common:
            out.write("data=%s RESOURCE_FILES_DIR\\%s\n" % (os.path.join(rootdest, filename), filename))
        out.write("\n//Language specific content.\n")
        for language in self.language.keys():
            # support EE language
            cond = ""
            if language == "01":
                cond = " || defined(__LOCALES_SC_IBY__)"
                            
            out.write("#if defined(__LOCALES_%s_IBY__)%s\n" % (language, cond))
            regex = re.compile(r"^(.*[\\/])?%s%s([\\/])" % (language, self.tag), re.I)
            for filename in self.language[language]:                
                destfilename = regex.sub(r"\g<1>%s\g<2>" % language, filename, 1)                
                out.write("data=%s RESOURCE_FILES_DIR\\%s\n" % (os.path.join(rootdest, filename), destfilename))
            out.write("#endif // defined(__LOCALES_%s_IBY__)%s\n\n" % (language, cond))
        out.write("#endif // __PRODUCT_HELPS__\n")

def main():
    """ Application entry point. """
    parser = optparse.OptionParser()
    parser.add_option("-o", "--output", dest="output",
                      help="Output filename", metavar="OUTPUT")
    parser.add_option("--rootdest", dest="rootdest",
                     help="Root destintation directory", metavar="ROOTDEST")
    parser.add_option("-t", "--tag", dest="tag",                      
                      help="Tag", metavar="TAG")
    parser.add_option("-e", "--exclude", dest="excludes", action="append",                      
                      help="Exclude pattern", metavar="EXCLUDES")

    options = parser.parse_args()[0]
    logger.info("Setting output to '%s'" % options.output)
    ibyfilename = options.output
    
    rootdest = None
    if options.rootdest != None:
        logger.info("Setting rootdest to '%s'" % options.rootdest)
        rootdest = options.rootdest    
    
    tag = ''
    if options.tag != None:
        logger.info("Setting tag to '%s'" % options.tag)
        tag = options.tag

    excludes = []
    if options.excludes != None:
        excludes = options.excludes
    logger.info("Exclude patterns: [%s]" % (", ".join(excludes)))

    datadir = os.path.splitdrive(os.path.abspath("../data"))[1]
    basket = Basket(datadir, tag, excludes=excludes)
    basket.generate_iby(ibyfilename, rootdest)

if __name__ == "__main__":
    main()
