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

package com.nokia.helium.metadata.ant.types;

import java.io.*;
import java.util.*;
import java.util.regex.Pattern;
import java.util.regex.Matcher;
import org.apache.log4j.Logger;
import javax.xml.stream.XMLStreamReader;
import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.events.XMLEvent;
import com.nokia.helium.jpa.entity.metadata.Metadata;

/**
 * This Type is to specify and use the sbs logparsertype to 
 * parse and store the data based on xmlstreamreader.
 * <pre>
 * &lt;hlm:metadatafilterset id="sbs.metadata.filter"&gt;
 *    &lt;metadatafilterset filterfile="common.csv" /&gt;
 * &lt;/hlm:metadatafilterset&gt;
 * 
 * &lt;hlm:sbsmetadatainput cleanLogFile="cleanlog.file" &gt
 *    &lt;fileset dir="${project.dir}/../data/"&gt;
 *        &lt;include name="*compile.log"/&gt;
 *    &lt;/fileset&gt;
 *    &lt;metadatafilterset refid="sbs.metadata.filter" /&gt;
 * &lt;/hlm:sbsmetadatainput&gt;
 * </pre>
 * @ant.task name="sbsmetadatainput" category="Metadata"
 */
public class SBSLogMetaDataInput extends XMLLogMetaDataInput {


    private static final String DRIVE_LETTER_REGEX = "(([a-z]|[A-Z]):(\\\\|/))(.*)(/bld\\.inf)";
    
    private static final String FAILED_STATUS_MESSAGE = "ERROR: recipe exit status is failed.";

    private Logger log = Logger.getLogger(SBSLogMetaDataInput.class);

    private String currentComponent;
    
    private float currentElapsedTime;
    
    private String logTextInfo = "";
    
    private String recipeStatus = "ok";
    
    private HashMap<String, List <CategoryEntry>> generalTextEntries = new HashMap<String, List <CategoryEntry>>();
    
    private CategorizationHandler categorizationHandler;

    private WhatLogHandler whatLogHandler;

    private List<SpecialRegex> specialRegexPatternList = new ArrayList<SpecialRegex>();

    private int lineNumber;
    
    private boolean inMainDataSection;

    private boolean categorizationCompleted;

    private boolean recordText;
    
    private File cleanLogFile;
    
    private HashMap<String, TimeEntry> componentTimeMap = new HashMap<String, TimeEntry>();

    private File whatLogFile;
    /**
     * Constructor
     */
    public SBSLogMetaDataInput() {
        specialRegexPatternList.add(new SpecialRegex("(make.exe|make): \\*\\*\\* No rule to make target.*needed by `(.*)'.*", 2));
        specialRegexPatternList.add(new SpecialRegex("(make.exe|make): \\*\\*\\* \\[(.*)\\].*", 2));
    }
    
    
    /**
     * Removes the bld inf and the drive letter from the text
     * @param text in which the bld.inf and drive letter to be removed
     * @return updated string.
     */
    static String removeDriveAndBldInf(String text) {
        Matcher matcher = (Pattern.compile(DRIVE_LETTER_REGEX)).matcher(text);
        if (matcher.matches()) {
            return matcher.group(4);
        } else {
            return text;
        }
    }

    /**
     * Removes the bld inf and the drive letter from the text
     * @param text in which the bld.inf and drive letter to be removed
     * @return updated string.
     */
    static String getComponent(XMLStreamReader streamReader) {
        String currentComponent = getAttribute("bldinf", streamReader);
        if ( currentComponent != null && currentComponent.equals("")) {
            return null;
        }
        if (currentComponent != null ) {
            currentComponent = removeDriveAndBldInf(currentComponent);
        }
        return currentComponent;
    }

    /**
     * Generic function to return the attribute value of an attribute from stream
     * @param attribute for which the value from xml stream to be returned.
     * @return the attribute value of an attribute.
     */
    static String getAttribute(String attribute, XMLStreamReader streamReader) {
        int count = streamReader.getAttributeCount() ;
        for (int i = 0 ; i < count ; i++) {
            if ( streamReader.getAttributeLocalName(i).equals(attribute) ) {
                return streamReader.getAttributeValue(i);
            }
        }
        return null;
    }

