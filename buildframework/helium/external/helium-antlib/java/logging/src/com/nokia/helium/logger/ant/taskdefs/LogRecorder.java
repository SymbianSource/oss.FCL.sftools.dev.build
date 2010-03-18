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



package com.nokia.helium.logger.ant.taskdefs;

import java.io.File;
import java.io.IOException;
import java.util.Hashtable;
import java.util.Vector;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.EnumeratedAttribute;
import org.apache.tools.ant.types.LogLevel;

import com.nokia.helium.logger.ant.listener.AntLoggingHandler;
import com.nokia.helium.logger.ant.listener.Handler;
import com.nokia.helium.logger.ant.listener.RecorderEntry;
import com.nokia.helium.logger.ant.listener.StatusAndLogListener;
import com.nokia.helium.logger.ant.types.RecordFilter;
import com.nokia.helium.logger.ant.types.RecordFilterSet;

/**
 * For recording ant logging output.
 *  
 * <pre>
 *      &lt;hlm:record name="${build.log.dir}/${build.id}_test.log" action="start" append="false" backup="true" loglevel="info"&gt;
 *           &lt;hlm:recordfilterset refid="recordfilter.config"/&gt;
 *           &lt;hlm:recordfilter category="info" regexp="^INFO:" /&gt;
 *      &lt;/hlm:record&gt;
 *      
 * </pre>
 * 
 * @ant.task name="Record" category="Logging".
 *
 */

public class LogRecorder extends Task implements Handler {
    
    private static Hashtable<File, RecorderEntry> recorderEntries = new Hashtable<File, RecorderEntry>();
    private File fileName;
    private boolean append ;
    private Boolean start ;
    private boolean backup;
    private String backupProperty;
    private int loglevel = -1;
    private boolean emacsMode ;
    private Vector<RecordFilter> recordFilters = new Vector<RecordFilter>();
    private Vector<RecordFilterSet> recordFilterSet = new Vector<RecordFilterSet>();
    private Vector<String> regExpList = new Vector<String>();
    
    
    /**
     * Run by the task.
     */
    public void execute () {
        if (StatusAndLogListener.getStatusAndLogListener() == null) {
            log("The StatusAndLogListener is not available.", Project.MSG_WARN);
            return;
        }
        AntLoggingHandler antLoggingHandler  = (AntLoggingHandler)StatusAndLogListener.getStatusAndLogListener().getHandler(AntLoggingHandler.class);
        
        /* To validate attributes passed. */
        validateAttributes();
        
        /* to add regular filters */
        addAllRecordFilters();
        
        
        /* Init password/record filter and replace any unset properties */
        initAndReplaceProperties();
        
        //Create the root folder path.
        if (this.start && this.start.booleanValue() && this.backup) {
            if (fileName.exists()) {
                File backupFile;
                try {
                    backupFile = File.createTempFile(fileName.getName(), null, fileName.getParentFile());
                    backupFile.delete();
                    log("Backing up " + fileName + " as " + backupFile);
                    if (!fileName.renameTo(backupFile)) {
                        log("Error renaming the backup file.", Project.MSG_ERR);
                    }
                    if (backupFile.exists() && backupProperty != null) {
                        getProject().setNewProperty(backupProperty, backupFile.getAbsolutePath());
                    }
                } catch (IOException e) {
                    log("Error creating the backup file: " + e, Project.MSG_ERR);
                }
            }    
        }
        if (!fileName.getParentFile().exists()) {
            fileName.getParentFile().mkdirs();
        }

        RecorderEntry recorder = getRecorder(fileName, getProject());
        // set the values on the recorder
        recorder.setMessageOutputLevel(loglevel);
        recorder.setEmacsMode(emacsMode);
        if (start != null) {
            if (start.booleanValue()) {
                if (antLoggingHandler != null) {
                    if (antLoggingHandler.getCurrentStageName() != null) {
                        antLoggingHandler.doLoggingAction(antLoggingHandler.getCurrentStageName(), false, "Stopping", this, getOwningTarget());
                    } else {
                        antLoggingHandler.doLoggingAction("default", false, "Stopping", this, getOwningTarget());
                    }
                }
                recorder.reopenFile();
                recorder.setRecordState(start.booleanValue());
            } else {
                recorder.setRecordState(start.booleanValue());
                recorder.closeFile();
                if (antLoggingHandler != null) {
                    if (antLoggingHandler.getCurrentStageName() != null) {
                        antLoggingHandler.doLoggingAction(antLoggingHandler.getCurrentStageName(), true, "Starting", this, getOwningTarget());
                    } else {
                        antLoggingHandler.doLoggingAction("default", true, "Starting", this, getOwningTarget());
                    }
                }
            }
        }
        
    }
    /**
     * To Validate is the fileName set for recording.
     */
    private void validateAttributes() {
        if (fileName == null) {
            throw new BuildException("filename attribute should be specified for helium recorder task.");
        }
        
    }

