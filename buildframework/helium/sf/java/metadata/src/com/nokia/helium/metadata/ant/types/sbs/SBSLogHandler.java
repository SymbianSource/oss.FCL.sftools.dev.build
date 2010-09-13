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
package com.nokia.helium.metadata.ant.types.sbs;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.Locator;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.helpers.DefaultHandler;

import com.nokia.helium.metadata.ant.types.SeverityEnum;

/**
 * This class implements the parsing of a SBS log file.
 * Information will be pushed using an SBSLogEvents.
 *
 */
public class SBSLogHandler extends DefaultHandler {
    private static final int UNCATEGORIZED_MAP_LIMIT = 10000;
    private static final String BLDINF_COMPONENT = "/bld.inf";
    private File file;
    private SBSLogEvents eventHandler;
    private boolean record;
    private StringBuffer text = new StringBuffer();
    private Locator locator; 
    private String recipeStatus = "ok";
    private String currentComponent;
    private boolean inWhatLog;
    private long deep;
    private StringBuffer mainSectionText = new StringBuffer();
    private List<SpecialPattern> specialPatterns = new ArrayList<SpecialPattern>();
    private UncategorizedItemMap uncategorizedItemMap = new UncategorizedItemMap();

    
    class SpecialPattern {
        private Pattern regexPattern;
        private int groupPosition;

        public SpecialPattern(String exp, int pos) {
            regexPattern = Pattern.compile(exp);
            groupPosition = pos;
        }
        
        public Pattern getRegexPattern() {
            return regexPattern;
        }
        
        public int getGroupPosition() {
            return groupPosition;
        }
    }
    
    class UncategorizedItemMap extends Hashtable<String, List<UncategorizedItem>> {
        
        private static final long serialVersionUID = 1L;

        public void put(String key, UncategorizedItem item) {
            if (this.containsKey(key)) {
                this.get(key).add(item);
            } else {
                this.put(key, new ArrayList<UncategorizedItem>());
                this.get(key).add(item);                
            }
        }
    }
    
    class UncategorizedItem {
        private SeverityEnum.Severity priotity;
        private String text;
        private int lineNumber;
        
        public UncategorizedItem(String text, int lineNumber, SeverityEnum.Severity priotity) {
            this.text = text;
            this.lineNumber = lineNumber;
            this.priotity = priotity;
        }

        public SeverityEnum.Severity getPriotity() {
            return priotity;
        }

        public String getText() {
            return text;
        }

        public int getLineNumber() {
            return lineNumber;
        }
    }
    
    /**
     * Construct an SBSLogHandler, defining a SBSLogEvents object
     * to receive parsing notifications. The file will be used
     * by the categorization handler.
     * 
     * @param event
     * @param file
     */
    public SBSLogHandler(SBSLogEvents event, File file) {
        this.file = file;
        this.eventHandler = event;
        currentComponent = event.getDefaultComponentName();
        specialPatterns.add(new SpecialPattern("(make.exe|make): \\*\\*\\* No rule to make target.*needed by `(.*)'.*", 2));
        specialPatterns.add(new SpecialPattern("(make.exe|make): \\*\\*\\* \\[(.*)\\].*", 2));
    }

    /**
     * This method will cleanup the path of a bld.inf to extract
     * a component name.
     * e.g: I:/root/layer/package/group/bld.inf
     * will return root/layer/package/group
     * 
     * @param text
     * @return
     */
    protected String removeDriveAndBldInf(String text) {
        // Some light linux support
        if (text.endsWith(BLDINF_COMPONENT)) {
            text = text.substring(0, text.length() - BLDINF_COMPONENT.length());
        }
        if (this.eventHandler.getEpocroot() == null) {
            return text.replaceFirst("^([a-zA-Z]:)?/", "");
        } else {
            text = this.eventHandler.getEpocroot().toURI().relativize((new File(text)).toURI()).getPath();
            if (text.endsWith("/")) {
                text = text.substring(0, text.length() - 1);
            }
            return text;
        }
    }

