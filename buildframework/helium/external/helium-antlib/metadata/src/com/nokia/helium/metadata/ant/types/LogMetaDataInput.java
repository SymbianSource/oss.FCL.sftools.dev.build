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
import com.nokia.helium.metadata.db.MetaDataDb;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Vector;
import java.util.Iterator;
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
    
    private List<File> fileList;
    private Vector<MetaDataFilterSet> metadataFilterSets = new Vector<MetaDataFilterSet>();
    private Vector<MetaDataFilter> completeFilterList;

    private Iterator<MetaDataDb.LogEntry> metadataInputIterator = new MetaDataInputIterator();

    private List<MetaDataDb.LogEntry> logEntries = new ArrayList<MetaDataDb.LogEntry>();
    
    
    public LogMetaDataInput() {
        //initRecordInfo();
    }

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

    private MetaDataDb.LogEntry getEntry()throws Exception {
        if (logEntries != null && logEntries.size() > 0) {
            return logEntries.remove(0);
        } else {
            throw new Exception("No entries found");
        }
    }

    protected List<File> getFileList() {
        return fileList;
    }

    abstract boolean isEntryAvailable() throws Exception ;
    
    protected String getSeverity(String logText) throws Exception {
        try {
            if (completeFilterList == null) {
                completeFilterList = getCompleteFilters();
            }
            for ( MetaDataFilter filter : completeFilterList) {
                Pattern pattern = filter.getPattern();
                if ((pattern.matcher(logText)).matches()) {
                    //log.debug("pattern matched");
                    return filter.getPriority();
                }
            }
        } catch (Exception ex) {
            log.debug("Exception while getting severity", ex);
            throw ex;
        }
        return null;
    }

    protected void addEntry(String priority, String component, String logPath, int lineNo, 
            String logText) throws Exception {
        //log.debug("adding entry to the list");
        File logPathFile = new File(logPath.trim());
        String baseDir = logPathFile.getParent();
        //Note: Always the query should be in "/" format only, compatible for both linux / windows
        String uniqueLogPath = baseDir + "/" +  logPathFile.getName();
        logEntries.add(new MetaDataDb.LogEntry(
                logText, priority, 
                component, uniqueLogPath, lineNo));
    }

    protected boolean findAndAddEntries(String logTextInfo, String currentComponent, 
            String logPath, int lineNumber)throws Exception {
        boolean entryAdded = false; 
        String[] logText = logTextInfo.split("\n");
        String severity = null;
        for (int i = 0; i < logText.length; i++) {
            severity = getSeverity(logText[i]);
            if ( severity != null) {
                log.debug("found match: ----" + logText[i]);
                addEntry(severity, currentComponent, logPath, 
                        i + lineNumber, logText[i] );
                if (!entryAdded) {
                    entryAdded = true;
                }
            }
        }
        return entryAdded;
    }    
    public Iterator<MetaDataDb.LogEntry> iterator() {
        return metadataInputIterator;
    }

    public class MetaDataInputIterator implements Iterator<MetaDataDb.LogEntry> {
        public boolean hasNext() {
            if (fileList == null) {
                fileList = getFileListFromFileSet();
                if (fileList.isEmpty()) {
                    throw new BuildException(" No input found.");
                }
            }
            if (logEntries.size() > 0) {
                log.debug("returning from existing entries");
                return true;
            }
            boolean retValue = false;
            try {
                retValue = isEntryAvailable();
            } catch ( Exception ex) {
                throw new BuildException("Exception in metadata input.");
            }
            return retValue;
        }

        public void remove() {
        }
        
        public MetaDataDb.LogEntry next() {
            //log.debug("getting next element: " + logEntry);
            MetaDataDb.LogEntry entry = null;
            try {
                entry = getEntry();
            } catch (Exception ex) {
                log.debug("Exception while getting entry: ", ex);
            }
            return entry;
        }
    }
}