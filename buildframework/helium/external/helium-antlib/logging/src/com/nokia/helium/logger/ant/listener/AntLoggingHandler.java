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
package com.nokia.helium.logger.ant.listener;

import java.io.File;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.HashMap;
import java.util.Map;
import java.util.Vector;
import java.util.Map.Entry;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.LogLevel;
import org.apache.tools.ant.BuildException;
import org.apache.log4j.Logger;

import com.nokia.helium.logger.ant.types.*;


    /**
     * Ant logging class for each Stage. 
     * 
     *
     */
public class AntLoggingHandler implements Handler {
    
    private static Hashtable recorderEntries = new Hashtable();
    private Boolean append ;
    private int loglevel = -1;
    private VerbosityLevelChoices antLogLevel;
    private Map<String, Stage> stagesMapping;
    private Map<String, StageLogging> stageRecordMap;
    private Map<String, StageLogging> defaultRecordMap;
    private Map<Stage, Target> depStartTargetMap;
    private boolean isStagesIntialized;
    private boolean isRecordingStarted;
    private AntLogRecorderEntry recorderEntry;
    private boolean isRecorderEntryRegistered;
    private boolean isDefaultRecorderEntryRegistered;
    private Logger log = Logger.getLogger(AntLoggingHandler.class);
    private boolean isInitDepStartTarget;
    private String currentStageName; 
    

    public AntLoggingHandler() {
        antLogLevel = new VerbosityLevelChoices();
        stagesMapping = new HashMap<String, Stage>();
        stageRecordMap = new HashMap<String, StageLogging>();
        defaultRecordMap = new HashMap<String, StageLogging>();
        depStartTargetMap = new HashMap<Stage, Target>();
    }

    /**
     * {@inheritDoc}
     */
    public void handleTargetFinished(BuildEvent event) {
        String stageName = getStopStageName (event.getTarget().getName());
        if (stageName != null && getIsRecordingStarted()) {
            stopStageAntLog(stageName);
            startDefaultAntLog();
            
        }
        log.debug("Finishing target [" + event.getTarget().getName() + "]");
    }

    /**
     * {@inheritDoc}
     */
    public void handleTargetStarted(BuildEvent event) {
        
        if (!isDefaultRecorderEntryRegistered ) {
            log.debug("Intializing deafult recorder information and registering the recorder");
            initDefaultAntLogStage(event);
            registerDefaultRecorderEntry();
        }
        
        if (!isStagesIntialized()) {
            log.debug("Intializing stages information");
            getStagesInformation(event);
        }
        
        if (!isInitDepStartTarget() && isStagesIntialized()) {
            log.debug("Intializing dependent targets stage information.");
            initDepStartTarget(event);
        }
        
        if (!isRecorderEntryRegistered && isStagesIntialized()) {
            log.debug("Registering recorder entries.");
            registerRecorderEntry(event);
        }
        
        log.debug("Starting target [" + event.getTarget().getName() + "]");
        String stageName = getStartStageName (event.getTarget().getName());
        if (stageName != null &&  !getIsRecordingStarted()) {
            stopDefaultAntLog(stageName);
            startStageAntLog(stageName);
        }
        
    }
    
    /**
     * {@inheritDoc}
     */
    public void handleBuildStarted(BuildEvent event) {
        
    }
    
    /**
     * {@inheritDoc}
     */
    public void handleBuildFinished(BuildEvent event) {
        String time = getDateTime();
        StageLogging stageLogging = defaultRecordMap.get("default");
        if (stageLogging != null) {
            // this case might happen if the config has not been loaded because
            // of an error happening before the start of the build.
            File logFile = new File(stageLogging.getDefaultOutput());
            if (logFile.exists()) {
                recorderEntry = getRecorder(stageLogging.getDefaultOutput(), StatusAndLogListener.getProject());
                recorderEntry.addLogMessage("Stopping main Ant logging at " + time + " into " + stageLogging.getDefaultOutput());
                recorderEntry.setRecordState(false);
            }
       } else {
           log.debug("Could not find default recorder configuration.");
       }
       this.cleanup();
    }
    
