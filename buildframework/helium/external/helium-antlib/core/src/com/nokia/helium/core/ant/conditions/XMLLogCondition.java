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

package com.nokia.helium.core.ant.conditions;

import java.io.File;
import org.apache.tools.ant.BuildException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;
import org.xml.sax.*;
import org.xml.sax.helpers.*;
import com.nokia.helium.core.ant.types.ConditionType;

/**
 * This class implements a Ant Condition which report true if it finds any
 * matching severity inside an XML log.
 * 
 * Example:
 * <pre>
 * &lt;target name=&quot;fail-on-build-error&quot;&gt;
 *   &lt;fail message=&quot;The build contains errors&quot;&gt;
 *     &lt;hlm:hasSeverity file=&quot;build_log.log.xml&quot; severity=&quot;error&quot;/&gt;
 *   &lt;/fail&gt;
 * &lt;/target&gt;
 * </pre>
 * 
 * The condition will eval as true if the build_log.log.xml contains any error message in the log.
 * 
 * @ant.type name="hasSeverity" category="Core"
 */
public class XMLLogCondition extends ConditionType {

    // The severity to count
    private String severity;
    private String logRegexp;
    private File fileName;

    /**
     * Sets which severity will be counted.
     * 
     * @param severity
     * @ant.required
     */
    public void setSeverity(String severity) {
        this.severity = severity;
    }

    public void setFile(File file) {
        fileName = file;
    }

    /**
     * Regular expression which used to match a specific log filename.
     * 
     * @param regex
     * @ant.not-required
     */
    public void setLogMatcher(String regex) {
        this.logRegexp = regex;
    }

    /**
     * Get the number of a particular severity.
     * 
     * @return the number of a particular severity.
     */
    public int getSeverity() {
        int messageCount = 0;
        if (fileName == null || !fileName.exists()) {
            //this.log("Error: Log file does not exist " + fileName);
            return -1;
        }
        if (severity == null)
            throw new BuildException("'severity' attribute is not defined");

        //this.log("Looking for severity '" + severity + "' under '" + fileName.getAbsolutePath() + "'");
        SAXParserFactory factory = SAXParserFactory.newInstance();
        try {
            SAXParser saxParser = factory.newSAXParser();
            MessageHandler handler = new MessageHandler();
            saxParser.parse(fileName, handler);
            this.log("Found " + handler.getMessageCount() + " " + severity
                    + "(s).");
            messageCount += handler.getMessageCount();
        } catch (Exception exc) {
            throw new BuildException(exc);
        }
        return messageCount;
    }

    /**
     * This method open the defined file and count the number of message tags
     * with their severity attribute matching the configured one.
     * 
     * @return if true if message with the defined severity have been found.
     */
    public boolean eval() {
        int severity = getSeverity();
        if (severity < 0) {
            return false;
        }
        return severity > 0;
    }

    /**
     * Implements a SAX handler specialized in counting message tag with a
     * specific severity.
     */
    class MessageHandler extends DefaultHandler {

        private int count;

        public MessageHandler() {
        }

        @Override
        public void startElement(String uri, String localName, String name,
                Attributes attributes) throws SAXException {
            super.startElement(uri, localName, name, attributes);
            if (name.equals(severity) && count == 0) {
                count = Integer.valueOf(attributes.getValue("count"));
            }
        }

        public int getMessageCount() {
            return count;
        }
    }
}