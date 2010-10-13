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
import java.util.ArrayList;
import java.util.Date;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Vector;
import java.util.regex.Pattern;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.ant.types.Stage;
import com.nokia.helium.logger.ant.types.StageRecord;


/**
 * Ant logging class for each Stage.
 * 
 * 
 */
public class AntLoggingHandler extends DataType implements BuildEventHandler, TargetEventHandler, SubBuildEventHandler, CommonListenerRegister {
    private Map<String, RecorderEntry> recorderEntries = new Hashtable<String, RecorderEntry>();
    private Map<String, Stage> stageStartTargets = new Hashtable<String, Stage>();
    private Map<String, Stage> stageEndTargets = new Hashtable<String, Stage>();
    private RecorderEntry defaultRecorderEntry;
    private RecorderEntry currentRecorderEntry;
    private Stage currentStage;
    private CommonListener commonListener;
    private boolean record;
    private List<Project> recordExclusions = new ArrayList<Project>();
    
    @SuppressWarnings("unchecked")
    public void register(CommonListener commonListener) {
        this.commonListener = commonListener;
        Map<String, Object> references = (Map<String, Object>)commonListener.getProject().getReferences();
        for (Map.Entry<String, Object> entry : references.entrySet()) {
            if (entry.getValue() instanceof StageRecord) {
                StageRecord stageRecord = (StageRecord)entry.getValue();
                if (stageRecord.getDefaultOutput() != null) {
                    if (defaultRecorderEntry == null) {
                        RecorderEntry recorderEntry = new RecorderEntry(stageRecord.getDefaultOutput());
                        recorderEntry.setMessageOutputLevel(stageRecord.getLogLevel());
                        recorderEntry.setEmacsMode(false);
                        recorderEntry.setRecordState(false);
                        defaultRecorderEntry = recorderEntry;
                    } else {
                        log("There must be only one default stagerecord datatype.");
                    }
                } else if (stageRecord.getStageRefID() != null) {
                    if (references.containsKey(stageRecord.getStageRefID())) {
                        if (references.get(stageRecord.getStageRefID()) instanceof Stage) {
                            // Check the stage
                            Stage stage = (Stage)references.get(stageRecord.getStageRefID());
                            validateStageInformation(stageRecord.getStageRefID(), stage);
                            log("Found  stage [" + stageRecord.getStageRefID() + "] for recording", Project.MSG_DEBUG);
                            //  check the stage logging.
                            validateStageRecorder(entry.getKey(), stageRecord);
                            String startTarget = stage.getStartTarget();
                            if (getProject().getTargets().containsKey(stage.getStartTarget())) {
                                Vector<Target> targets = getProject().topoSort(stage.getStartTarget(), getProject().getTargets(), false);
                                if (targets.size() != 0) {
                                    startTarget = targets.firstElement().getName();
                                }
                            }

                            if (stageRecord.getOutput().exists()) {
                                long timestamp = System.currentTimeMillis();
                                log("Backing up of " + stageRecord.getOutput() + " into " + stageRecord.getOutput() + "."
                                        + timestamp);
                                stageRecord.getOutput().renameTo(new File(stageRecord.getOutput().getAbsoluteFile() + "." + timestamp));
                            }
                            
                            RecorderEntry recorderEntry = new RecorderEntry(stageRecord.getOutput());
                            recorderEntry.setMessageOutputLevel(stageRecord.getLogLevel());
                            recorderEntry.setEmacsMode(false);
                            recorderEntry.setRecordState(false);

                            // Make sure we cleanup the file now if needed.
                            if (stageRecord.getOutput().exists()) {
                                recorderEntry.openFile(stageRecord.getAppend());                            
                                recorderEntry.closeFile();
                            }
                            
                            // Then add everything to the internal configuration
                            stageStartTargets.put(startTarget, stage);
                            stageEndTargets.put(stage.getEndTarget(), stage);
                            recorderEntries.put(stageRecord.getStageRefID(), recorderEntry);
                        } else {
                            throw new BuildException("Invalid stagerecord stageRefId attribute value, " + 
                                    "the '" + stageRecord.getStageRefID() + "' id doesn't refer to a stage type at " + 
                                    stageRecord.getLocation().toString());
                            
                        }
                    } else {
                        throw new BuildException("Invalid stagerecord stageRefId attribute value, " + 
                                "the '" + stageRecord.getStageRefID() + "' id doesn't exist at " + 
                                    stageRecord.getLocation().toString());
                    }
                } else {
                    throw new BuildException("Invalid stagerecord configuration, " + 
                            "the stageRefId attribute is not defined at " +
                            stageRecord.getLocation().toString());
                }
            }
        }
        if (defaultRecorderEntry != null) {
            log("Registering the logging framework.", Project.MSG_DEBUG);
            currentRecorderEntry = defaultRecorderEntry;
            commonListener.register(this);
        } else {
            log("There must be one default stagerecord datatype. Logging framework will be disabled.");
        }
    }

    private void validateStageInformation(String stageKey, Stage stage) {
        if (stage.getStartTarget() == null) {
            throw new BuildException("'starttarget' for stage '" + stageKey
                + "' should not be null.");
        }
        if (stage.getEndTarget() == null) {
            throw new BuildException("'endtarget' for stage '" + stageKey + "' should not be null.");
        }        
    }

    /**
     * To validate each stagelogging data type.
     * 
     * @param stagerefid
     * @param stageLogging
     */
    private void validateStageRecorder(String stagerefid, StageRecord stageRecorder) {
        if (stageRecorder.getOutput() == null) {
            throw new BuildException("'output' attribute for stagelogging '" + stagerefid
                + "' should not be null.");
        }
    }    

