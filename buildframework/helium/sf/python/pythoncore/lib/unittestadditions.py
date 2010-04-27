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

import logging
logger = logging.getLogger('unittestadditions')

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

    def __call__(self, f):
        """ Returns the function f if  shouldSkip is False. Else a stub function is returned. """
        def __skiptest(*args, **kargs):
            logger.warning("Skipping test %s" % f.__name__)
            return self.returns
        if self.shouldSkip:
            return __skiptest
        return f