    /**
     * Stage ant logging for respective stage.
     * @param stageName
     */
    public void startStageAntLog(String stageName) {
        String time = getDateTime();
        log.debug("Starting stagerecorder for stage [" + stageName + "]");
        StageLogging startStageLogging = stageRecordMap.get(stageName);
        File logFile = new File(startStageLogging.getOutput());
        if (logFile.exists()) {
            recorderEntry = getRecorder(startStageLogging.getOutput(), StatusAndLogListener.getProject());
            recorderEntry.setRecordState(true);
            recorderEntry.addLogMessage("Starting logging for stage \"" + stageName + "\" into " + startStageLogging.getOutput() + " at " + time );
            this.isRecordingStarted = true;
            this.currentStageName = stageName;
        }
    }
    
    /**
     * Stop ant logging for respective stage.
     * @param stageName
     */

    public void stopStageAntLog( String stageName) {
        String time = getDateTime();
        log.debug("Stopping stagerecorder for stage [" + stageName + "]");
        StageLogging stopStageLogging = stageRecordMap.get(stageName);
        StageLogging defaultStageLogging = defaultRecordMap.get("default");
        recorderEntry.addLogMessage("Stopping logging for stage \"" + stageName + "\" into " + stopStageLogging.getOutput() + " at " + time);
        recorderEntry.addLogMessage("Starting logging into " +  defaultStageLogging.getDefaultOutput());
        recorderEntry = getRecorder(stopStageLogging.getOutput(), StatusAndLogListener.getProject());
        recorderEntry.setRecordState(false);
        this.isRecordingStarted = false;
        this.currentStageName = null;
    }
    
    /**
     * Returns recorder entry for logging current build process.
     * @param stageLogging
     * @param proj
     * @return
     */
    @SuppressWarnings("unchecked")
    protected AntLogRecorderEntry getRecorder(String name, Project proj) {
        
        Object o = recorderEntries.get(name);
        AntLogRecorderEntry entry;
        if (o == null) {
            // create a recorder entry
            entry = new AntLogRecorderEntry(name);
            if (append == null) {
                entry.openFile(false);
            } else {
                entry.openFile(append.booleanValue());
            }
            entry.setProject(proj);
            recorderEntries.put(name, entry);
        } else {
            entry = (AntLogRecorderEntry) o;
        }
        return entry;
    }
    
    /**
     * Whether or not the logger should append to a previous file.
     * @param append if true, append to a previous file.
     */
    public void setAppend(boolean append) {
        this.append = append ;
    }
    
    
    /**
     * Sets the level to which this recorder entry should log to.
     * @param level the level to set.
     * @see VerbosityLevelChoices
     */
    public void setLoglevel(VerbosityLevelChoices level) {
        loglevel = level.getLevel();
    }
    
    /**
     * A list of possible values for the <code>setLoglevel()</code> method.
     * Possible values include: error, warn, info, verbose, debug.
     */
    public static class VerbosityLevelChoices extends LogLevel {
    }
    
    /**
     * To get the stage information.
     * @param event
     */
    @SuppressWarnings("unchecked")
    private void getStagesInformation(BuildEvent event) {
        this.isStagesIntialized = true;
        Hashtable<String, Object> references = event.getProject().getReferences(); 
        Enumeration<String> keyEnum = references.keys();
        while (keyEnum.hasMoreElements()) {
            String key = keyEnum.nextElement();
            if (references.get(key) instanceof Stage) {
                Stage tempStage = (Stage)references.get(key);
                log.debug("Found  stage [" + key + "] for recording");
                if (validateStageTargets(event, tempStage.getStartTarget(), tempStage.getEndTarget() )) {
                    log.debug("Start and end targets are valid for stage [" + key + "]");
                    stagesMapping.put(key, (Stage)references.get(key));
                    getStageRecordInformation(event, key, tempStage.getStartTarget(), tempStage.getEndTarget());
                }
            }
        }
    }
    
