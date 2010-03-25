#============================================================================ 
#Name        : comments.py 
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

""" Helper to parse branch information.
"""
import amara
import logging
import os
import re
import string


COMMENT_SYMBOLS = {
    '.java': ['//'],
    '.hrh': ['//'],
    '.cpp': ['//'],
    '.h': ['//'],
    '.inf': ['//'],
    '.mmp': ['//'],
    '.iby': ['//'],
    '.pl':['#'],
    '.py':['#'],
    '.mk':['#'],
    '.bat':['REM'],
    '.xml':['<!--'],
    '.txt':['//'],
    '.cmd':['#','REM']
    }


# Uncomment this line to enable logging in this module, or configure logging elsewhere   
#logging.basicConfig(level=logging.DEBUG)
_logger = logging.getLogger("comments")


class CommentParser(object):
    """ Parse branch information. """
    def __init__(self, files, element_name):
        self.files = files
        self.element_name = element_name

    def scan(self):
        """ This method goes processes the input files.
        
        It returns an xml document.  """
        doc = amara.create_document(u"commentLog")
        for path in self.files:
            open_file = open(path)
            CommentParser.scan_content(path, open_file.read(), self.element_name, doc)
            open_file.close()

        #print doc.xml()
        return doc
    
    @staticmethod
    def scan_content(filename, content, element_name, doc=None):
        """ This method scan the defined content to find any custom comment tags.
        
        It returns an xml document.
        """
        # Creating a doc if not defined
        if not doc:
            doc = amara.create_document(u"commentLog")
            
        # Search the file for any XML elements matching the given element name
        regex = string.Template(r"<${element_name}.*</${element_name}>").substitute(element_name=element_name)
        comment_elements = re.findall(regex, content, re.DOTALL)
        for comment in comment_elements:
            (_, file_type) = os.path.splitext(filename)
            file_type = file_type.lower()
            if COMMENT_SYMBOLS.has_key(file_type):
                for i in range(len(COMMENT_SYMBOLS[file_type])): 
                    comment = comment.replace(COMMENT_SYMBOLS[file_type][i], "")
            try:
                doc.commentLog.xml_append_fragment(comment)
                # Add a generic file attribute to the comment to label which file it comes from
                doc.commentLog.xml_children[-1].xml_set_attribute(u'file', unicode(filename))
            except Exception:
                _logger.warning("A comment in '%s' is not valid XML." % filename)

        #print doc.xml()
        return doc
    