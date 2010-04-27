#============================================================================ 
#Name        : test_comments.py 
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

""" Test cases for Comments.py. """
import unittest
import comments
import amara
import os

class CommentParserTest(unittest.TestCase):
    """ Test cases for Comments.py. """
    
    def setUp(self):
        # Initialize the sample files into two Comment Parsers.
        self.parser1 = comments.CommentParser( [os.environ['TEST_DATA'] + '/data/comments_test.txt'], 'branchInfo' )
        self.parser2 = comments.CommentParser( [os.environ['TEST_DATA'] + '/data/comments_test.cpp', os.environ['TEST_DATA'] + '/data/comments_test.bat',
                                                os.environ['TEST_DATA'] + '/data/comments_test.h', os.environ['TEST_DATA'] + '/data/comments_test.hrh',
                                                os.environ['TEST_DATA'] + '/data/comments_test.iby', os.environ['TEST_DATA'] + '/data/comments_test.inf',
                                                os.environ['TEST_DATA'] + '/data/comments_test.mk', os.environ['TEST_DATA'] + '/data/comments_test.mmp',
                                                os.environ['TEST_DATA'] + '/data/comments_test.pl', os.environ['TEST_DATA'] + '/data/comments_test.xml',
                                                os.environ['TEST_DATA'] + '/data/comments_test.py', os.environ['TEST_DATA'] + '/data/comments_test.java',
                                                os.environ['TEST_DATA'] + '/data/comments_test1.cmd', os.environ['TEST_DATA'] + '/data/comments_test2.cmd'], 'branchInfo' )
     #   self.parser3 = comments.CommentParser( [os.environ['TEST_DATA'] + '/data/comments_test2.cmd'], 'branchInfo' )
     
        

    """ Unit test for method scan() in comments.py. It also tested scan_content by using scan()
    """
    def test_scan(self):
        #doc1 for only one txt file. 
        doc1 = amara.parse(self.parser1.scan().xml())
        #doc2 for all other 14 types of files. It also included two types of cmd files.
        doc2 = amara.parse(self.parser2.scan().xml())
        
        # doc1's test verifies all the information the xml comment provides.
        self.assertEquals(doc1.commentLog.branchInfo.originator, "sanummel")
        self.assertEquals(doc1.commentLog.branchInfo.category, "")
        self.assertEquals(doc1.commentLog.branchInfo.since, "07-03-22")
        self.assertEquals(doc1.commentLog.branchInfo.file, os.environ['TEST_DATA'] + '/data/comments_test.txt')
        self.assertEquals(doc1.commentLog.branchInfo.error, "kkk")
        self.assertEquals(str(doc1.commentLog.branchInfo).strip(),"Add rofsfiles for usage in paged images")
        # s = (str(doc1.commentLog.xml()))
        # print s
        # doc2's test only verifies the main comment content.
        self.assertEquals(str(doc2.commentLog.branchInfo[0]).strip(), "We need TwistOpen and TwistClose to cause display to change between\n landscape and portrait, but SysAp is consuming the key events.  Try\n treating them as Flip events are handled already by SysAp.")
        self.assertEquals(str(doc2.commentLog.branchInfo[1]).strip(), "Testing if it's good~~~")
        self.assertEquals(str(doc2.commentLog.branchInfo[2]).strip(), "We need TwistOpen and TwistClose to cause display to change between\n landscape and portrait, but SysAp is consuming the key events.  Try\n treating them as Flip events are handled already by SysAp.")
        self.assertEquals(str(doc2.commentLog.branchInfo[3]).strip(), "puikko ME SCD DeSW: wk21 Flag fix")
        self.assertEquals(str(doc2.commentLog.branchInfo[4]).strip(), "Since Catalogs is not compiling at this point, and we are not building it, don't try to\n pull it into the rom.  Also, tfxserver is crashing, so don't build or pull it in either.")
        self.assertEquals(str(doc2.commentLog.branchInfo[5]).strip(), "Fix target export, which cause issue when cleanexport.")
        self.assertEquals(str(doc2.commentLog.branchInfo[6]).strip(), "Move command to makmake as EBS does not call abld build")
        self.assertEquals(str(doc2.commentLog.branchInfo[7]).strip(), "Activate PCFW for Screensaver")
        self.assertEquals(str(doc2.commentLog.branchInfo[8]).strip(), "Support SPP mechanism for flags support.")
        self.assertEquals(str(doc2.commentLog.branchInfo[9]).strip(), "Enabling all the HWRM light zones target for product")
        self.assertEquals(str(doc2.commentLog.branchInfo[10]).strip(), "Again, it is just a test")
        self.assertEquals(str(doc2.commentLog.branchInfo[11]).strip(), "Test info, so whatever~")
        self.assertEquals(str(doc2.commentLog.branchInfo[12]).strip(), "k")
        self.assertEquals(str(doc2.commentLog.branchInfo[13]).strip(), "")
          
    