    /**
     * Checks, is stages are initialized.
     * @return
     */
    private boolean isStagesIntialized() {
        return this.isStagesIntialized;
    }
    
    /**
     * To initialize stage record mapping.
     * @param event
     */
    @SuppressWarnings("unchecked")
    private void getStageRecordInformation(BuildEvent event, String stageKey, String startTarget, String endTarget) {
        Hashtable<String, Object> references = event.getProject().getReferences(); 
        Enumeration<String> keyEnum = references.keys();
        while (keyEnum.hasMoreElements()) {
            String key = keyEnum.nextElement();
            if (references.get(key) instanceof StageLogging) {
                StageLogging tempStageLogging = (StageLogging)references.get(key);
                
                if (tempStageLogging.getStageRefID() == null && tempStageLogging.getDefaultOutput() == null ) {
                    throw new BuildException("stagefefid attribute should be specified for stagerecord [" + key + "]");
                }
                if (tempStageLogging.getStageRefID() != null ) {
                    if (tempStageLogging.getStageRefID().equalsIgnoreCase(stageKey) && tempStageLogging.getDefaultOutput() == null) {
                        log.debug("stagerecord reference for stage [" + stageKey + "] is [" +  tempStageLogging.getStageRefID() + "]");
                        if (tempStageLogging.getOutput() == null) {
                            throw new BuildException("output attribute should be specified for stagerecord [" + key + "]");
                        }
                        stageRecordMap.put(stageKey, tempStageLogging);
                    }
                }
            }
        }
    }
    
    /**
     * First Validate is the default output has been set. 
     * @param event
     */
    @SuppressWarnings("unchecked")
    private void initDefaultAntLogStage(BuildEvent event) {
        Hashtable<String, Object> references = event.getProject().getReferences(); 
        Enumeration<String> keyEnum = references.keys();
        while (keyEnum.hasMoreElements()) {
            String key = keyEnum.nextElement();
            if (references.get(key) instanceof StageLogging) {
                StageLogging tempStageLogging = (StageLogging)references.get(key);
                
                if (tempStageLogging.getStageRefID() == null && tempStageLogging.getDefaultOutput() != null ) {
                    defaultRecordMap.put("default", tempStageLogging);
                }
            }
        }
    }
    
    /**
     * To check is the stage start and end targets present in the sequence. 
     * @param event
     * @param startTarget
     * @param endTarget
     * @return
     */
    @SuppressWarnings("unchecked")
    private boolean validateStageTargets(BuildEvent event, String startTarget, String endTarget) {
        
        Hashtable<String, String> antTargets = event.getProject().getTargets();
        return antTargets.containsKey(startTarget) && antTargets.containsKey(endTarget);
    }
    
    /**
     * Return mapped stage name to start record.
     * @param targetName
     * @return
     */
    
    private String getStartStageName(String targetName) {
        
        for (Map.Entry<String, Stage> entry : stagesMapping.entrySet() ) {
            Stage stage = entry.getValue();
            if ( stage.getStartTarget().equalsIgnoreCase(targetName)) {
                log.debug("stageName name for target [" + targetName + "] is [" +  entry.getKey() + "]");
                return entry.getKey();
            }
            for (Map.Entry<Stage, Target> depEntry : depStartTargetMap.entrySet() ) {
                Stage depStage = depEntry.getKey();
                if ((depStage.getStartTarget().equalsIgnoreCase(stage.getStartTarget())) && (depEntry.getValue().getName().equalsIgnoreCase(targetName))) {
                    log.debug("stageName name for depending target [" + depStage.getStartTarget() + "] is [" +  entry.getKey() + "]");
                    return entry.getKey();
                }
            }
        }
        return null;
    }
    
