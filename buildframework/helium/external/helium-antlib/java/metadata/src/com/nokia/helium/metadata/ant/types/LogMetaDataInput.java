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

import com.nokia.helium.metadata.MetaDataInput;

import org.apache.tools.ant.BuildException;
import com.nokia.helium.jpa.entity.metadata.Metadata;
import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Vector;
import java.util.Iterator;
import java.util.Map;
import java.util.Hashtable;
import java.util.regex.Pattern;
import org.apache.tools.ant.types.FileSet;
import org.apache.tools.ant.DirectoryScanner;
import org.apache.log4j.Logger;
import org.apache.tools.ant.types.DataType;

/**
 * Abstract base class to provide common functionality for the log parsing.
 */
public abstract class LogMetaDataInput extends DataType implements
    MetaDataInput {

    private static final String DEFAULT_COMPONENT_NAME = "general";

    private static Logger log = Logger.getLogger(LogMetaDataInput.class);
    
    private Vector<FileSet> fileSetList = new Vector<FileSet>();

    private int currentFileIndex;
    
    private boolean entryAddedForLog;

    private List<File> fileList;
    private Vector<MetaDataFilterSet> metadataFilterSets = new Vector<MetaDataFilterSet>();
    private Vector<MetaDataFilter> completeFilterList;

    private Iterator<Metadata.LogEntry> metadataInputIterator = new MetaDataInputIterator();

    private List<Metadata.LogEntry> logEntries = new ArrayList<Metadata.LogEntry>();
    
    
    /**
     * Adds the fileset (list of input log files to be processed).
     *  @param fileSet fileset to be added
     * 
     */
    public void add(FileSet fileSet) {
        fileSetList.add(fileSet);
    }   
    
    /**
     * Adds the fileset (list of input log files to be processed).
     *  @param fileSet fileset to be added
     * 
     */
    public void add(MetaDataFilterSet metadataFilterSet) {
        metadataFilterSets.add(metadataFilterSet);
    } 

    /**
     * Helper function called by ant to create the new filter
     */
    public MetaDataFilterSet createMetaDataFilterSet() {
        MetaDataFilterSet filterSet =  new MetaDataFilterSet();
        add(filterSet);
        return filterSet;
    }

    /**
     * Helper function to return all the filters associated with this metadata input
     * @return all the filters merged based on the order of definition.
     */
    private Vector<MetaDataFilter> getCompleteFilters()throws Exception {
        Vector<MetaDataFilter> allFilter = new Vector<MetaDataFilter>();
        for (MetaDataFilterSet filterSet : metadataFilterSets) {
            allFilter.addAll(filterSet.getAllFilters());
        }
        return allFilter;
    }

    /**
     * Updates the list of filelist from the input fileset.
     *  @param fileSetList input fileset list
     *  @return the matched files including the base dir. 
     */
    private List<File> getFileListFromFileSet() {
        fileList = new ArrayList<File>();
        for (FileSet fs : fileSetList) {
            DirectoryScanner ds = fs.getDirectoryScanner(getProject());
            String[] includedFiles = ds.getIncludedFiles();
            for ( String file : includedFiles ) {
                fileList.add(new File(ds.getBasedir(), file));
                log.debug("includedfiles: " + file);
            }
        }
        log.debug("fileList.size" + fileList.size());
        return fileList;
    }

    /**
     * Internal function to get the entry
     * @return the top most entry in the list.
     */
    private Metadata.LogEntry getEntry()throws Exception {
        if (logEntries != null && logEntries.size() > 0) {
            return logEntries.remove(0);
        } else {
            throw new Exception("No entries found");
        }
    }

    /**
     * Helper function to return the file list of the metadata input
     * @return file list of this metadata input.
     */
    protected List<File> getFileList() {
        return fileList;
    }

    protected File getCurrentFile() {
        List<File> fileList = getFileList();
        return fileList.get(currentFileIndex); 
    }

    /**
     * Function to check from the input stream if is there any entries available. Implemented by the sub classes.
     * @return true if there are any entry available otherwise false.
     */
    
    boolean isEntryAvailable() throws Exception {
        try {
            int fileListSize = getFileList().size();
            while (currentFileIndex < fileListSize) {
                boolean entryCreated = false;
                File currentFile = getCurrentFile();
                entryCreated = isEntryCreated(currentFile);
                if (entryCreated) {
                    if (!entryAddedForLog) {
                        entryAddedForLog = true;
                    }
                    return entryCreated;
                }
                if (!entryAddedForLog) {
                    // If no entry, then logfile is added to the database.
                    addEntry("default", "general",
                            getCurrentFile().toString(), -1, "", -1, null);
                    entryAddedForLog = true;
                    return true;
                }
                if (isAdditionalEntry()) {
                    return true;
                }
                currentFileIndex ++;
            }
        } catch (Exception ex1 ) {
            log.info("Exception processing stream: " + ex1.getMessage());
            log.debug("exception while parsing the stream", ex1);
            throw ex1;
        }
        return false;
    }

    /**
     * Function to check from the input stream if is there any entries available.
     * @param file for which the contents needs to be parsed for errors
     * @return true if there are any entry available otherwise false.
     */
    abstract boolean isEntryCreated(File currentFile) throws Exception;

    /**
     * Function to check if is there any additional entry. This is being used for example during streaming
     * recorded and at the end of streaming use the recorded data to add any additional entry. Used by
     * @return true if there are any additional entries which are to be recorded in the database.
     */
    protected boolean isAdditionalEntry() {
        return false;
    }

    /**
     * Returns the severity matches for the log text
     * @param log text for which the severity needs to be identified.
     * @return the severity of the input text
     */
    protected String getSeverity(String logText) throws Exception {
        try {
            if (completeFilterList == null) {
                completeFilterList = getCompleteFilters();
            }
            for ( MetaDataFilter filter : completeFilterList) {
                Pattern pattern = filter.getPattern();
                if ((pattern.matcher(logText)).matches()) {
                    return filter.getPriority();
                }
            }
        } catch (Exception ex) {
            log.debug("Exception while getting severity", ex);
            throw ex;
        }
        return null;
    }


    /**
     * Helper function to store the entry which will be added to the database
     * @param priority for the entry
     * @param component of the entry
     * @param logpath of the entry
     * @param lineNo of the entry
     * @param log text message of the entry
     */
    protected void addEntry(String priority, String component, String logPath, int lineNo, 
            String logText) throws Exception {
        addEntry(priority, component, logPath, lineNo, logText, -1, null);
    }
    

    /**
     * Helper function to store the entry which will be added to the database
     * @param priority for the entry
     * @param component of the entry
     * @param logpath of the entry
     * @param lineNo of the entry
     * @param log text message of the entry
     * @param elapsedTime of the component
     */
    protected void addEntry(String priority, String component, String logPath, int lineNo, 
            String logText, float elapsedTime, Metadata.WhatEntry whatEntry) throws Exception {
        //log.debug("adding entry to the list");
        File logPathFile = new File(logPath.trim());
        String baseDir = logPathFile.getParent();
        //Note: Always the query should be in "/" format only, compatible for both linux / windows
        String uniqueLogPath = baseDir + "/" +  logPathFile.getName();
        Metadata.LogEntry entry = new Metadata.LogEntry(
                logText, priority, 
                component, uniqueLogPath, lineNo, elapsedTime, whatEntry);
        logEntries.add(entry);
    }
    
    /**
     * Looks for the text which matches the filter regular expression and adds the entries to the database.
     * @param logTextInfo text message to be searched with filter regular expressions
     * @param priority for the entry
     * @param currentComponent of the logtextInfo
     * @param logpath fo;e fpr wjocj tje text info has to be looked for with filter expression
     * @param lineNumber of the text message
     */
    protected boolean findAndAddEntries(String logTextInfo, String currentComponent, 
            String logPath, int lineNumber) throws Exception {
        return findAndAddEntries(logTextInfo, currentComponent, logPath, lineNumber, null);
    }

    /**
     * Looks for the text which matches the filter regular expression and adds the entries to the database.
     * @param logTextInfo text message to be searched with filter regular expressions
     * @param priority for the entry
     * @param currentComponent of the logtextInfo
     * @param logpath fo;e fpr wjocj tje text info has to be looked for with filter expression
     * @param lineNumber of the text message
     * @param stat object to capture statistics about the parsing.
     */
    protected boolean findAndAddEntries(String logTextInfo, String currentComponent, 
            String logPath, int lineNumber, Statistics stat) throws Exception {
        boolean entryAdded = false; 
        String[] logText = logTextInfo.split("\n");
        String severity = null;
        for (int i = 0; i < logText.length; i++) {
            severity = getSeverity(logText[i]);
            if (severity != null) {
                addEntry(severity, currentComponent, logPath, 
                        i + lineNumber, logText[i]);
                if (stat != null) {
                    stat.incrementSeverity(severity);
                }
                entryAdded = true;
            }
        }
        return entryAdded;
    }
    
    /**
     * Log text are processed based on iterator. When ever the entry is found the entry is returned
     * and the function is called again for further entries.
     * @return the iterator object for the metadata input.
     */
    public Iterator<Metadata.LogEntry> iterator() {
        return metadataInputIterator;
    }

    /**
     * Class to process the files as stream and add the entries todb
     */
    public class MetaDataInputIterator implements Iterator<Metadata.LogEntry> {
        public boolean hasNext() {
            if (fileList == null) {
                fileList = getFileListFromFileSet();
                if (fileList.isEmpty()) {
                    throw new BuildException(" No input found.");
                }
            }
            if (logEntries.size() > 0) {
                return true;
            }
            boolean retValue = false;
            try {
                retValue = isEntryAvailable();
            } catch ( Exception ex) {
                throw new BuildException("Exception while analysing errors from the log:", ex);
            }
            return retValue;
        }

        /**
         * Helper function to remove  entries if any
         */
        public void remove() {
        }
        

        /**
         * Gets the next entry, which has been identified
         * @return log entry to be added to the database.
         */
        public Metadata.LogEntry next() {
            Metadata.LogEntry entry = null;
            try {
                entry = getEntry();
            } catch (Exception ex) {
                log.debug("Exception while getting entry: ", ex);
            }
            return entry;
        }
    }
    
    /**
     * This class capture statistics about the number of severity counted when 
     * parsing, the log.
     */
    public class Statistics {
        private Map<String, Integer> statistics = new Hashtable<String, Integer>();
        
        /**
         * Increment the severity counter by 1.
         */
        public void incrementSeverity(String severity) {
            severity = severity.toLowerCase();
            if (statistics.get(severity) == null) {
                statistics.put(severity, new Integer(1));
            } else {
                statistics.put(severity, new Integer(statistics.get(severity).intValue() + 1));
            }
        }
        
        /**
         * Get the severity counter.
         * @return the number of message with the mentioned severity.
         */
        public int getSeveriry(String severity) {
            severity = severity.toLowerCase();
            if (statistics.get(severity) == null) {
                return 0;
            } else {
                return statistics.get(severity).intValue();
            }
        }
    }
}