    /**
     * A new stage is starting. Stop current log, then start stage specific log recording.
     * @param target
     * @param stage
     */
    protected void startStage(Target target, Stage stage) {
        if (record && currentRecorderEntry != null) {
            currentRecorderEntry.addLogMessage("Stop logging into " + currentRecorderEntry.getFilename() + " at " + getDateTime());            
            currentRecorderEntry.setRecordState(false);
            currentRecorderEntry.closeFile();            
            commonListener.unRegister(currentRecorderEntry);
        }
        currentRecorderEntry = recorderEntries.get(stage.getStageName());
        if (currentRecorderEntry == null) {
            currentRecorderEntry = this.defaultRecorderEntry;
        }
        if (record) {
            defaultRecorderEntry.reopenFile();
            defaultRecorderEntry.addLogMessage("Start logging stage " + stage.getStageName() + " into " + currentRecorderEntry.getFilename() + " at " + getDateTime());
            defaultRecorderEntry.closeFile();
            
            currentRecorderEntry.reopenFile();
            currentRecorderEntry.setRecordState(true);
            currentRecorderEntry.addLogMessage("Start logging into " + currentRecorderEntry.getFilename() + " at " + getDateTime());
            commonListener.register(currentRecorderEntry);
        }        
    }
    
    /**
     * Current stage is ending. Stop recording current stage, and then switch to
     * default log.
     * @param target
     * @param stage
     */
    protected void endStage(Target target, Stage stage) {
        if (record && currentRecorderEntry != null) {
            currentRecorderEntry.addLogMessage("Stop logging into " + currentRecorderEntry.getFilename() + " at " + getDateTime());            
            currentRecorderEntry.setRecordState(false);
            currentRecorderEntry.closeFile();
            commonListener.unRegister(currentRecorderEntry);
        }
        currentRecorderEntry = defaultRecorderEntry;
        if (record) {
            currentRecorderEntry.reopenFile();
            currentRecorderEntry.setRecordState(true);
            currentRecorderEntry.addLogMessage("Start logging into " + currentRecorderEntry.getFilename() + " at " + getDateTime());            
            commonListener.register(currentRecorderEntry);
        }        
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public synchronized void targetStarted(BuildEvent event) {
        if (stageStartTargets.containsKey(event.getTarget().getName())) {
            if (this.currentStage != null) {
                endStage(event.getTarget(), currentStage);
            }
            currentStage = stageStartTargets.get(event.getTarget().getName()); 
            startStage(event.getTarget(), currentStage);
        }
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public synchronized void targetFinished(BuildEvent event) {
        if (currentStage != null && currentStage.getEndTarget().equals(event.getTarget().getName())) {
            endStage(event.getTarget(), currentStage);
            currentStage = null;
        }
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void buildStarted(BuildEvent event) {
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public synchronized void buildFinished(BuildEvent event) {
        if (currentRecorderEntry != defaultRecorderEntry) {
            currentRecorderEntry.addLogMessage("Stop logging into " + currentRecorderEntry.getFilename() + " at " + getDateTime());            
            currentRecorderEntry.setRecordState(false);
            currentRecorderEntry.closeFile();
            commonListener.unRegister(currentRecorderEntry);
            currentRecorderEntry = defaultRecorderEntry;
        }
        defaultRecorderEntry.reopenFile();
        defaultRecorderEntry.setRecordState(true);
        defaultRecorderEntry.addLogMessage("Start logging into " + defaultRecorderEntry.getFilename() + " at " + getDateTime());            
        defaultRecorderEntry.buildFinished(event);
        defaultRecorderEntry.setRecordState(false);
        defaultRecorderEntry.closeFile();
        record = false;
    }

    /**
     * Define if the stage logging should be recording of not.
     * @param record
     */
    public synchronized void setRecordState(boolean record) {
        this.record = record;
        if (record) {
            currentRecorderEntry.reopenFile();
            currentRecorderEntry.setRecordState(true);
            this.commonListener.register(this.currentRecorderEntry);
        } else {
            currentRecorderEntry.setRecordState(false);
            this.commonListener.unRegister(this.currentRecorderEntry);
            currentRecorderEntry.closeFile();
        }
    }
    
    /**
     * Adding a regular expression 
     * @param pattern
     */
    public void addRegexp(Pattern pattern) {
        if (pattern != null) {
            for (Entry<String, RecorderEntry> entry : recorderEntries.entrySet()) {
                RecorderEntry recorderEntry = entry.getValue();
                recorderEntry.addRegexp(pattern);
            }
        }
    }

    /**
     * Prunning a project/subproject from stage logger recording scope. 
     * @param project
     */
    public synchronized void addRecordExclusion(Project project) {
        if (!recordExclusions.contains(project)) {
            recordExclusions.add(project);
            if (currentRecorderEntry != null) {
                currentRecorderEntry.setExcludedProject(recordExclusions);
            }
        }
    }

    /**
     * Allow an external task to add again a project into recording scope.
     * @param project
     */
    public synchronized void removeRecordExclusion(Project project) {
        recordExclusions.remove(project);        
    }
    
    /**
     * Get formated date and time
     */
    private String getDateTime() {
        DateFormat dateFormat = new SimpleDateFormat("EE yyyy/MM/dd HH:mm:ss:SS aaa");
        Date date = new Date();
        return dateFormat.format(date);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void subBuildFinished(BuildEvent event) {
        removeRecordExclusion(event.getProject());
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void subBuildStarted(BuildEvent event) {
    }
}