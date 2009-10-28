#============================================================================ 
#Name        : test_misc.py 
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

""" Miscellaneous tests.

"""


def test_optparse_import():
    """Ensure 'optparse' module is not imported from within docutils.
    
    Docutils, as of docutils-0.5 at least, comes bundled with a version of the
    `optparse` module that is older than what comes with Python 2.4 standard
    library.
    
    This test, although implemented in a slightly unpythonic manner (thinking
    pythonically, we should only care about a module's behaviour, not its
    version), checks that the `optparse` module acquired without any import
    magic is not the old buggy one from within docutils.
    
    """
    import optparse
    assert "docutils" not in optparse.__file__
    
def test_optparse_help():
    """Test for this issue:
    SF #960515: don't crash when generating help for callback
    options that specify 'type', but not 'dest' or 'metavar'.from 
    http://sourceforge.net/project/shownotes.php?release_id=278548&group_id=38019
    """
    
    import optparse
    
    def testCallback(option, opt, value, parser):
        pass
    
    parser = optparse.OptionParser()
    parser.add_option("--x", help="x", callback=testCallback, action="callback", type="string", default=True)
    parser.print_help()
