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

package com.nokia.helium.ant.data;

import java.io.IOException;
import java.text.BreakIterator;
import java.util.HashMap;
import java.util.StringTokenizer;

import org.apache.tools.ant.Project;
import org.dom4j.Comment;
import org.dom4j.Node;

/**
 * An XML comment about an Ant object, which could be a property, target,
 * fileset, etc. It should preceed the object.
 */
public class AntComment {
    private String summary = "";
    private String parsedDocText = "";
    private HashMap<String, String> tags;
    private String objectName = "";
    private boolean isMarkedComment;

    public AntComment() throws IOException {
        this(null);
    }

    public AntComment(Comment comment) throws IOException {
        tags = new HashMap<String, String>();
        if (comment != null) {
            
            String text = getCleanedDocNodeText(comment);

            // See if it is a marked comment (a comment that is only
            // intended to be for documentation generation)
            if (text.startsWith("*")) {
                text = text.substring(1).trim();
                isMarkedComment = true;
            }

            // See if it is a comment describing an object not defined in Helium
            // Currently only properties are supported
            if (text.startsWith("@property")) {
                String[] splitStrings = text.split("\\s", 3);
                objectName = splitStrings[1];
                if (objectName == null) {
                    log("Comment block: object name is not defined.", Project.MSG_WARN);
                    objectName = "";
                }
                if (splitStrings.length > 2) {
                    text = splitStrings[2];
                }
                else {
                    text = "";
                }
            }
            parseCommentText(text);
        }
    }

    private void parseCommentText(String text) throws IOException {
        if (text.length() > 0) {
            StringTokenizer tokenizer = new StringTokenizer(text, "@");

            // Parse any free text before the tags
            if (!text.startsWith("@")) {
                String freeText = tokenizer.nextToken();

                BreakIterator iterator = BreakIterator.getSentenceInstance();
                iterator.setText(freeText);
                if (iterator.next() > 0) {
                    this.summary = freeText.substring(0, iterator.current()).trim();
                }

                parsedDocText = freeText;
            }

            // See if there are any tags to parse
            if (tokenizer.countTokens() > 0) {
                while (tokenizer.hasMoreElements()) {
                    String tagText = (String) tokenizer.nextElement();
                    String[] tagParts = tagText.split("\\s", 2);
                    tags.put(tagParts[0], tagParts[1].trim());
                }
            }
        }
    }

    /**
     * The summary text of the comment, which is the first sentence.
     * 
     * @return The first comment sentence.
     */
    public String getSummary() {
        return summary;
    }

    /**
     * The full documentation text of the comment.
     * 
     * @return The doc text.
     */
    public String getDocumentation() {
        return parsedDocText;

    }

    /**
     * The value of a comment tag that is used to describe a specific attribute
     * of the Ant object.
     * 
     * @param tag The tag name.
     * @return The value of the tag.
     */
    public String getTagValue(String tag) {
        return getTagValue(tag, "");
    }

    /**
     * The value of a comment tag that is used to describe a specific attribute
     * of the Ant object.
     * 
     * @param tag The tag name.
     * @return The value of the tag.
     */
    public String getTagValue(String tag, String defaultValue) {
        String value = (String) tags.get(tag);
        if (value == null) {
            value = defaultValue;
        }
        return value;
    }

    /**
     * Returns the name of the object when the object is defined only by a
     * comment.
     * 
     * @return An object name.
     */
    public String getObjectName() {
        return objectName;
    }

    public boolean isMarkedComment() {
        return isMarkedComment;
    }

    private void log(String string, int msgWarn) {
        System.out.println(string);
    }
    
    /**
     * Clean the whitespace of the doc text.
     * Trim the whole string and also remove a consistent indent from the start
     * of each line.
     */
    static String getCleanedDocNodeText(Node docNode) {
        Node preceedingWhitespaceNode = docNode.selectSingleNode("preceding-sibling::text()");
        // System.out.println(whitespace);
        int indent = 0;
        if (preceedingWhitespaceNode != null) {
            String text = preceedingWhitespaceNode.getText();
            String[] lines = text.split("\n");
            indent = lines[lines.length - 1].length();
            // System.out.println("indent: " + lines[lines.length -
            // 1].length());
        }
        
        String text = docNode.getText();
        text = text.trim();
        
        String[] docLines = text.split("\n");
        // Do not remove from the first line, it is already trimmed.
        text = docLines[0];
        for (int i = 1; i < docLines.length; i++) {
            String line = docLines[i].replaceFirst("^[ \t]{" + indent + "}", "");
            text += line + "\n";
        }
        
        return text;
    }
}