    /**
     * Helper function to set the clean log file.
     * @param logFile which is the clean log file to process for additional categories
     */
    public void setCleanLogFile(File logFile) {
        cleanLogFile = logFile;
    }

    /**
     * Helper function to set the clean log file.
     * @param logFile which is the what log file to process for missing
     * components
     */
    public void setWhatLogFile(File logFile) {
        whatLogFile = logFile;
    }

    /**
     * Function to process the characters event of xml stream callback.
     * @param streamReader: the input stream reader which contains the xml data to be parsed for recording data.
     * @return true if there are any element to be added to the database.
     */
    public boolean characters (XMLStreamReader streamReader) throws Exception {
        HashMap<String, Integer> toProcess = new HashMap<String, Integer>(); 
        if (recordText) {
            logTextInfo += streamReader.getText();
        } else {
            if (inMainDataSection) {
                String cdataText = streamReader.getText().trim();
                String [] textList = cdataText.split("\n");
                int i = 0;
                for (String text : textList) {
                    boolean added = false;
                    if (text.trim().equals("")) {
                        continue;
                    }
                    for (SpecialRegex specialRegex : specialRegexPatternList) {
                        Matcher matcher = specialRegex.getRegexPattern().matcher(text); 
                        int groupPosition = specialRegex.getGroupPosition();
                        List <CategoryEntry> entryList  = null;
                        if (matcher.matches()) {
                            String componentName = matcher.group(groupPosition).toLowerCase();
                            CategoryEntry newEntry = new CategoryEntry(text, componentName ,
                                    "error", streamReader.getLocation().getLineNumber(), getCurrentFile().toString());
                            entryList = generalTextEntries.get(componentName); 
                            if ( entryList == null) {
                                entryList = new ArrayList<CategoryEntry>();
                                generalTextEntries.put(componentName, entryList);
                            }
                            entryList.add(newEntry);
                            added = true;
                            break;
                        }
                    }
                    if (!added) {
                        toProcess.put(text.trim(), streamReader.getLocation().getLineNumber() + i);
                    }
                    i++;
               }
                boolean entryCreated = false;
                //Check for any general errors.
                for (String textString : toProcess.keySet()) {
                    boolean created = findAndAddEntries(textString, "general",
                        getCurrentFile().toString(), toProcess.get(textString));
                    if (created && !entryCreated ) {
                        entryCreated = true;
                    }
                }
            }
        }
        return false;
    }

    /**
     * Function to process the start event of xml stream callback.
     * @param streamReader: the input stream reader which contains the xml data to be parsed for recording data.
     * @return true if there are any element to be added to the database.
     */
    public boolean startElement (XMLStreamReader streamReader) throws Exception {
        try {
            String tagName = streamReader.getLocalName();
            if (tagName.equalsIgnoreCase("buildlog")) {
                log.debug("starting with buildlog");
                inMainDataSection  = true;
            }
            if (tagName.equalsIgnoreCase("recipe") ) {
                lineNumber = streamReader.getLocation().getLineNumber();
                currentComponent = getComponent(streamReader);
                recordText = true;
                inMainDataSection = false;
                recipeStatus = "ok";
            } if (tagName.equalsIgnoreCase("status") ) {
                String exit = streamReader.getAttributeValue(null, "exit");
                recipeStatus = (exit != null) ? exit : "ok";
            } else if (tagName.equalsIgnoreCase("error")
                    || tagName.equalsIgnoreCase("warning")) {
                lineNumber = streamReader.getLocation().getLineNumber();
                currentComponent = getComponent(streamReader);
                recordText = true;
                inMainDataSection = false;
            } else if (tagName.equalsIgnoreCase("whatlog") ) {
                currentComponent = getComponent(streamReader);
                inMainDataSection = false;
            } else if (tagName.equalsIgnoreCase("time")) {
                inMainDataSection = false;
                currentElapsedTime = Float.valueOf(getAttribute("elapsed", streamReader)).floatValue();
                log.debug("currentElapsedTime:" + currentElapsedTime);
                if (currentComponent != null) {
                    TimeEntry timeObject = componentTimeMap.get(currentComponent);
                    log.debug("currentComponent:" + currentComponent);
                    if (timeObject == null) {
                        timeObject = new TimeEntry(currentElapsedTime, getCurrentFile().toString());
                        componentTimeMap.put(currentComponent, timeObject);
                        log.debug("creating to new time object");
                    } else  {
                        timeObject.addElapsedTime(currentElapsedTime);
                        log.debug("adding it to existing time object");
                    }
                }
            /*} else if (tagName.equalsIgnoreCase("status")) {
                if ( getAttribute("exit", streamReader).equals("failed")) {
                    if (currentComponent == null) {
                        currentComponent = "general";
                    }
                    addEntry("error", currentComponent, getCurrentFile().toString(),
                            streamReader.getLocation().getLineNumber(),
                            FAILED_STATUS_MESSAGE);
                }*/
            } else if (tagName.equalsIgnoreCase("clean")) {
                inMainDataSection = false;
            } else if (tagName.equalsIgnoreCase("info")) {
                inMainDataSection = false;
            }
        } catch (Exception ex) {
            log.debug("exception in startelement", ex);
            throw ex;
        }
        return false;
    }

