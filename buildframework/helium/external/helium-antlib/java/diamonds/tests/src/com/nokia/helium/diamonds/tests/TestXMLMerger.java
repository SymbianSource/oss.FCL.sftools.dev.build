/*
* Copyright (c) 2007-2008 Nokia Corporation and/or its subsidiary(-ies).
* All rights reserved.
* This component and the accompanying materials are made available
* under the terms of the License "Eclipse Public License v1.0"
* which accompanies this distribution, and is available
* at the URL "http://www.eclipse.org/legal/epl-v10.html".
*
* Initial Contributors:
* Nokia Corporation - initial contribution.
*
* Contributors:
*
* Description:  
*
*/

package com.nokia.helium.diamonds.tests;

import java.io.File;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.FileReader;
import java.io.Reader;
import java.io.BufferedReader;
import java.io.IOException;
import com.nokia.helium.diamonds.XMLMerger;
import com.nokia.helium.diamonds.XMLMerger.XMLMergerException;

import org.junit.*;
import static org.junit.Assert.*;
import org.custommonkey.xmlunit.*;

public class TestXMLMerger {
    
    @Before
    public void setUp() {
    }

    @After
    public void tearDown() {
    }

    
    private File createTextFile(String content) throws IOException {
        File temp = File.createTempFile("merge", ".xml");
        temp.deleteOnExit();
        BufferedWriter output = new BufferedWriter(new FileWriter(temp));
        output.write(content);
        output.close();
        return temp;
    }
    
    /**
     * Simple merge with empty source.
     * The result should be the same as the merged content.
     * @throws Exception
     */
    @Test
    public void test_simpleMergeNode() throws Exception {
        File merge = createTextFile("<?xml version=\"1.0\"?>\n<root/>");
        File toBeMerged = createTextFile("<?xml version=\"1.0\"?>\n<root>\n" +                 
                "<section1/>\n" + 
                "<section2/>\n"+ 
                "<section3><subnode>text</subnode></section3>\n"+ 
                "</root>");
        XMLMerger merger = new XMLMerger(merge);
        merger.merge(toBeMerged);
        DifferenceListener differenceListener = new IgnoreTextAndAttributeValuesDifferenceListener();
        Diff diff = new Diff(new ReaderNoSpaces(new FileReader(merge)), new ReaderNoSpaces(new FileReader(toBeMerged)));
        diff.overrideDifferenceListener(differenceListener);
        assertTrue("Test that 2 simple XML merge correctly  " + diff, diff.similar());
    }

    /**
     * Test the merging of twice the same content.
     * Result should be similar to the source.
     * @throws Exception
     */
    @Test
    public void test_mergeSameNode() throws Exception {
        File merge = createTextFile("<?xml version=\"1.0\"?>\n<root>\n" +                 
                "<section>\n" + 
                "<subnode attr=\"1\">1</subnode>\n" + 
                "</section>\n" + 
                "</root>");
        File toBeMerged = createTextFile("<?xml version=\"1.0\"?>\n<root>\n" +                 
                "<section>\n" + 
                "<subnode attr=\"1\">1</subnode>\n" + 
                "</section>\n" + 
                "</root>");
        XMLMerger merger = new XMLMerger(merge);
        merger.merge(toBeMerged);
        DifferenceListener differenceListener = new IgnoreTextAndAttributeValuesDifferenceListener();
        Diff diff = new Diff(new ReaderNoSpaces(new FileReader(merge)), new ReaderNoSpaces(new FileReader(toBeMerged)));
        diff.overrideDifferenceListener(differenceListener);
        assertTrue("Test that identity  " + diff, diff.similar());
    }

