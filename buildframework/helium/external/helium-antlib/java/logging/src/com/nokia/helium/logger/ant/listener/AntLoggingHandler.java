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

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.LogLevel;
import org.apache.tools.ant.BuildException;
import org.apache.log4j.Logger;

import com.nokia.helium.logger.ant.types.StageLogging;
import com.nokia.helium.logger.ant.types.Stage;


    /**
     * Ant logging class for each Stage. 
     * 
     *
     */
public class AntLoggingHandler implements Handler {
    private static Hashtable<File, RecorderEntry> recorderEntries = new Hashtable<File, RecorderEntry>();
    private Map<String, Stage> stagesMapping ;
    private Map<String, StageLogging> stageRecordMap;
    private HashMap<String, Vector<Target>> depStartTargetMap;
    private HashMap<String, Target> stageStartTargetMap;
    private HashMap<File, Boolean> fileCreatedMap;
    private boolean isStageRecordingHappening;
    private boolean loggingStarted;
    private boolean isStageInformationInited;
    private boolean isDefaultStageStarted;
    private int loglevel = -1;
    private VerbosityLevelChoices antLogLevel;
    private Logger log = Logger.getLogger(AntLoggingHandler.class);
    private String currentStageName;
    private Project project;
    
    /**
     * AntLoggingHandler constructor.
     * @param proj
     */
    public AntLoggingHandler(Project proj) {
        project = proj;
        antLogLevel = new VerbosityLevelChoices();
        stagesMapping = new HashMap<String, Stage>();
        stageRecordMap = new HashMap<String, StageLogging>();
        depStartTargetMap = new HashMap<String, Vector<Target>>();
        stageStartTargetMap = new HashMap<String, Target>();
        fileCreatedMap = new HashMap<File, Boolean>();
    }

    /** Return the project associated to this Handler.
     * @return a project instance
     */
    public Project getProject() {
        return project;
    }
    
    /**
     * {@inheritDoc}
     */
    public void handleTargetFinished(BuildEvent event) {
        //log.debug("Finished target [" + event.getTarget().getName() + "]");
        if (isEndTarget(event.getTarget().getName()) && getIsStageRecordingHappening() && (getLoggingStarted())) {
            log.debug("Stopping stage logging for  [" + currentStageName + "] for target [" + event.getTarget().getName() + "]");
            stopLog(currentStageName, "default");
            startLog("default");
            currentStageName = null;
        }
    }
    
    /**
     * {@inheritDoc}
     */
    public void handleTargetStarted(BuildEvent event) {
        
        //log.debug("Started target [" + event.getTarget().getName() + "]");
        if (!this.isStageInformationInited) {
            initStagesInformation(event.getProject());
            this.isStageInformationInited = true;
        }
        
        if (this.isStageInformationInited && getLoggingStarted() && !this.isDefaultStageStarted) {
            startLog("default");
            this.isDefaultStageStarted = true;
        }
        
        if (currentStageName == null && !getIsStageRecordingHappening() && (getLoggingStarted())) {
            String stageName = isStageValid(event.getTarget(), event.getProject());
            if (stageName != null) {
                log.debug("Started stage logging for  [" + stageName + "] for target [" + event.getTarget().getName() + "]" );
                stopLog("default", stageName);
                startLog(stageName);
                currentStageName = stageName;
            }
        }
    }
    
    /**
     * {@inheritDoc}
     */
    public void handleBuildStarted(BuildEvent event) {
        // Nothing to do
    }
    