    /**
     * Get the component based on the Attributes list.
     * If not found it will fallback to the default
     * component name defined by the eventHandler.
     * 
     * @param attributes XML tag SAX attributes list.
     * @return a String representing the component name
     */
    public String getComponent(Attributes attributes) {
        String component = attributes.getValue("", "bldinf");
        if (component == null || component.length() == 0) {
            return eventHandler.getDefaultComponentName();
        }
        return removeDriveAndBldInf(component);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void setDocumentLocator(Locator locator) {
        this.locator = locator;
        super.setDocumentLocator(locator);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void endElement(String uri, String localName, String qName)
        throws SAXException {
        // one level deeper
        deep--;
        if (qName.equals("error") || qName.equals("warning") || qName.equals("info")) {
            record = false;
            String line = text.toString();
            if (!line.trim().equals("")) {
                //log.info(qName + " - " + line);
                eventHandler.add(SeverityEnum.Severity.valueOf(qName.toUpperCase()), text.toString(), locator.getLineNumber());
            }
        } else if (qName.equals("recipe")) {
            record = false;
            int count = 0;
            for (String line : text.toString().split("\n")) {
                if (eventHandler.check(currentComponent, line, locator.getLineNumber()) == SeverityEnum.Severity.ERROR) {
                    count++;
                }
            }
            if (count == 0 && recipeStatus.equalsIgnoreCase("failed")) {
                eventHandler.add(SeverityEnum.Severity.ERROR, currentComponent, "ERROR: recipe exit status is failed.", locator.getLineNumber());
            }
            recipeStatus = "ok";
            text.setLength(0);
        } else if (qName.equalsIgnoreCase("whatlog") ) {
            record = false;
            for (String line : text.toString().split("\n")) {
                line = line.trim().replace("\"", "");
                if (line.length() > 0) {
                    this.eventHandler.addWhatEntry(currentComponent, line, locator.getLineNumber());
                }
            }
            text.setLength(0);
            inWhatLog = false;
        } else if (inWhatLog && qName.equalsIgnoreCase("member")) {
            String line = text.toString().trim().replace("\"", "");
            this.eventHandler.addWhatEntry(currentComponent, line, locator.getLineNumber());
            record = false;
            text.setLength(0);
        } else if (qName.equalsIgnoreCase("clean")) {
            record = false;
            for (String line : text.toString().split("\n")) {
                line = line.trim().replace("\"", "");
                if (line.length() > 0) {
                    if (uncategorizedItemMap.containsKey(line)) {
                        for (UncategorizedItem item : uncategorizedItemMap.get(line)) {
                            this.eventHandler.add(item.getPriotity(), currentComponent, item.getText(), item.getLineNumber());
                        }
                        uncategorizedItemMap.remove(line);
                    }
                }
            }
            text.setLength(0);
        }
        if (deep == 1) {
            mainSectionText.setLength(0);
        }
        super.endElement(uri, localName, qName);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void fatalError(SAXParseException e) throws SAXException {
        // Reporting an XML parsing error.
        eventHandler.add(SeverityEnum.Severity.ERROR, e.getMessage(), e.getLineNumber());
        super.fatalError(e);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void error(SAXParseException e) throws SAXException {
        // Reporting an XML parsing error.
        eventHandler.add(SeverityEnum.Severity.ERROR, e.getMessage(), e.getLineNumber());
        super.error(e);
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void startElement(String uri, String localName, String qName,
            Attributes attributes) throws SAXException {
        // one level deeper
        deep++;
        if (deep == 2) {
            for (String line : mainSectionText.toString().split("\n")) {
                for (SpecialPattern sp : specialPatterns) {
                    Matcher matcher = sp.getRegexPattern().matcher(line);
                    if (matcher.matches()) {
                        uncategorizedItemMap.put(matcher.group(sp.getGroupPosition()), new UncategorizedItem(line, locator.getLineNumber(), SeverityEnum.Severity.ERROR));
                    }
                }
                // record external log messages (such as from emake)
                eventHandler.check(line, locator.getLineNumber());
            }
            if (uncategorizedItemMap.size() > UNCATEGORIZED_MAP_LIMIT) {
                emptyUncategorizedItemMap();
            }
            mainSectionText.setLength(0);
        }
        if (qName.equalsIgnoreCase("buildlog")) {
            mainSectionText.setLength(0);
        } else if (qName.equals("error") || qName.equals("warning") || qName.equals("info")) {
            record = true;
            text.setLength(0);
        } else if (qName.equals("recipe")) {
            record = true;
            text.setLength(0);
            currentComponent = getComponent(attributes);
            this.eventHandler.declareComponent(currentComponent);
        } else if (qName.equalsIgnoreCase("time")) {
            //currentComponent
            String elapsed = attributes.getValue("", "elapsed");
            if (elapsed != null) {
                try {
                    this.eventHandler.addElapsedTime(currentComponent, Double.valueOf(elapsed).doubleValue());
                } catch (NumberFormatException ex) {
                    ex = null; // ignoring the error.
                }
            }
            //elapsedTime = Float.valueOf(getAttribute("elapsed", streamReader)).floatValue();
        } else if (qName.equalsIgnoreCase("status") ) {
            String exit = attributes.getValue("", "exit");
            recipeStatus = (exit != null) ? exit : "ok";
        } else if (qName.equalsIgnoreCase("whatlog") ) {
            record = true;
            inWhatLog = true;
            text.setLength(0);
            currentComponent = getComponent(attributes);
            this.eventHandler.declareComponent(currentComponent);
        } else if (inWhatLog && qName.equalsIgnoreCase("export")) {
            String filename = attributes.getValue("", "destination");
            eventHandler.addWhatEntry(currentComponent, filename, locator.getLineNumber());
        } else if (inWhatLog && qName.equalsIgnoreCase("member")) {
            record = true;
            text.setLength(0);
        } else if (qName.equalsIgnoreCase("clean")) {
            record = true;
            currentComponent = getComponent(attributes);
            this.eventHandler.declareComponent(currentComponent);
            text.setLength(0);
        }
        super.startElement(uri, localName, qName, attributes);
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void characters(char[] ch, int start, int length)
        throws SAXException {
        if (record) {
            text.append(ch, start, length);
        }
        if (deep == 1) {
            mainSectionText.append(ch, start, length);            
        }
        super.characters(ch, start, length);
    }


    private void emptyUncategorizedItemMap() throws SAXException {
        if (uncategorizedItemMap.size() > 0) {
            try {
                SAXParserFactory saxFactory = SAXParserFactory.newInstance();
                SAXParser parser = saxFactory.newSAXParser();
                parser.parse(file, new CategorizationHandler(this));
            } catch (ParserConfigurationException e) {
                throw new SAXException(e.getMessage(), e);
            } catch (IOException e) {
                throw new SAXException(e.getMessage(), e);
            }
        }        
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void endDocument() throws SAXException {
        // Remaining changes
        
        // Let's try categorization handler first
        emptyUncategorizedItemMap();
        
        // Last resorts
        for (String key : uncategorizedItemMap.keySet()) {
            for (UncategorizedItem item : uncategorizedItemMap.get(key)) {
                this.eventHandler.add(item.getPriotity(), this.eventHandler.getDefaultComponentName(), item.getText(), item.getLineNumber());
            }
        }
        super.endDocument();
    }

    /**
     * Get the EventHandler.
     * @return
     */
    public SBSLogEvents getEventHandler() {
        return eventHandler;
    }    

    /**
     * Get the uncategorized items map.
     * @return a map of uncategorized items.
     */
    public UncategorizedItemMap getUncategorizedItemMap() {
        return uncategorizedItemMap;
    }
}