    /**
     * Set the file name to record.
     * @param fileName
     * @ant.required
     */
    public void setName(File fileName) {
        this.fileName = fileName;
    }
    
    /**
     * Return the fileName.
     * @return
     */
    public File getName() {
        return this.fileName;
    }
    
    /**
     * Set the append parameter.
     * @param append
     * @ant.not-required Default is false
     */
    public void setAppend(boolean append) {
        this.append = append;
    }
    
    
    
    /**
     * Enable backup of 
     * @param backup 
     * @ant.not-required
     */
    public void setBackup(boolean backup) {
        this.backup = backup;
    }

    /**
     * Name of the property that will contains the backed up log.
     * @param property a property name.
     * @ant.not-required Only works if backup is true.
     */
    public void setBackupProperty(String property) {
        this.backupProperty = property;
    }
    
    /**
     * Set logLevel to log the information.
     * @param level
     * @ant.not-required
     */
    public void setLoglevel(VerbosityLevelChoices level) {
        loglevel = level.getLevel();
    }
    
    /**
     * Set the EmacsMode.
     * @param emacsMode
     * @ant.not-required
     */
    public void setEmacsMode(boolean emacsMode) {
        this.emacsMode = emacsMode;
    }
    
    /**
     * Return the emacsMode.
     * @return
     */
    public boolean getEmacsMode() {
        return this.emacsMode;
    }
    
    /**
     * create the type of recorderfilter.
     * @param logFilter
     */
    public void addRecordFilter(RecordFilter logFilter) {
        if (!recordFilters.contains(logFilter)) {
            recordFilters.add(logFilter);
        }
    }
    
    /**
     * Create the type of recoderfilterset
     * @param logFilterSet
     */
    public void addRecordFilterSet(RecordFilterSet logFilterSet) {
        if (!recordFilterSet.contains(logFilterSet)) {
            recordFilterSet.add(logFilterSet);
        }
    }
    
    /**
     * Set the action of stop/start.
     * @param action
     * @ant.not-required
     */
    public void setAction(ActionChoices action) {
        if (action.getValue().equalsIgnoreCase("start")) {
            start = Boolean.TRUE;
        } else {
            start = Boolean.FALSE;
        }
    }
    
    /**
     * To get the action state of current recorder.
     * @return
     */
    public boolean getAction() {
        return start.booleanValue();
    }
    
    
    /**
     * A list of possible values for the <code>setAction()</code> method.
     * Possible values include: start and stop.
     */
    public static class ActionChoices extends EnumeratedAttribute {
        private static final String[] VALUES = {"start", "stop"};

        /**
         * @see EnumeratedAttribute#getValues()
         */
        /** {@inheritDoc}. */
        public String[] getValues() {
            return VALUES;
        }
    }
    
    /**
     * To set the verbosity levels
     * 
     *
     */
    public static class VerbosityLevelChoices extends LogLevel {
    }
    
    
    /**
     * To register the recorder entry
     */
    protected RecorderEntry getRecorder(File name, Project proj) {
        RecorderEntry entry = recorderEntries.get(name);
        if (entry == null) {
            // create a recorder entry
            entry = new RecorderEntry(name);
            for (String regExp : regExpList) {
                if (!regExp.equals("")) {
                    String pattern = Pattern.quote(regExp);
                    entry.addRegexp(pattern);
                }
            }
            entry.openFile(append);
            recorderEntries.put(fileName, entry);
        }
        return entry;
    }
    
    /**
     * Get all the recorderfilters from recorderfilterset refid.
     */
    public void addAllRecordFilters() {
        for (RecordFilterSet recFilterSet : recordFilterSet ) {
            recordFilters.addAll(recFilterSet.getAllFilters());
        }
    }
    
    public void handleBuildFinished(BuildEvent event) {
        // TODO Auto-generated method stub

    }

    public void handleBuildStarted(BuildEvent event) {
        // TODO Auto-generated method stub

    }

    public void handleTargetFinished(BuildEvent event) {
        // TODO Auto-generated method stub
    }

    public void handleTargetStarted(BuildEvent event) {
        // TODO Auto-generated method stub

    }
    
    /**
     * To init password and record filters. 
     * Replace with values if any property values are unset.
     */
    public void initAndReplaceProperties() {
        
        Pattern pattern = null; 
        Matcher match = null;
        for (RecordFilter recordFilter : recordFilters) { 
            if (recordFilter.getRegExp() == null) {
                throw new BuildException("\"regexp\" attribute should not have null value for recordfilter");
            }
            if (recordFilter.getRegExp() != null) {
                pattern = Pattern.compile("\\$\\{(.*)}");
                match = pattern.matcher(recordFilter.getRegExp());
                if (match.find()) {
                    regExpList.add(getProject().replaceProperties(recordFilter.getRegExp()));
                } else {
                    regExpList.add(recordFilter.getRegExp());
                }
            }
        }
    }
    
    

}