    /**
     * {@inheritDoc}
     */
    public void handleBuildFinished(BuildEvent event) {
        if (this.isDefaultStageStarted && getLoggingStarted()) {
            stopLog("default", null, event);
        }
        this.cleanup();
    }
    
        
    /**
     * Returns recorder entry for logging current build process.
     * @param name
     * @param proj
     * @return
     */
    protected RecorderEntry getRecorder(File name) {
        RecorderEntry entry = recorderEntries.get(name);
        if (entry == null) {
            // create a recorder entry
            entry = new RecorderEntry(name);
            recorderEntries.put(name, entry);
        }
        return entry;
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
     * To clean recorder entries.
     */
    private void cleanup() {
        log.debug("Cleaning up recorder entries of stagerecord");
        recorderEntries.clear();
        
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
     * @param task
     */
    public void doLoggingAction(String stageName, boolean action, String message, Task task, Target target) {
        String time = getDateTime();
        File fileName;
        if (stageName.equalsIgnoreCase("default")) {
            fileName = stageRecordMap.get("default").getDefaultOutput();
        } else {
            fileName = stageRecordMap.get(stageName).getOutput();
        }
        
        if (fileName.exists()) {
            for (Map.Entry<File, RecorderEntry> entry : recorderEntries.entrySet() ) {
                if (fileName.equals(entry.getKey()) && (getRecorderEntry(fileName) != null) && (fileCreatedMap.get(fileName))) {
                    RecorderEntry recorderEntry = getRecorderEntry(fileName);
                    recorderEntry.addLogMessage(message + " logging into " + fileName + " from " + task.getTaskName() + " task at " + time);
                    log.debug(message + " logging into " + fileName + " from " + task.getTaskName() + " task at " + time);
                    recorderEntry.setRecordState(action);
                    break;
                }
            }
        }
    }
    
    
    /**
     * Called by LogReplace task to find and replace any property values which are not updated.
     * @param regExp
     */
    public void addRegExp (String regExp) {
        if (!regExp.equals("")) {
            for (Map.Entry<File, RecorderEntry> entry : recorderEntries.entrySet() ) {
                RecorderEntry recorderEntry = entry.getValue();
                recorderEntry.addRegexp(regExp);
            }
        }
    }
    
    /**
     * To initialize stages information.
     * @param proj
     */
    
    @SuppressWarnings("unchecked")
    private void initStagesInformation(Project proj) {
        log.debug("initStagesInformation: project: " + proj.getName());
        Hashtable<String, Object> references = proj.getReferences(); 
        Enumeration<String> keyEnum = references.keys();
        validateDefaultStage(references);
        while (keyEnum.hasMoreElements()) {
            String key = keyEnum.nextElement();
            if (references.get(key) instanceof Stage) {
                Stage tempStage = (Stage)references.get(key);
                validateStageInformation(key, tempStage);
                log.debug("Found  stage [" + key + "] for recording");
                stagesMapping.put(key, (Stage)references.get(key));
                getStageRecordInformation(proj, key);
                initDependentTargetMap(proj, key, tempStage.getStartTarget(), tempStage.getEndTarget());
            }
        }
    }
    
    /**
     * To initialize stage record information.
     * @param proj
     * @param stageKey
     */
    @SuppressWarnings("unchecked")
    private void getStageRecordInformation(Project proj, String stageKey) {
        Hashtable<String, Object> references = proj.getReferences();
        matchStageName(references, stageKey);
        Enumeration<String> keyEnum = references.keys();
        while (keyEnum.hasMoreElements()) {
            String key = keyEnum.nextElement();
            if (references.get(key) instanceof StageLogging) {
                StageLogging tempStageLogging = (StageLogging)references.get(key);
                if ((tempStageLogging.getStageRefID() != null) && (tempStageLogging.getStageRefID().equals(stageKey))) {
                    validateStageLogging(key, tempStageLogging);
                    stageRecordMap.put(stageKey, tempStageLogging);
                    return;
                }
            }
        }
    }
    
    /**
     * To start logging for respective stage.
     * @param stageName
     */
    private void startLog(String stageName) {
        
        File fileName ;
        String message ;
        String time = getDateTime();
        StageLogging stageLogging = null;
        log.debug("Starting logging for [" + stageName + "]");
        if (stageName.equals("default")) {
            fileName = stageRecordMap.get("default").getDefaultOutput();
            stageLogging = stageRecordMap.get("default");
            message = "Starting logging into " + fileName + " at " + time;
        } else {
            fileName = stageRecordMap.get(stageName).getOutput();
            stageLogging = stageRecordMap.get(stageName);
            this.isStageRecordingHappening = true;
            message = "Starting logging for " + stageName + " into " + fileName + " at " + time;
        }
        if (getRecorderEntry(fileName) != null) {
            RecorderEntry recorderEntry = getRecorderEntry(fileName);
            if (isFilePresent(recorderEntry, fileName, stageLogging)) {
                recorderEntry.setRecordState(true);
                recorderEntry.addLogMessage(message);
            }
        }
    }
    
    /**
     * To check is the file created.
     * @param recorderEntry
     * @param fileName
     * @param stageLogging
     * @return
     */
    private boolean isFilePresent(RecorderEntry recorderEntry, File fileName, StageLogging stageLogging) {
        log.debug("isFilePresent? " + fileName);
        if (!fileCreatedMap.get(fileName)) {
            if (!fileName.getParentFile().exists()) {
                log.debug("Creating dir: " + fileName.getParentFile());
                fileName.getParentFile().mkdirs();
            }
            if (fileName.exists()) {
                long timestamp = System.currentTimeMillis();
                StatusAndLogListener.getStatusAndLogListener().getProject().log("Backing up of " + fileName + " into " + fileName + "." + timestamp);
                fileName.renameTo(new File(fileName.getAbsoluteFile() + "." + timestamp));
            }
            recorderEntry.openFile(stageLogging.getAppend());
            fileCreatedMap.put(fileName, true);
            return true;
        } else {
            return true;
        }
        
    }
    
    /**
     * To stop logging for respective stage.
     * @param stopStageName
     * @param startStageName
     */
    private void stopLog(String stopStageName, String startStageName) {
        stopLog(stopStageName, startStageName, null);
    }
    
    /**
     * To stop logging for respective stage.
     * @param stopStageName
     * @param startStageName
     * @param event
     */
    private void stopLog(String stopStageName, String startStageName, BuildEvent event) {
        
        File fileName ;
        String message ;
        String time = getDateTime();
        log.debug("Stopping logging for [" + stopStageName + "]");
        if (stopStageName.equals("default")) {
            fileName = stageRecordMap.get("default").getDefaultOutput();
            message = "Stopping logging into " + fileName + " at " + time;
            if (startStageName != null )
                message = message + "\nStarting logging into " + stageRecordMap.get(startStageName).getOutput();
        } else {
            fileName = stageRecordMap.get(stopStageName).getOutput();
            this.isStageRecordingHappening = false;
            message = "Stopping logging for " + stopStageName + " into " + fileName + " at " + time;
            if (startStageName != null )
                message = message + "\nResuming logging into " + stageRecordMap.get("default").getDefaultOutput();
        }
        if (getRecorderEntry(fileName) != null) {
            RecorderEntry recorderEntry = getRecorderEntry(fileName);
            if (event != null) {
                recorderEntry.handleBuildFinished(event);
            } else {
                recorderEntry.addLogMessage(message);
                recorderEntry.setRecordState(false);
            }
        }
    }
    
    
    /**
     * To register into recorder entry.
     * @param fileName
     * @param stageLogging
     * @param proj
     */
    private void registerRecorderEntry (File fileName, StageLogging stageLogging, Project proj) {
        log.debug("Registering recorderentry for log file [" + fileName + "]");
        RecorderEntry recorderEntry = getRecorder(fileName);
        antLogLevel.setValue(stageLogging.getLogLevel());
        this.setLoglevel(antLogLevel);
        recorderEntry.setMessageOutputLevel(loglevel);
        recorderEntry.setEmacsMode(false);
        recorderEntry.setRecordState(false);
        fileCreatedMap.put(fileName, false);
    }
    
    /**
     * To check is the stage valid for given start and end targets.
     * @param target
     * @param proj
     * @return
     */
    private String isStageValid(Target target, Project proj) {
        
        if (!proj.getName().equals(StatusAndLogListener.getStatusAndLogListener().getProject().getName()) && (StatusAndLogListener.getStatusAndLogListener().getProject().getName() != null )) {
            initSubProjectDependentTarget(proj);
        }
        for (Map.Entry<String, Stage> entry : stagesMapping.entrySet() ) {
            Stage stage = entry.getValue();
            if (stage.getStartTarget().equals(target.getName()) && validateStageTargets(proj, stage.getStartTarget(), stage.getEndTarget())) {
                log.debug("Found stage [" + entry.getKey() + "] for target [" + target.getName() + "]");
                return entry.getKey();
            } 
            if (stageStartTargetMap.get(entry.getKey()) != null) {
                if (stageStartTargetMap.get(entry.getKey()).getName().equals(target.getName())) {
                    log.debug("Found stage [" + entry.getKey() + "] for dependent target [" + target.getName() + "]");
                    return entry.getKey();
                }
            } else if (isDependentTarget(target, entry.getKey())) {
                log.debug("Found stage [" + entry.getKey() + "] for dependent target [" + target.getName() + "]");
                return entry.getKey();
            }
        }
        return null;
    }
    
    /**
     * To check, is the given target is end target for any stages.
     * @param targetName
     * @return
     */
    
    private boolean isEndTarget(String targetName) {
        if (stagesMapping.get(currentStageName) != null) {
            return stagesMapping.get(currentStageName).getEndTarget().equals(targetName);
        }
        return false;
    }
    
    /**
     * To validate is the endtarget and starttarget are present in the current project.
     * @param proj
     * @param startTarget
     * @param endTarget
     * @return
     */
    
    @SuppressWarnings("unchecked")
    private boolean validateStageTargets(Project proj, String startTarget, String endTarget) {
        
        Hashtable<String, String> antTargets = proj.getTargets();
        return antTargets.containsKey(startTarget) && antTargets.containsKey(endTarget);
    }
    
    /**
     * To check is recording is happening for any stages. 
     * @return
     */
    private boolean getIsStageRecordingHappening() {
        return this.isStageRecordingHappening;
    }
    
    
    /**
     * Is the given target is dependent target to start the stage.
     * @param target
     * @param stageName
     * @return
     */
    private boolean isDependentTarget(Target target, String stageName) {

        if (depStartTargetMap.get(stageName) != null) {
            for (Target depTarget : depStartTargetMap.get(stageName)) {
                if (depTarget.getName().equals(target.getName())) {
                    depStartTargetMap.remove(stageName);
                    stageStartTargetMap.put(stageName, depTarget);
                    return true;
                }
            }
        }
        
        return false;
    }
    
    /**
     * To initialize the dependent target and stages mapping.
     * @param proj
     * @param stageKey
     * @param startTarget
     * @param endTarget
     */
    @SuppressWarnings("unchecked")
    private void initDependentTargetMap(Project proj, String stageKey, String startTarget, String endTarget) {
        Vector<Target> arrayList = null;
        if (validateStageTargets(proj, startTarget, endTarget)) {
            arrayList = proj.topoSort(startTarget, proj.getTargets(), false);
            log.debug("Target dependency for " + startTarget);
            for (Target target : arrayList) {
                log.debug("       Start Target : " + target.getName());
            }
            if (arrayList != null && arrayList.size() > 1) {
                depStartTargetMap.put(stageKey, arrayList);
            }
        }

    }
    
    /**
     * To init dependent targets for subproject.
     * @param proj
     */
    private void initSubProjectDependentTarget(Project proj) {
        
        for (Map.Entry<String, Stage> entry : stagesMapping.entrySet() ) {
            if (depStartTargetMap.get(entry.getKey()) == null) {
                initDependentTargetMap(proj, entry.getKey(), entry.getValue().getStartTarget(), entry.getValue().getEndTarget());
            }
        }
    }
    
    /**
     * To validate stage information.
     * @param stageKey
     * @param stage
     */
    private void validateStageInformation(String stageKey, Stage stage) {
        
        if (stage.getStartTarget() == null ) {
            throw new BuildException("'starttarget' for stage '" + stageKey + "' should not be null.");
        }
        
        if (stage.getEndTarget() == null ) {
            throw new BuildException("'endtarget' for stage '" + stageKey + "' should not be null.");
        }
    }
    
    /**
     * To validate each stagelogging data type.
     * @param stagerefid
     * @param stageLogging
     */
    private void validateStageLogging(String stagerefid, StageLogging stageLogging) {
        
        if (stageLogging.getOutput() == null) {
            throw new BuildException ("'output' attribute for stagelogging '" + stagerefid + "' should not be null." );
        }
        registerRecorderEntry(stageLogging.getOutput(), stageLogging, StatusAndLogListener.getStatusAndLogListener().getProject());
    }
    
    /**
     * To validate default stage.
     * @param stageRecord
     */
    private void validateDefaultStage(Hashtable<String, Object> stageRecord) {
        
        Enumeration<String> keyEnum = stageRecord.keys();
        while (keyEnum.hasMoreElements()) {
            String key = keyEnum.nextElement();
            if (stageRecord.get(key) instanceof StageLogging) {
                StageLogging tempStageLogging = (StageLogging)stageRecord.get(key);
                if ((tempStageLogging.getStageRefID() == null) && (tempStageLogging.getDefaultOutput() != null )) {
                    stageRecordMap.put("default", tempStageLogging);
                    registerRecorderEntry(tempStageLogging.getDefaultOutput(), tempStageLogging, StatusAndLogListener.getStatusAndLogListener().getProject());
                    return;
                }
            }
        }
        throw new BuildException("There should be one default stagerecord datatype.");
    }
    
    /**
     * To validate respective stagelogging for stage datatype.
     * @param stageRecord
     * @param stageKey
     */
    private void matchStageName(Hashtable<String, Object> stageRecord, String stageKey) {
        
        Enumeration<String> keyEnum = stageRecord.keys();
        while (keyEnum.hasMoreElements()) {
            String key = keyEnum.nextElement();
            if (stageRecord.get(key) instanceof StageLogging) {
                StageLogging tempStageLogging = (StageLogging)stageRecord.get(key);
                if ((tempStageLogging.getStageRefID() != null) && (tempStageLogging.getStageRefID().equals(stageKey))) {
                    return;
                }
            }
        }
        throw new BuildException("there is no stagelogging datatype matching for stage '" + stageKey + "'");
    }
    
    /**
     * To retrun recorderEntry of respective file.
     * @param filename
     * @return
     */
    private RecorderEntry getRecorderEntry(File filename) {
        return recorderEntries.get(filename);
    }
    
    /**
     * Is recording started.
     * @return
     */
    public boolean getLoggingStarted() {
        return loggingStarted;
    }

    /**
     * Set to recording started.
     * @param loggingStarted
     */
    public void setLoggingStarted(boolean loggingStarted) {
        this.loggingStarted = loggingStarted;
    }
    
    
    
}

