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
package com.nokia.helium.antlint;

import org.xml.sax.Attributes;
import org.xml.sax.Locator;
import org.xml.sax.helpers.DefaultHandler;

import com.nokia.helium.antlint.checks.Check;

/**
 * <code>AntLintHandler</code> is an SAX2 event handler class used to check for
 * tab characters and indents inside the xml elements.
 * 
 */
public class AntLintHandler extends DefaultHandler {
    private int indentLevel;
    private int indentSpace;
    private Locator locator;
    private boolean textElement;
    private int currentLine;
    private StringBuffer strBuff = new StringBuffer();

    private boolean indentationCheck;
    private boolean tabCharacterCheck;

    private Check check;

    /**
     * Create an instance of {@link AntLintHandler}.
     * 
     * @param check
     *            is the check to be performed.
     */
    public AntLintHandler(Check check) {
        super();
        this.check = check;
    }

    /**
     * {@inheritDoc}
     */
    public void setDocumentLocator(Locator locator) {
        this.locator = locator;
    }

    /**
     * {@inheritDoc}
     */
    public void startDocument() {
        indentLevel -= 4;
    }

    /**
     * {@inheritDoc}
     */
    public void endDocument() {

    }

    /**
     * Set whether the handler should check for indentation or not.
     * 
     * @param indentationCheck
     *            a boolean value to set.
     */
    public void setIndentationCheck(boolean indentationCheck) {
        this.indentationCheck = indentationCheck;
    }

    /**
     * Set whether the handler should check for tab characters or not.
     * 
     * @param tabCharacterCheck
     *            is a boolean value to set.
     */
    public void setTabCharacterCheck(boolean tabCharacterCheck) {
        this.tabCharacterCheck = tabCharacterCheck;
    }

    /**
     * {@inheritDoc}
     */
    public void startElement(String uri, String name, String qName,
            Attributes atts) {
        countSpaces();
        indentLevel += 4; // When an element start tag is encountered,
        // indentLevel is increased 4 spaces.
        checkIndent();
        currentLine = locator.getLineNumber();
    }

    /**
     * {@inheritDoc}
     */
    public void endElement(String uri, String name, String qName) {
        countSpaces();
        // Ignore end tags in the same line
        if (currentLine != locator.getLineNumber()) {
            checkIndent();
        }
        indentLevel -= 4; // When an element end tag is encountered,
        // indentLevel is decreased 4 spaces.
        textElement = false;
    }

    /**
     * Check for indentation.
     * 
     */
    private void checkIndent() {
        if (indentationCheck) {
            if ((indentSpace != indentLevel) && !textElement) {
                check.log(locator.getLineNumber() + ": Bad indentation!");
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    public void characters(char[] ch, int start, int length) {
        for (int i = start; i < start + length; i++) {
            strBuff.append(ch[i]);
        }
    }

    /**
     * Method counts the number of spaces.
     */
    public void countSpaces() {
        // Counts spaces and tabs in every newline.
        int numSpaces = 0;
        for (int i = 0; i < strBuff.length(); i++) {
            switch (strBuff.charAt(i)) {
            case '\t':
                numSpaces += 4;
                if (tabCharacterCheck) {
                    check.log(locator.getLineNumber()
                            + ": Tabs should not be used!");
                }
                break;
            case '\n':
                numSpaces = 0;
                break;
            case '\r':
                break;
            case ' ':
                numSpaces++;
                break;
            default:
                textElement = true;
                break;
            }
        }
        indentSpace = numSpaces;
        strBuff.delete(0, strBuff.length());
    }

}
