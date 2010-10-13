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
package com.nokia.helium.antlint.ant.types;

/**
 * <code>CheckIndentation</code> is used to check the indentations in the ant
 * files.
 * 
 * <pre>
 * Usage:
 * 
 *  &lt;antlint&gt;
 *       &lt;fileset id=&quot;antlint.files&quot; dir=&quot;${antlint.test.dir}/data&quot;&gt;
 *               &lt;include name=&quot;*.ant.xml&quot;/&gt;
 *               &lt;include name=&quot;*build.xml&quot;/&gt;
 *               &lt;include name=&quot;*.antlib.xml&quot;/&gt;
 *       &lt;/fileset&gt;
 *       &lt;checkIndentation severity=&quot;error&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="checkIndentation" category="AntLint"
 * 
 */
public class CheckIndentation extends AbstractAntFileStyleCheck {
    private static final int INDENT_SPACES = 4;
    private int indentLevel;
    private int totalNoOfSpaces;
    private boolean textElement;
    private int currentLine;

    /**
     * {@inheritDoc}
     */
    public void handleStartDocument() {
        indentLevel -= INDENT_SPACES;
    }

    @Override
    protected void handleEndDocument() {
        indentLevel = 0;
    }

    /**
     * {@inheritDoc}
     */
    public void handleStartElement(String text) {
        countSpaces(text);

        // When an element start tag is encountered,
        // indentLevel is increased 4 spaces.
        indentLevel += INDENT_SPACES;

        checkIndent(text);
        currentLine = getLocator().getLineNumber();
    }

    /**
     * {@inheritDoc}
     */
    public void handleEndElement(String text) {
        countSpaces(text);
        // Ignore end tags in the same line
        if (currentLine != getLocator().getLineNumber()) {
            checkIndent(text);
        }
        // When an element end tag is encountered,
        // indentLevel is decreased 4 spaces.
        indentLevel -= INDENT_SPACES;
        textElement = false;
    }

    /**
     * Check for indentation.
     * 
     */
    private void checkIndent(String text) {
        if ((totalNoOfSpaces != indentLevel) && !textElement) {
            report("Bad indentation : ", getLocator().getLineNumber());
        }
    }

    /**
     * Method counts the number of spaces.
     */
    public void countSpaces(String text) {
        // Counts spaces and tabs in every newline.
        int numSpaces = 0;
        for (int i = 0; i < text.length(); i++) {
            switch (text.charAt(i)) {
                case '\t':
                    numSpaces += 4;
                    break;
                case '\n':
                    numSpaces = 0;
                    break;
                case ' ':
                    numSpaces++;
                    break;
                default:
                    // An alphanumeric character encountered
                    // set the text element flag
                    textElement = true;
                    break;
            }
        }
        totalNoOfSpaces = numSpaces;
        clearBuffer();
    }
}