    /**
     * Checks whether is there any additional entry. During log parsing, all the text which are not part of any tag
     * and are part of CDATA are recorded in a list and checked in this function for any matching errors and processed
     * for their categorization.
     * @return true if there are any element to be added to the database.
     */
    public boolean isAdditionalEntry() {
        try { 
            if (!componentTimeMap.isEmpty()) {
                Set<String> componentSet = componentTimeMap.keySet();
                for (String component : componentSet) {
                    
                    TimeEntry entry = componentTimeMap.get(component);
                    addEntry("default", component, entry.getFilePath(), -1, 
                            null, entry.getElapsedTime(), null);
                    componentTimeMap.remove(component);
                    return true;
                }
            }
            if (!categorizationCompleted) {
                if (cleanLogFile != null) {
                    if (categorizationHandler == null ) {
                        log.info("initializing categorization handler");
                        categorizationHandler = 
                            new CategorizationHandler(cleanLogFile, generalTextEntries);
                    }
                }
                if (categorizationHandler != null && categorizationHandler.hasNext()) {
                    try {
                        CategoryEntry entry = categorizationHandler.getNext();
                        if (entry != null) {
                            addEntry(entry.getSeverity(), entry.getCategory(), entry.getLogFile(), 
                                    entry.getLineNumber(), entry.getText());
                            return true;
                        }
                    } catch (Exception ex) {
                        log.debug("Exception during categorization handler", ex);
                        return false;
                    }
                }
                categorizationCompleted = true;
            }
            if (whatLogFile != null && whatLogHandler == null ) {
                log.info("initializing whatLogHandler");
                whatLogHandler = 
                    new WhatLogHandler(whatLogFile);
            }
            if (whatLogHandler != null ) {
                whatLogHandler.resetMembers();
                if (whatLogHandler.hasNext()) {
                    Metadata.WhatEntry entry = whatLogHandler.getNext();
                    log.debug("Processing for what log handler ");
                    if (entry != null ) {
                        addEntry("default", entry.getComponent(), whatLogHandler.getLogFile(), 
                                whatLogHandler.getLineNumber(), "what log info", -1,  entry);
                        log.debug("adding entry for what log handler");
                        return true;
                    }
                }
            }
        } catch (Exception ex) {
            log.debug("Exception in finding additional entry", ex);
        }
        return false;
    }