    /**
     * Testing the merge of several files.
     * @throws Exception
     */
    @Test
    public void test_mergeWithSubNodeAndAttribute() throws Exception {
        File merge = createTextFile("<?xml version=\"1.0\"?>\n<root/>");
        File toBeMerged1 = createTextFile("<?xml version=\"1.0\"?>\n<root>\n" +                 
                "<section>\n" + 
                "<subnode attr=\"1\">1</subnode>\n" + 
                "</section>\n" + 
                "</root>");
        File toBeMerged2 = createTextFile("<?xml version=\"1.0\"?>\n<root>\n" +                 
                "<section>\n" + 
                "<subnode attr=\"2\">2</subnode>\n" + 
                "</section>\n" + 
                "</root>");
        File toBeMerged3 = createTextFile("<?xml version=\"1.0\"?>\n<root>\n" +                 
                "<section>\n" + 
                "<subnode attr=\"3\">3</subnode>\n" + 
                "</section>\n" + 
                "</root>");
        File toBeMerged4 = createTextFile("<?xml version=\"1.0\"?>\n<root>\n" +                 
                "<section>\n" +                 
                "<subnode attr=\"4\">1</subnode>\n" + 
                "</section>\n" + 
                "</root>");
        File expected = createTextFile("<?xml version=\"1.0\"?>\n<root>\n" +                 
                "<section>\n" + 
                "<subnode attr=\"1\">1</subnode>\n" + 
                "<subnode attr=\"2\">2</subnode>\n" + 
                "<subnode attr=\"3\">3</subnode>\n" + 
                "<subnode attr=\"4\">1</subnode>\n" + 
                "</section>\n" + 
                "</root>");
        XMLMerger merger = new XMLMerger(merge);
        merger.merge(toBeMerged1);
        merger.merge(toBeMerged2);
        merger.merge(toBeMerged3);
        merger.merge(toBeMerged4);
        Diff diff = new Diff(new ReaderNoSpaces(new FileReader(merge)), new ReaderNoSpaces(new FileReader(expected)));
        //System.out.println(readTextFile(merge.getAbsolutePath()));
        assertTrue("test XML matches control skeleton XML " + diff, diff.similar());
    }

    /**
     * Test the XMLMerger with xml file with no Root node.
     */
    @Test(expected=XMLMergerException.class)
    public void test_mergeWithNoRootNode() throws Exception{
		File merge = createTextFile("<?xml version=\"1.0\"?>\n");
		XMLMerger merger = new XMLMerger(merge);
	}
    /**
     * Test the XMLMerger with xml files with different root nodes to merge.
     */
    @Test(expected=XMLMergerException.class)
    public void test_mergeWithDifferentRootNodes() throws Exception{
		File merge = createTextFile("<?xml version=\"1.0\"?>\n<root/>");
		File toBeMerged = createTextFile("<?xml version=\"1.0\"?>\n<root1/>\n");
		XMLMerger merger = new XMLMerger(merge);
		merger.merge(toBeMerged);
	}
    /**
     * Test the XMLMerger with xml files with Wrong xml format
     */
    @Test(expected=XMLMergerException.class)
    public void test_mergeWithWrongXML() throws Exception{
        	File merge = createTextFile("<?xml version=\"1.0\"?>\n<root/>");
        	File toBeMerged = createTextFile("<?xml version=\"1.0\"?>\n<root/><test/>\n");
        	XMLMerger merger = new XMLMerger(merge);
        	merger.merge(toBeMerged);
	}

    /**
     * Load file content into a string. 
     * @param fullPathFilename
     * @return the file content as a string
     * @throws IOException
     */
    public static String readTextFile(String fullPathFilename) throws IOException {
        StringBuffer sb = new StringBuffer(1024);
        BufferedReader reader = new BufferedReader(new FileReader(fullPathFilename));
                
        char[] chars = new char[1024];
        int numRead = 0;
        while ( (numRead = reader.read(chars)) > -1) {
            sb.append(String.valueOf(chars));
        }

        reader.close();

        return sb.toString();
    }    
    
    public class ReaderNoSpaces extends BufferedReader {

        private boolean skip = true; 
        public ReaderNoSpaces(Reader in) throws Exception {
            super(in);
        }
        
        public int read(char[] cbuf, int off, int len) throws IOException {
            int rlen = super.read(cbuf, off, len);
            if (rlen < 0)
                return rlen;
            int w = off;
            for (int i = off ; i < off + rlen ; i++) {
                char c = cbuf[i];
                if (c == '<')
                    skip = false;
                if (c == '>')
                    skip = true;                
                if (!(skip && (c == '\n' || c == '\t'|| c == ' '))) {
                    cbuf[w++] = c;
                }
            }
            return w - off;
        }
        
    }
}
