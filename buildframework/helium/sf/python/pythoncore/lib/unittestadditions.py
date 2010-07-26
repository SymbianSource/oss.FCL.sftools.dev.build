#============================================================================ 
#Name        : unittestadditions.py 
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
""" unit test additions"""


import logging
_logger = logging.getLogger('unittestadditions')

# pylint: disable-msg=C0103

class skip(object):
    """ Skip decorator. The decorated function will only be called
        if the parameter is true.
         
        e.g: 
        @skip(True)
        def test():
           assert True==False
               
    """
    
    def __init__(self, shouldSkip, returns=None):
        self.shouldSkip = shouldSkip
        self.returns = returns

    def __call__(self, f_file):
        """ Returns the function f_file if  shouldSkip is False. Else a stub function is returned. """
        def __skiptest(*args, **kargs):
            """skip test"""
            _logger.warning("Skipping test %s" % f_file.__name__)
            return self.returns
        if self.shouldSkip:
            return __skiptest
        return f_file
# pylint: enable-msg=C0103