    /**
     * Return mapped stage name to stop record.
     * @param targetName
     * @return
     */
    private String getStopStageName(String targetName) {
        
        for (Map.Entry<String, Stage> entry : stagesMapping.entrySet() ) {
            Stage stage = entry.getValue();
            if ( stage.getEndTarget().equalsIgnoreCase(targetName)) {
                log.debug("stageName name for end target [" + targetName + "] is [" +  entry.getKey() + "]");
                return entry.getKey();
            }
        }
        return null;
    }
    
    /**
     * To check is recording started.
     * @return
     */
    private boolean getIsRecordingStarted() {
        return this.isRecordingStarted;
    }
    
    /**
     * To register recorder entries.
     * @param event
     */
    @SuppressWarnings("unchecked")
    private void registerRecorderEntry(BuildEvent event) {
        /* Later register stages recorder entries */
        for (Map.Entry<String, StageLogging> entry : stageRecordMap.entrySet()) {
            StageLogging stageLogging  = entry.getValue();  
            File logFile = new File(stageLogging.getOutput());
            if (!logFile.getParentFile().exists()) {
                logFile.getParentFile().mkdirs();
            }
            if (logFile.getParentFile().exists()) {
                log.debug("Registering recorderentry for log file [" + stageLogging.getOutput() + "]");
                this.setAppend(stageLogging.getAppend().booleanValue());
                recorderEntry = getRecorder(stageLogging.getOutput(), StatusAndLogListener.getProject());
                antLogLevel.setValue(stageLogging.getLogLevel());
                this.setLoglevel(antLogLevel);
                recorderEntry.setMessageOutputLevel(loglevel);
                recorderEntry.setEmacsMode(false);
                recorderEntry.setRecordState(false);
                isRecorderEntryRegistered = true;
            }
        }
    }
    
    /**
     * To register default recorder entry.
     */
    @SuppressWarnings("unchecked")
    private void registerDefaultRecorderEntry() {
        
        /* First register default recorder */
        if (defaultRecordMap.size() == 0) {
            throw new BuildException("There is no stagerecord type with defaultoutput attribute set. please set...");
        }
        StageLogging stageLogging = defaultRecordMap.get("default");
        File logFile = new File(stageLogging.getDefaultOutput());
        if (!logFile.getParentFile().exists()) {
            logFile.getParentFile().mkdirs();
        }
        if (logFile.getParentFile().exists()) {
            log.debug("Registering recorderentry for log file [" + stageLogging.getDefaultOutput() + "]");
            this.setAppend(stageLogging.getAppend().booleanValue());
            recorderEntry = getRecorder(stageLogging.getDefaultOutput(), StatusAndLogListener.getProject());
            antLogLevel.setValue(stageLogging.getLogLevel());
            this.setLoglevel(antLogLevel);
            recorderEntry.setMessageOutputLevel(loglevel);
            recorderEntry.setEmacsMode(false);
            recorderEntry.setRecordState(true);
            String time = getDateTime();
            recorderEntry.addLogMessage("Starting main Ant logging at " + time + " into " + stageLogging.getDefaultOutput());
            isDefaultRecorderEntryRegistered = true;
        }
        
    }
    
    
    
    /**
     * To clean recorder entries.
     */
    private void cleanup() {
        log.debug("Cleaning up recorder entries of stagerecord");
        StatusAndLogListener.getProject().removeBuildListener(recorderEntry);
        recorderEntries.clear();
        
    }
    
    /**
     * To check is the dependent start target map is initialized.
     * @return
     */
    private boolean isInitDepStartTarget() {
        return isInitDepStartTarget;
    }
    
    /**
     * Initialize the dependent start targets mapping.
     * @param event
     */
    @SuppressWarnings("unchecked")
    private void initDepStartTarget(BuildEvent event) {
        Vector<Target> arrayList = null;
        isInitDepStartTarget = true;
        for (Map.Entry<String, Stage> entry : stagesMapping.entrySet() ) {
            Stage stage = entry.getValue();
            arrayList = event.getProject().topoSort(stage.getStartTarget(), event.getProject().getTargets(), false);
            if (arrayList != null && arrayList.size() > 1) {
                depStartTargetMap.put(stage, arrayList.firstElement());
            }
        }
    }
    
