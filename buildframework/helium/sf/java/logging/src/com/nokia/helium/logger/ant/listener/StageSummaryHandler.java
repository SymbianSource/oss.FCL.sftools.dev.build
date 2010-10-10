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
import java.io.StringWriter;
import java.text.DateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import org.apache.tools.ant.util.DateUtils;

import com.nokia.helium.core.ant.types.Stage;

import freemarker.cache.FileTemplateLoader;
import freemarker.template.Configuration;
import freemarker.template.Template;

/**
 * <code>StageStatusHandler</code> is the handler class responsible for
 * displaying the summary of the various configured build stages at the end of
 * build process.
 * 
 */
public class StageSummaryHandler implements BuildEventHandler, TargetEventHandler {

    public static final String PASSED = "PASSED";
    public static final String FAILED = "FAILED";

    private boolean summarize;
    private boolean initialized;
    

    private Map<String, StageWrapper> completedStages = new LinkedHashMap<String, StageWrapper>();;
    private StageWrapper currentStage;
    private Hashtable<String, Stage> stages;
    private File template;

    public StageSummaryHandler(File template) {
        this.template = template;
    }

    /**
     * {@inheritDoc}
     */
    public void buildStarted(BuildEvent event) {

    }

    /**
     * {@inheritDoc}
     */
    public void buildFinished(BuildEvent event) {
        if (summarize && currentStage != null) {
            endCurrentStage();
        }
        if (summarize && !completedStages.isEmpty()) {
            generateSummary(event.getProject());
            CommonListener.getCommonListener().getProject().log("Stage Summary generation completed", Project.MSG_DEBUG);
        }
    }

