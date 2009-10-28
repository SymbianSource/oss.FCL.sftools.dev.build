#============================================================================ 
#Name        : dataurl.py 
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

""" This module implements method to create dataurl """
import mimetypes
import base64
import urllib

def from_url(url):
    """ This function returns a data url using content pointed by url. """
    (mimetype, encoding) = mimetypes.guess_type(url)
    if mimetype == None:
        return url
    if encoding != None:
        encoding = "charset=%s;" % encoding
    else:
        encoding = ""
    data = urllib.urlopen(url).read()
    return "data:%s;%sbase64,%s" % (mimetype, encoding, base64.encodestring(data).replace("\n",""))