    /**
     * To get current date and time.
     * @return
     */
    private String getDateTime() {
        DateFormat dateFormat = new SimpleDateFormat("EE yyyy/MM/dd HH:mm:ss:SS aaa");
        Date date = new Date();
        return dateFormat.format(date);
    } 
    
    /**
     * To stop default ant logging.
     */
    private void stopDefaultAntLog(String stageName) {
        String time = getDateTime();
        StageLogging defaultStageLogging = defaultRecordMap.get("default");
        StageLogging stageLogging = stageRecordMap.get(stageName);
        File logFile = new File(defaultStageLogging.getDefaultOutput());
        if (logFile.exists()) {
            recorderEntry = getRecorder(defaultStageLogging.getDefaultOutput(), StatusAndLogListener.getProject());
            recorderEntry.addLogMessage("Stopping logging into " + defaultStageLogging.getDefaultOutput() + " and starting logging for stage \"" + stageName + "\" at " + time);
            recorderEntry.addLogMessage("Starting logging into " + stageLogging.getOutput());
            recorderEntry.setRecordState(false);
        }
    }
    
    /**
     * To start deafult ant logging.
     */
    
    private void startDefaultAntLog() {
        String time = getDateTime();
        StageLogging stageLogging = defaultRecordMap.get("default");
        recorderEntry = getRecorder(stageLogging.getDefaultOutput(), StatusAndLogListener.getProject());
        recorderEntry.addLogMessage("Resuming logging into " + stageLogging.getDefaultOutput() + " at " + time );
        recorderEntry.setRecordState(true);
    }
    
    /**
     * To get the current stage running.
     * @return
     */
    public String getCurrentStageName() {
        
        return this.currentStageName;
    }
    
    /**
     * To do the logging actions depending on hlm:record actions.
     * @param stageName
     * @param action
     * @param message
     */
    public void doLoggingAction(String stageName, boolean action, String message, Task task) {
        String time = getDateTime();
        StageLogging stageLogging = null;
        String fileName;
        if (stageName.equalsIgnoreCase("default")) {
            stageLogging = defaultRecordMap.get(stageName);
            fileName = stageLogging.getDefaultOutput();
        } else {
            stageLogging = stageRecordMap.get(stageName);
            fileName = stageLogging.getOutput();
        }
        File logFile = new File(fileName);
        if (logFile.exists()) {
            recorderEntry = getRecorder(fileName, StatusAndLogListener.getProject());
            recorderEntry.addLogMessage(message + " logging into " + fileName + " from " + task.getTaskName() + " task at " + time);
            recorderEntry.setRecordState(action);
        }
    }
    
    /**
     * Called by LogReplace task to find and replace any property values which are not updated.
     * @param regExp
     */
    @SuppressWarnings("unchecked")
    public void addRegExp (String regExp) {
        
        if (!regExp.equals("")) {
            
            for (Map.Entry<String, StageLogging> entry : defaultRecordMap.entrySet() ) {
                StageLogging stageLogging = entry.getValue();
                File logFile = new File(stageLogging.getDefaultOutput());
                if (logFile.exists()) {
                    AntLogRecorderEntry recorderEntry = getRecorder(stageLogging.getDefaultOutput(), StatusAndLogListener.getProject());
                    recorderEntry.addRegexp(regExp);
                }
            }
            
            for (Map.Entry<String, StageLogging> entry : stageRecordMap.entrySet() ) {
                StageLogging stageLogging = entry.getValue();
                File logFile = new File(stageLogging.getOutput());
                if (logFile.exists()) {
                    AntLogRecorderEntry recorderEntry = getRecorder(stageLogging.getOutput(), StatusAndLogListener.getProject());
                    recorderEntry.addRegexp(regExp);
                }
            }
            
        }
    }

}