    /**
     * Function to process the end event of xml stream callback.
     * @param streamReader: the input stream reader which contains the xml data to be parsed for recording data.
     * @return true if there are any element to be added to the database.
     */
    public boolean endElement(XMLStreamReader streamReader) throws Exception {
        try {
            String tagName = streamReader.getLocalName();
            if (tagName.equalsIgnoreCase("recipe")) {
                inMainDataSection = true;
                recordText = false;
                if (logTextInfo != null) {
                    if (currentComponent == null) {
                        currentComponent = "general";
                    }
                    Statistics stat = new Statistics();
                    boolean entryCreated = findAndAddEntries(logTextInfo, currentComponent,
                            getCurrentFile().toString(), lineNumber, stat);
                    if (stat.getSeveriry("error") == 0 && recipeStatus.equals("failed")) {
                        addEntry("error", currentComponent, getCurrentFile().toString(), 
                                lineNumber, FAILED_STATUS_MESSAGE);
                        entryCreated = true;
                    }
                    logTextInfo = "";
                    recipeStatus = "ok";
                    return entryCreated;
                }
            } else if (tagName.equalsIgnoreCase("error")
                    || tagName.equalsIgnoreCase("warning")) {
                inMainDataSection = true;
                recordText = false;
                if (currentComponent == null) {
                    currentComponent = "general";
                }
                addEntry(tagName, currentComponent, getCurrentFile().toString(), lineNumber, 
                        logTextInfo);
                logTextInfo = "";
                return true;
            } else if (tagName.equalsIgnoreCase("whatlog") ) {
                inMainDataSection = true;
                addEntry("default", currentComponent, getCurrentFile().toString(), -1, 
                        "");
                return true;
            } else if (tagName.equalsIgnoreCase("clean")) {
                inMainDataSection = true;                
            } else if (tagName.equalsIgnoreCase("info")) {
                inMainDataSection = true;
            }
        } catch (Exception ex) {
            log.debug("Exception while processing for sbs metadata input", ex);
            throw ex;
        }
        return false;
    }
}

class SpecialRegex {
    private Pattern regexPattern;
    private int groupPosition;

