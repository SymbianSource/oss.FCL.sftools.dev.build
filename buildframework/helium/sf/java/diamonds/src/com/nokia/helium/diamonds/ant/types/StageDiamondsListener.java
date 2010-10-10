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

package com.nokia.helium.diamonds.ant.types;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.ant.Message;
import com.nokia.helium.core.ant.types.Stage;
import com.nokia.helium.diamonds.DiamondsException;
import com.nokia.helium.diamonds.DiamondsListener;
import com.nokia.helium.diamonds.ant.Listener;

/**
 * The targetTimingMessageListener should be used as a reference in a build
 * file so the message listener can detect it an record target execution time 
 * before sending it.
 * 
 * <pre>
 *      &lt;hlm:stageMessageListener id=&quot;stage.message.listener&quot;&gt;
 *          &lt;hlm:fmppMessage sourceFile="tool.xml.ftl"&gt;
 *              &lt;data expandProperties="yes"&gt;
 *                  ant: antProperties()
 *              &lt;/data&gt;
 *          &lt;/hlm:fmppMessage&gt;
 *      &lt;/hlm:stageMessageListener&gt; 
 * </pre>
 * 
 * @ant.type name="stageMessageListener" category="Diamonds"
 */
public class StageDiamondsListener extends DataType implements DiamondsListener {
    private Listener diamondsListener;
    private List<DiamondsStage> stages = new ArrayList<DiamondsStage>();
    private List<DiamondsStage> completedStages = new ArrayList<DiamondsStage>();
    private DiamondsStage currentStage;
    private Message message;
    
    class DiamondsStage extends Stage {
        private Date startTime;
        private Date endTime;
        private String stageName;
            
        public DiamondsStage(Stage stage) {
            this.setEndTarget(stage.getEndTarget());
            this.setStartTarget(stage.getStartTarget());
            stageName = stage.getStageName();
        }
        
        public void setStartTime(Date startTime) {
            this.startTime = startTime;
        }
        
        public void setEndTime(Date endTime) {
            this.endTime = endTime;
        }

        public void setProperties(Project project, String timeFormatString) {
            SimpleDateFormat timeFormat = new SimpleDateFormat(timeFormatString);
            project.setProperty("logical.stage", this.getStageName());
            project.setProperty("stage.start.time", timeFormat.format(startTime));
            project.setProperty("stage.end.time", timeFormat.format(endTime));
        }

        public String getStageName() {
            return stageName;
        }        
    }

    @SuppressWarnings("unchecked")
    public void configure(Listener listener) throws DiamondsException {
        diamondsListener = listener;
        if (message == null) {
            throw new BuildException(this.getDataTypeName() + " must have one nested message at " + this.getLocation());
        }
        Map<String, String> startStageName = new Hashtable<String, String>();
        for (Map.Entry<String, Object> entry : ((Map<String, Object>)listener.getProject().getReferences()).entrySet()) {
            if (entry.getValue() instanceof Stage) {
                Stage stage = (Stage)entry.getValue();
                if (stage.getStartTarget() != null && stage.getEndTarget() != null) {
                    if (startStageName.containsKey(stage.getStartTarget())) {
                        log("Stage " + entry.getKey() + " uses the start target named '" + stage.getStartTarget() +
                                "' which is already used by stage " + startStageName.get(stage.getStartTarget()) +
                                ". Stage " + entry.getKey() + " will be ignored.", Project.MSG_WARN);
                    } else {
                        if (!getProject().getTargets().containsKey(stage.getStartTarget())) {
                            log("Stage " + entry.getKey() + " refer to an inexistant start target: " + stage.getStartTarget()
                                    + ". Stage will be ignored", Project.MSG_ERR);
                        } else if (!getProject().getTargets().containsKey(stage.getEndTarget())) {
                            log("Stage " + entry.getKey() + " refer to an inexistant end target: " + stage.getEndTarget()
                                    + ". Stage will be ignored", Project.MSG_ERR);
                        } else {
                            startStageName.put(stage.getStartTarget(), entry.getKey());
                            DiamondsStage diamondsStage = new DiamondsStage(stage);
                            stages.add(diamondsStage);
                        }
                    }
                }
            }
        }        
    }

    
    public void buildFinished(BuildEvent buildEvent) throws DiamondsException {
        if (currentStage != null) {
            currentStage.setEndTime(new Date());
            completedStages.add(currentStage);
            currentStage = null;
        }
    }
    
    public void buildStarted(BuildEvent buildEvent) throws DiamondsException {
    }
    
    public synchronized void targetFinished(BuildEvent buildEvent) throws DiamondsException {
        if (currentStage != null) {
            if (buildEvent.getTarget().getName().equals(currentStage.getEndTarget())) {
                getProject().log("Stage ending - " + currentStage.getStageName(), Project.MSG_DEBUG);
                currentStage.setEndTime(new Date());
                completedStages.add(currentStage);
                try {
                    sendCompletedStage(currentStage);
                } finally {
                    currentStage = null;
                }
            }
        }
    }

    protected void sendCompletedStage(DiamondsStage stage) throws DiamondsException {
        if (message != null) {
            stage.setProperties(diamondsListener.getProject(), diamondsListener.getConfiguration().getTimeFormat());
            diamondsListener.getSession().send(message);
        }
    }
    
    public synchronized void targetStarted(BuildEvent buildEvent) throws DiamondsException {
        if (currentStage == null) {
            currentStage = geStageByStartTarget(buildEvent.getTarget().getName());
            if (currentStage != null) {
                getProject().log("Stage starting - " + currentStage.getStageName(), Project.MSG_DEBUG);
                currentStage.setStartTime(new Date());
            }
        } else {
            // In this case we have an overlap...
            DiamondsStage newStage = geStageByStartTarget(buildEvent.getTarget().getName());
            if (newStage != null) {
                getProject().log("Stage " + currentStage.getStageName() + " and stage " + newStage.getStageName() + " are overlapping.", Project.MSG_WARN);
                getProject().log("Stage ending - " + currentStage.getStageName(), Project.MSG_DEBUG);
                currentStage.setEndTime(new Date());
                newStage.setStartTime(new Date());
                completedStages.add(currentStage);
                try {
                    sendCompletedStage(currentStage);
                } finally {
                    currentStage = newStage;
                    getProject().log("Stage starting - " + currentStage.getStageName(), Project.MSG_DEBUG);
                }
                
            }
        }
    }
    
    private DiamondsStage geStageByStartTarget(String targetName) {
        for (DiamondsStage stage : stages) {
            if (targetName.equals(stage.getStartTarget())) {
                return stage;
            }
        }
        return null;
    }
    
    
    public void add(Message message) {
        if (this.message != null) {
            throw new BuildException(this.getDataTypeName() + " cannot accept more than one nested message at " + this.getLocation());
        }
        this.message = message;
    }
}