    /**
     * {@inheritDoc}
     */
    public void targetStarted(BuildEvent event) {
        if (!initialized) {
            if (template != null) {
                parseStages(event.getProject());
                CommonListener.getCommonListener().getProject().log("Stage summary enabled...", Project.MSG_DEBUG);
                summarize = true;
            } else {
                
                CommonListener.getCommonListener().getProject().log("Stage summary disabled because template is missing.", Project.MSG_DEBUG);
            }
            initialized = true;
        }

        if (summarize && doRunTarget(event)) {
            StageWrapper stage = searchNewStage(event);
            if (stage != null) {
                startNewStage(stage);
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    public void targetFinished(BuildEvent event) {
        if (summarize && isCurrentStageToEnd(event)) {
            endCurrentStage();
        }
    }

    /**
     * Indicates whether the current stage is ending or not.
     * 
     * @param event
     *            is the build event.
     * @return true, if the build failed or the end target of the stage is
     *         reached; otherwise false.
     */
    private boolean isCurrentStageToEnd(BuildEvent event) {
        boolean end = false;
        if (currentStage != null) {
            if (event.getException() != null) {
                currentStage.setError(getReason(event.getException()));
                end = true;
            } else {
                end = currentStage.stage.isEndTarget(event.getTarget()
                        .getName());
            }
        }
        return end;
    }

    /**
     * Start the given stage as a new build stage.
     * 
     * @param newStage
     *            is the new build stage to start.
     */
    private void startNewStage(StageWrapper newStage) {
        endCurrentStage();
        Long currTime = getCurrentTime();
        if (!completedStages.containsKey(newStage.stageName)) {
            newStage.setStageStartTime(getTimestamp(currTime));
        }
        newStage.setStartTime(currTime);
        this.currentStage = newStage;
        CommonListener.getCommonListener().getProject().log("New stage [" + newStage.stageName + "] started at "
                + getTimestamp(currTime), Project.MSG_DEBUG);
    }

    /**
     * End the current stage.
     * 
     */
    private void endCurrentStage() {
        if (currentStage != null) {
            Long currTime = getCurrentTime();
            if (completedStages.containsKey(currentStage.stageName)) {
                StageWrapper stg = completedStages.get(currentStage.stageName);
                stg.setDuration(stg.duration
                        + getTimeElapsed(currentStage.startTime, currTime));
            } else {
                currentStage.setDuration(getTimeElapsed(currentStage.startTime,
                        currTime));
                completedStages.put(currentStage.stageName, currentStage);
            }
            CommonListener.getCommonListener().getProject().log("Stage [" + currentStage.stageName + "] finished at "
                    + getTimestamp(currTime), Project.MSG_DEBUG);
            currentStage = null;
        }
    }

    /**
     * Search for the new Stage based on the given build event.
     * 
     * @param event
     *            is the build event fired.
     * @return an instance of StageWrapper, if the build event marks the start
     *         of a configured Stage.
     */
    private StageWrapper searchNewStage(BuildEvent event) {
        StageWrapper stageWrapper = null;
        String target = event.getTarget().getName();
        for (String stageName : stages.keySet()) {
            Stage stage = stages.get(stageName);
            if (isStartingTarget(target, event.getProject(), stage)) {
                stageWrapper = new StageWrapper(stageName, stage);
                break;
            }
        }
        return stageWrapper;
    }

    /**
     * Return whether the given target is a starting target of the given stage.
     * 
     * @param targetName
     *            is the target to check.
     * @param project
     *            is the project to lookup for target
     * @param stage
     *            is the stage to check.
     * @return
     */
    @SuppressWarnings("unchecked")
    private boolean isStartingTarget(String targetName, Project project,
            Stage stage) {
        boolean bool = false;
        if (project.getTargets().containsKey(stage.getStartTarget())) {
            Vector<Target> dependencies = project.topoSort(stage
                    .getStartTarget(), project.getTargets(), false);
            if (!dependencies.isEmpty()) {
                Target target = dependencies.firstElement();
                bool = target.getName().equals(targetName);
            }
        }
        return bool;
    }

    /**
     * Parse and cache the stages configured.
     * 
     * @param project
     *            is the project to lookup for stages.
     */
    @SuppressWarnings("unchecked")
    private void parseStages(Project project) {
        stages = new Hashtable<String, Stage>();
        Hashtable<String, Object> references = project.getReferences();
        for (Enumeration<String> en = references.keys(); en.hasMoreElements();) {
            String key = en.nextElement();
            Object value = references.get(key);
            if (value instanceof Stage) {
                validateStageInformation(key, (Stage) value);
                stages.put(key, (Stage) value);
            }
        }
    }

    /**
     * Return the reason for build failure in String format.
     * 
     * @param th
     *            is the cause of build failure if any.
     * @return String representing the build failure.
     */
    private String getReason(Throwable th) {
        return (th != null) ? th.getMessage() : "";
    }

    /**
     * Return the current time in milliseconds.
     * 
     * @return the current time in milliseconds.
     */
    private Long getCurrentTime() {
        return System.currentTimeMillis();
    }

    /**
     * Method is used to construct build reports for the completed stages.
     * 
     * @return a list of build status reports.
     */
    private List<BuildStatusReport> constructBuildStatusReports() {
        List<BuildStatusReport> reports = new ArrayList<BuildStatusReport>();
        BuildStatusReport report = null;
        StageWrapper stage = null;
        for (String stageName : completedStages.keySet()) {
            stage = completedStages.get(stageName);
            report = new BuildStatusReport(stageName, stage.stageStartTime,
                    format2String(stage.duration), stage.error);
            reports.add(report);
        }
        return reports;
    }

    /**
     * Generate build summary.
     * 
     */
    private void generateSummary(Project project) {
        if (template != null) {
            try {
                Configuration cfg = new Configuration();
                CommonListener.getCommonListener().getProject().log("Basedir: " + template.getParentFile(), Project.MSG_DEBUG);
                cfg.setTemplateLoader(new FileTemplateLoader(template
                        .getParentFile()));
                Template templ = cfg.getTemplate(template.getName());
                StringWriter writer = new StringWriter();
                templ.process(getTemplateData(), writer);
                project.log(writer.toString());
            } catch (freemarker.core.InvalidReferenceException ivx) {
                project.log("Invalid reference in config: ", ivx,
                        Project.MSG_WARN);
            } catch (freemarker.template.TemplateException e2) {
                project.log("TemplateException: ", e2, Project.MSG_WARN);
            } catch (java.io.IOException e) {
                project.log("I/O Error during template conversion: "
                        + e.toString(), Project.MSG_WARN);
            }
        }
    }

    /**
     * Return the data-model to be merged with the template.
     * 
     * @return a Map representing template data-model.
     */
    private Map<String, Object> getTemplateData() {
        Map<String, Object> templateMap = new HashMap<String, Object>();
        List<BuildStatusReport> statusReports = constructBuildStatusReports();
        templateMap.put("statusReports", statusReports);
        return templateMap;
    }

    /**
     * Get the given date as String format.
     * 
     * @param date
     *            is the date to be formatted as String.
     * @return given date formated as String
     */
    private String getTimestamp(long date) {
        Date dt = new Date(date);
        DateFormat formatter = DateFormat.getDateTimeInstance(DateFormat.SHORT,
                DateFormat.SHORT);
        String finishTime = formatter.format(dt);
        return finishTime;
    }

    /**
     * Get the time duration for the given start and end times.
     * 
     * @param startTime
     *            is the start time.
     * @param endTime
     *            is the end time.
     * @return total time elapsed.
     */
    private Long getTimeElapsed(Long startTime, Long endTime) {
        return endTime - startTime;
    }

    /**
     * Return the given elapsed time in String format.
     * 
     * @param time
     *            is the time to be formatted as String.
     * @return time elapsed in String format.
     */
    private String format2String(Long time) {
        return DateUtils.formatElapsedTime(time);
    }

    /**
     * To validate stage information.
     * 
     * @param stageKey
     * @param stage
     */
    private void validateStageInformation(String stageKey, Stage stage) {

        if (stage.getStartTarget() == null) {
            throw new BuildException("'starttarget' attribute for stage '" + stageKey
                    + "' is not defined.");
        }

        if (stage.getEndTarget() == null) {
            throw new BuildException("'endtarget' attribute for stage '" + stageKey
                    + "' is not defined.");
        }
    }

    /**
     * Method indicates whether the target is to be considered for build stage
     * summary or not.
     * 
     * @param event
     *            is the build event.
     * @return true, if the target is enabled;otherwise false
     */
    private boolean doRunTarget(BuildEvent event) {
        boolean doRun = true;

        String ifCondition = event.getTarget().getIf();

        if (ifCondition != null && !ifCondition.isEmpty()) {
            String prop = event.getProject().replaceProperties(ifCondition);
            doRun = event.getProject().getProperty(prop) != null;
        }

        String unlessCondition = event.getTarget().getUnless();

        if (unlessCondition != null && !unlessCondition.isEmpty()) {
            String prop = event.getProject().replaceProperties(unlessCondition);
            doRun = event.getProject().getProperty(prop) == null;
        }
        return doRun;
    }

    /**
     * A wrapper class for Stage.
     * 
     */
    private class StageWrapper {
        private Stage stage;
        private String stageName;
        private String error;
        private String stageStartTime;
        private Long startTime;
        private Long duration;

        public StageWrapper(String stageName, Stage stage) {
            this.stageName = stageName;
            this.stage = stage;
        }

        public void setStartTime(Long startTime) {
            this.startTime = startTime;
        }

        public void setError(String error) {
            this.error = error;
        }

        public void setDuration(Long duration) {
            this.duration = duration;
        }

        public void setStageStartTime(String stageStartTime) {
            this.stageStartTime = stageStartTime;
        }
    }
}