    public SpecialRegex(String exp, int pos) {
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


/* This class stores the temporary Time entry which is being recorded for each data
 * at the end of the build and during isAdditionalEntry function, the time for the component
 * is updated in the database.
 */
class TimeEntry {
    
    private float elapsedTime;
    private String filePath;
    
    /**
     * Constructor to store the elapsedTime and the path which are to be updated to the database.
     * @param elapsedTime: time duration of the component.
     * @path of the component.
     */
    public TimeEntry(float time, String path) {
        elapsedTime = time;
        filePath = path;
    }
    

    /**
     * Helper function to add time to the previous elapsed time.
     * @param time to be added to the elapsed timet.
     */
    public void addElapsedTime(float time) {
        elapsedTime += time;
    }
    
    /**
     * Helper function to return the elapsed time
     * @return elapsed time of this time entry.
     */
    public float getElapsedTime() {
        return elapsedTime;
    }

    /**
     * Helper function to return the file path of this entry
     * @return path of this time entry.
     */
    public String getFilePath() {
        return filePath;
    }
}
/* This class stores the temporary category entry which is processed during
 * at the end of the build and categorized and written to the database.
 */
class CategoryEntry {

    private String text;
    private int lineNumber;
    private String fileName;
    private String severity;
    private String category;


    /**
     * Constructor of the category entry
     * @param txt - text message of the entry
     * @param ctgry - category of the entry
     * @param svrty - severity of this entry
     * @param lnNo - line number of this entry
     * @param flName - name of the file being processed.
     * @return path of this time entry.
     */
    public CategoryEntry(String txt, String ctgry, 
            String svrty, int lnNo, String flName) {
        text = txt;
        lineNumber = lnNo;
        fileName = flName;
        severity = svrty;
        category = "general";
        if (ctgry != null) {
            category = ctgry;
        }
    }
    
    /**
     * Helper function to set the category
     * @param set the category
     */
    void setCategory(String ctgry) {
        category = ctgry;
    }
    
    /**
     * Helper function to return the category
     * @return the category of this entry.
     */
    String getCategory() {
        return category;
    }

    /**
     * Returns the logfile of this entry
     * @return logfile of this entry
     */
    String getLogFile() {
        return fileName;
    }

    /**
     * Helper function returns the severity of this entry
     * @return severity of this entry
     */
    String getSeverity() {
        return severity;
    }

    /**
     * Helper function returns the line number of this entry
     * @return the line number of this entry.
     */
    
    int getLineNumber() {
        return lineNumber;
    }

    /**
     * Helper function returns the text message of this entry
     * @return text message of this entry
     */
    String getText() {
        return text;
    }

}

/* This class handles the categorization of scanlog errors based on the clean log output
 * from raptor.
 */
 class CategorizationHandler {
       
    private String currentComponent;
    private boolean isInFileTag;
    
    private HashMap<String, List <CategoryEntry>> categoryList;

    private List<CategoryEntry> currentList;

    private XMLInputFactory xmlInputFactory;

    private XMLStreamReader xmlStreamReader;

    private Logger log = Logger.getLogger(CategorizationHandler.class);

    /**
     * Constructor
     * @param clean log file input using which the CDATA text are categorized
     * @param list of entries to be categorized
     */
    public CategorizationHandler(File cleanLogFile, HashMap<String, List <CategoryEntry>> ctgMap) {
        categoryList = ctgMap;
        if (cleanLogFile != null ) {
            try {
                xmlInputFactory = XMLInputFactory.newInstance();
                xmlStreamReader = xmlInputFactory.createXMLStreamReader(cleanLogFile.toString(), 
                    new BufferedInputStream(new FileInputStream(cleanLogFile)));
            } catch ( Exception ex) {
                log.debug("exception while initializing stax processor",ex);
            }
        }
    }

    /**
     * Checks whether is there any entry (by checking for categorization of the recorded CDATA text)
     * @return true if there any entry that are being categorized.
     */
    public boolean hasNext() {
        boolean generalEntriesStatus = categoryList != null && !categoryList.isEmpty();
        boolean currentListStatus = currentList != null && ! currentList.isEmpty();
        return generalEntriesStatus || currentListStatus;
    }

    /**
     * Process the start element event of XML Stream from clean log.
     * @param streamReader clean log xml stream reader to be processed
     * @return true if there are any entry to be added.
     */
    public boolean startElement(XMLStreamReader streamReader) throws Exception {
        String tagName = streamReader.getLocalName();
        if (tagName.equals("clean")) {
            currentComponent = getCategory(streamReader);
            if (currentComponent != null) {
                currentComponent = SBSLogMetaDataInput.removeDriveAndBldInf(currentComponent);
            }
        }
        if (tagName.equals("file")) {
            isInFileTag = true;
        }
        return false;
    }

    /**
     * Process the end element event of XML Stream from clean log.
     * @param streamReader clean log xml stream reader to be processed
     * @return true if there are any entry to be added.
     */
    public boolean endElement (XMLStreamReader streamReader) throws Exception {
        String tagName = streamReader.getLocalName();
        if (tagName.equals("file")) {
            isInFileTag = false;
        }
        return false;
    }

    /**
     * Internal function to find bld inf from the component 
     * @param streamReader clean log xml stream reader to be processed
     * @return the bld.inf attribute.
     */
    private String getCategory(XMLStreamReader streamReader) {
        int count = streamReader.getAttributeCount() ;
        for (int i = 0 ; i < count ; i++) {
            if ( streamReader.getAttributeLocalName(i).equals("bldinf") ) {
                return streamReader.getAttributeValue(i);
            }
        }
        return null;
    }

    /**
     * Internal function to find the CDATA text of the file attribute.
     * @param streamReader clean log xml stream reader to be processed
     * @return the CDATA text of <file> tag.
     */
    private String characters(XMLStreamReader xmlStreamReader) {
        if (isInFileTag) {
            return xmlStreamReader.getText().toLowerCase();
        }
        return null;
    }

    /**
     * Gets the entry which matches the input path. For each line of <file> tag attribute, the entry list
     * is compared with that and if there is any match, then it returns the entry from the list, which
     * is being mtached.
     * @param path for which matching entry is looked for.
     * @return entry which matched the path from the clean log file.
     */
    private List<CategoryEntry> getEntry(String path) {
        Set<String> categorySet = categoryList.keySet();
        for (String key : categorySet) {
        if (path.toLowerCase().equals(key)) {

                List<CategoryEntry> entry = categoryList.get(key);
                categoryList.remove(key);
                return entry;
            }
        }
        return null;
    }

    /**
     * Internal function to update the category entries of the list.
     * @param categoryList for which the category.
     * @param category which is to be updated to the list.
     */
    private void updateCategoryEntries(List<CategoryEntry> categoryList, String category) {
        for (CategoryEntry entry : categoryList) {
            entry.setCategory(category);
        }
    }

    /**
     * Gets the next entry from the stream based on categorization.
     * @return the category entry which is identified as categorized entry.
     */
    public CategoryEntry getNext() throws Exception {
        try {
            if (currentList != null && !currentList.isEmpty()) {
                CategoryEntry entry = currentList.get(0);
                currentList.remove(0);
                return entry;
            }
            if (xmlStreamReader != null ) {
                while (xmlStreamReader.hasNext()) {
                    int eventType = xmlStreamReader.next();
                    switch (eventType) {
                    case XMLEvent.START_ELEMENT:
                        startElement(xmlStreamReader);
                        break;
                    case XMLEvent.END_ELEMENT:
                        endElement(xmlStreamReader);
                        break;
                    case XMLEvent.CHARACTERS:
                        String path = characters(xmlStreamReader);
                        if (path != null ) {
                            currentList = getEntry(path);
                            if (currentList != null && !currentList.isEmpty()) {
                                if (currentComponent != null) {
                                    updateCategoryEntries(currentList, currentComponent);
                                    CategoryEntry entry = (CategoryEntry)currentList.remove(0);
                                    return entry;
                                }
                            }
                        }
                        break;
                    default:
                        break;
                    }
                }
                if (xmlStreamReader != null) {
                    close();
                }
            }
            Set<String> categorySet = categoryList.keySet();
            for (String key : categorySet) {
                currentList = categoryList.remove(key);
                if (currentList != null && !currentList.isEmpty()) {
                    updateCategoryEntries(currentList, "general");
                    CategoryEntry entry = (CategoryEntry)currentList.remove(0);
                    return entry;
                }
            }
        } catch ( Exception ex) {
            log.debug("exception in categorization",ex);
            throw ex;
        }
        return null;
    }
    /**
     * Internal function to close the clean log file stream
     */
    private void close() {
        try {
            if (xmlStreamReader != null) {
                xmlStreamReader.close();
                xmlStreamReader = null;
            }
        } catch (Exception ex) {
            log.debug("exception while closing xml stream",ex);
        }
        
    }
}
 
 /* This class handles the categorization of scanlog errors based on the clean log output
  * from raptor.
  */
  class WhatLogHandler {

     //Todo : handle for linux later
     private static final String MEMBER_REGEX = "^[a-zA-Z]:\\S+$";

     private String currentComponent;
     
     private Metadata.WhatEntry currentEntry;

     private boolean inWhatLog;

     private boolean entryAdded;

     private Pattern memberPattern;

     private List<Metadata.WhatLogMember> members = new ArrayList<Metadata.WhatLogMember>();

     private XMLInputFactory xmlInputFactory;

     private XMLStreamReader xmlStreamReader;
     
     private File whatLogFile;

     private Logger log = Logger.getLogger(WhatLogHandler.class);
     
     /**
      * Constructor
      * @param clean log file input using which the CDATA text are categorized
      * @param list of entries to be categorized
      */
     public WhatLogHandler(File logFile) {
         whatLogFile = logFile;
         log.debug("what log file: " + whatLogFile);
         memberPattern = Pattern.compile(MEMBER_REGEX);
         if (whatLogFile != null ) {
             try {
                 xmlInputFactory = XMLInputFactory.newInstance();
                 xmlStreamReader = xmlInputFactory.createXMLStreamReader(whatLogFile.toString(), 
                     new BufferedInputStream(new FileInputStream(whatLogFile)));
             } catch ( Exception ex) {
                 log.debug("exception while initializing stax processor",ex);
             }
         }
     }

     public String getLogFile() {
         return whatLogFile.toString();
     }
     
     public void resetMembers() {
         members.clear();
     }

     public int getLineNumber() {
         if (xmlStreamReader != null) {
             log.debug("what log file line number: " + xmlStreamReader.getLocation().getLineNumber());
             return xmlStreamReader.getLocation().getLineNumber();
         }
         return -1;
     }

     /**
      * Process the startelement event of XML Stream from clean log.
      * @param streamReader clean log xml stream reader to be processed
      * @return true if there are any entry to be added.
      */
     public boolean startElement(XMLStreamReader streamReader) throws Exception {
         String tagName = streamReader.getLocalName();
         if (tagName.equals("whatlog")) {
             currentComponent = SBSLogMetaDataInput.getComponent(streamReader);
             log.debug("what log file current component: " + currentComponent);
             if (currentComponent != null) {
                 currentComponent = SBSLogMetaDataInput.removeDriveAndBldInf(currentComponent);
             }
             inWhatLog = true;
         } else if (tagName.equals("export")) {
             String text = SBSLogMetaDataInput.getAttribute("destination", streamReader);
             log.debug("what log file in export: text: " + text);
             if (text != null) {
                 String member = SBSLogMetaDataInput.removeDriveAndBldInf(text);
                 boolean exists = (new File(member)).exists();
                 members.add(new Metadata.WhatLogMember(member, exists));
             }
         }
         return false;
     }

     /**
      * Process the endelement event of XML Stream from clean log.
      * @param streamReader clean log xml stream reader to be processed
      * @return true if there are any entry to be added.
      */
     public boolean endElement (XMLStreamReader streamReader) throws Exception {
         String tagName = streamReader.getLocalName();
         if (tagName.equals("whatlog")) {
             log.debug("what log file in entry found returning true:");
             inWhatLog = false;
             if (members != null && !members.isEmpty()) {
                 return true;
             }
         }
         return false;
     }

     /**
      * Internal function to find the CDATA text of the file attribute.
      * @param streamReader clean log xml stream reader to be processed
      * @return the CDATA text of <file> tag.
      */
     private String characters(XMLStreamReader xmlStreamReader) {
         if (inWhatLog) {
             String fullText = xmlStreamReader.getText();
             String[] textList = fullText.split("\n");
             for (String text : textList) {
                 String member = getMember(text);
                 if (member != null) {
                     boolean exists = (new File(member)).exists();
                     String actualText = SBSLogMetaDataInput.removeDriveAndBldInf(member);
                     members.add(new Metadata.WhatLogMember(actualText, exists));
                 }
             }
         }
         return null;
     }
     
     private String getMember(String text) {
         if (memberPattern.matcher(text).matches()) {
             return text;
         } else {
             return null;
         }
     }
     
     public Metadata.WhatEntry getNext() {
         return currentEntry;
     }

     /**
      * Gets the next entry from the stream based on categorization.
      * @return the category entry which is identified as categorized entry.
      */
     public boolean hasNext() throws Exception {
         try {
             boolean entryAvailable = false;
             if (xmlStreamReader != null ) {
                 while (xmlStreamReader.hasNext()) {
                     int eventType = xmlStreamReader.next();
                     switch (eventType) {
                     case XMLEvent.START_ELEMENT:
                         startElement(xmlStreamReader);
                         break;
                     case XMLEvent.END_ELEMENT:
                         entryAvailable = endElement(xmlStreamReader);
                         if (entryAvailable) {
                             if (members != null && ! members.isEmpty()) {
                                 currentEntry = new Metadata.WhatEntry (currentComponent, members);
                                 if (!entryAdded) {
                                     entryAdded = true;
                                 }
                                 return true;
                             }
                         }
                         break;
                     case XMLEvent.CHARACTERS:
                         characters(xmlStreamReader);
                         break;
                     default:
                         break;
                     }
                 }
                 if (!entryAdded) {
                     currentEntry = new Metadata.WhatEntry ("general", null);
                     entryAdded = true;
                     return true;
                 }
                 if (xmlStreamReader != null) {
                     close();
                 }
             }
         } catch ( Exception ex) {
             log.debug("exception in categorization",ex);
             throw ex;
         }
         return false;
     }
     /**
      * Internal function to close the clean log file stream
      */
     private void close() {
         try {
             if (xmlStreamReader != null) {
                 xmlStreamReader.close();
                 xmlStreamReader = null;
             }
         } catch (Exception ex) {
             log.debug("exception while closing xml stream",ex);
         }
     }
}