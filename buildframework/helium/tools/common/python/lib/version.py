#============================================================================ 
#Name        : version.py 
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

""" S60 Version Management module.

::

    config = {'model.name': 'NXX',
              'variant.id': '01',
              'variant.revision' : '0',
              'model.template': '${model.name} (${variant.id}.${variant.revision})'}
    v = Version('model',config)
    print v.version_string()

"""

from datetime import date
import codecs
import os
import re

class Version:
    """ Version template.
    """
    def __init__(self, vtype, config):
        """ Initialise the Version object.
        """
        self.vtype = vtype
        self.config = config
        today = date.today().strftime( "%d-%m-%y" )
        self.config['today'] = today
  
    def version_string( self ):
        """ Returns the formatted version string.
        """
        # Insert the attributes of this object into the format string
        # Make all Ant-like substitution match the Python format for string substitution
        return self.__unescape(self.config["%s.template" % self.vtype])

    def write(self):
        """ Write the version string to the vtype.txt.path file.
        """
        self.__write(self.__unescape(self.config["%s.txt.path" % self.vtype]), self.version_string())

    def __write( self, path, content ):
        print 'Writing version file: ' + path
        #print 'Content: ' + content
        if os.path.exists( path ):
            os.remove( path )
        newfile = open( path, 'w+' )
        newfile.write( codecs.BOM_UTF16_LE )
        newfile.close()
        vout = codecs.open( path, 'a', 'utf-16-le' )
        vout.write( unicode( content ) )
        vout.close()

    
    def __unescape(self, text):
        previous = u''
        while previous != text:
            previous = text
            text = re.sub(r'\${(?P<name>[._a-zA-Z0-9]+)}', r'%(\g<name>)s', text)
            text = text % self.config
        return text
        

    def __str__(self):
        """ The string representation of the version object is the full version string.
        """
        return self.version_string()

