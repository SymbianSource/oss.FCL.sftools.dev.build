#============================================================================ 
#Name        : test_path_match.py 
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

""" path/match.py module tests. """

import pathaddition.match


def test_path_match_ant_match():
    # Matching stuff
    assert pathaddition.match.ant_match(r"CVS/Repository", r"**/CVS/*") == True
    assert pathaddition.match.ant_match(r"org/apache/CVS/Entries", r"**/CVS/*") == True
    assert pathaddition.match.ant_match(r"org/apache/jakarta/tools/ant/CVS/Entries", r"**/CVS/*") == True

    assert pathaddition.match.ant_match(r"org/apache/jakarta/tools/ant/docs/index.html", r"org/apache/jakarta/**") == True
    assert pathaddition.match.ant_match(r"org/apache/jakarta/test.xml", r"org/apache/jakarta/**") == True

    assert pathaddition.match.ant_match(r"org/apache/CVS/Entries", r"org/apache/**/CVS/*") == True
    assert pathaddition.match.ant_match(r"org/apache/jakarta/tools/ant/CVS/Entries", r"org/apache/**/CVS/*") == True

    assert pathaddition.match.ant_match(r"/test/foo", r"**/test/**") == True
    assert pathaddition.match.ant_match(r"/test", r"**/test/**") == True
    
    assert pathaddition.match.ant_match(r"C:\development\test\7zip.exe", r"**\*.exe") == True
    assert pathaddition.match.ant_match(r"C:\development\test\7zip.exe", r"**\?zip.exe") == True
    assert pathaddition.match.ant_match(r"C:\development\test\7zip.exe", r"**\?zip.*?") == True
    assert pathaddition.match.ant_match(r"C:\development\test\7zip.exe", r"**/development/*/7zip.exe") == True
    assert pathaddition.match.ant_match(r"C:\development\test\7zip.exe", r"C:\development\**") == True
    assert pathaddition.match.ant_match(r"C:\deve.lopment\te.st\7zip.exe", r"**\*.exe") == True

    # Not matching stuff
    assert pathaddition.match.ant_match(r"org/apache/CVS/foo/bar/Entries", r"**/CVS/*") == False
    assert pathaddition.match.ant_match(r"org/apache/xyz.java", r"org/apache/jakarta/**") == False
    assert pathaddition.match.ant_match(r"org/apache/CVS/foo/bar/Entries", r"org/apache/**/CVS/*") == False

    assert pathaddition.match.ant_match(r"C:\development\test\7zip.exe", r"**/foo/**\?zip.*?") == False
    
    
