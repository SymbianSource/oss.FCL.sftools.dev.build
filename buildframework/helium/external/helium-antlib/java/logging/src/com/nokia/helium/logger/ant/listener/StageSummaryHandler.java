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
import java.util.HashSet;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.Vector;

import org.apache.log4j.Logger;
import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import org.apache.tools.ant.util.DateUtils;

import com.nokia.helium.logger.ant.types.Stage;
import com.nokia.helium.logger.ant.types.StageSummary;

import freemarker.cache.FileTemplateLoader;
import freemarker.template.Configuration;
import freemarker.template.Template;

/**
 * <code>StageStatusHandler</code> is the handler class responsible for
 * displaying the summary of the various configured build stages at the end of
 * build process.
 * 
 */
public class StageSummaryHandler implements Handler {

    public static final String PASSED = "PASSED";
    public static final String FAILED = "FAILED";

    private Logger log = Logger.getLogger(getClass());
    private boolean displaySummary;
    private boolean lookup4Stages;
    private boolean summarize;

    private List<BuildStatusReport> statusReports;
    private HashSet<String> completedStages;
    private Hashtable<String, Stage> currentStages;
    private Hashtable<String, Long> currentStagesStartTime;
    private Hashtable<String, Stage> stages;
    private File template;

    /**
     * Create an instance of {@link StageSummaryHandler}
     * 
     */
    public StageSummaryHandler() {
        this.statusReports = new ArrayList<BuildStatusReport>();
        this.completedStages = new HashSet<String>();
        this.currentStages = new Hashtable<String, Stage>();
        this.currentStagesStartTime = new Hashtable<String, Long>();
        log.debug("StageStatusHandler instantiated");
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
        if (summarize && !currentStages.isEmpty()) {
            Long currTime = getCurrentTime();
            String reason = getReason(event.getException());
            Map<String, Stage> tempStages = new Hashtable<String, Stage>(
                    currentStages);
            for (String stageName : tempStages.keySet()) {
                endCurrentStage(stageName, tempStages.get(stageName), reason,
                        currTime);
            }

        }
        if (summarize && displaySummary) {
            generateSummary(event.getProject());
            displaySummary = false;
            log.debug("Stage Summary generation completed");
        }
    }

    /**
     * {@inheritDoc}
     */
    public void handleTargetStarted(BuildEvent event) {
        Project project = event.getProject();
        if (!summarize) {
            StageSummary stageSummary = getStageSummary(project);
            summarize = stageSummary != null
                    && stageSummary.getTemplate() != null;
            lookup4Stages = summarize;
            template = stageSummary.getTemplate();
            log.debug("Is Project configured to display Stage Summary ? "
                    + summarize);
        }

        if (lookup4Stages) {
            log.debug("Loading stages....");
            parseStages(event.getProject());
            log.debug("Total no of stages loaded = " + stages.size());
            lookup4Stages = false;
        }

        log.debug("Handling target - " + event.getTarget().getName());
        if (summarize) {
            Long currTime = getCurrentTime();
            TreeMap<String, Stage> result = searchNewStage(event);
            if (result != null && result.size() == 1) {
                String stageName = result.firstKey();
                Stage stage = result.get(stageName);
                startNewStage(stageName, stage, currTime);
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    public void handleTargetFinished(BuildEvent event) {
        String currentTarget = event.getTarget().getName();
        Long currTime = getCurrentTime();
        String reason = getReason(event.getException());
        if (summarize && !currentStages.isEmpty()) {
            TreeMap<String, Stage> result = getCurrentStageToEnd(currentTarget);
            if (!result.isEmpty()) {
                String stageName = result.firstKey();
                Stage stage = result.get(stageName);
                endCurrentStage(stageName, stage, reason, currTime);
            }
        }
    }

    private TreeMap<String, Stage> getCurrentStageToEnd(String target) {
        TreeMap<String, Stage> result = new TreeMap<String, Stage>();
        for (String stageName : currentStages.keySet()) {
            Stage stage = currentStages.get(stageName);
            if (stage.isEndTarget(target)) {
                result.put(stageName, stage);
                break;
            }
        }
        return result;
    }

    /**
     * Method returns the configured {@link StageSummary}.
     * 
     * @param project
     *            is the project to lookup for stageSummary.
     * @return the {@link StageSummary}.
     */
    @SuppressWarnings("unchecked")
    private StageSummary getStageSummary(Project project) {
        StageSummary stageSummary = null;
        int count = 0;
        Hashtable<String, Object> references = project.getReferences();
        for (Enumeration<String> en = references.keys(); en.hasMoreElements();) {
            Object object = references.get(en.nextElement());
            if (object instanceof StageSummary) {
                count++;
                if (count > 1) {
                    raiseException("Multiple entries of 'hlm:stagesummary' found in "
                            + "stages_config.ant.xml.");
                }
                stageSummary = (StageSummary) object;
            }
        }
        return stageSummary;
    }

    /**
     * Raise a {@link BuildException} with the specified error message.
     * 
     * @param message
     *            is the error message to display.
     */
    private void raiseException(String message) {
        throw new BuildException(message);
    }

    /**
     * Start the given stage as a new build stage.
     * 
     * @param stageName
     *            is the name of the new stage.
     * @param newStage
     *            is the build stage to start as new.
     * @param startTime
     *            is the start time of the given build stage.
     */
    private void startNewStage(String stageName, Stage newStage, Long startTime) {
        if (!currentStages.containsKey(stageName)) {
            this.currentStages.put(stageName, newStage);
            this.currentStagesStartTime.put(stageName, startTime);
            log.debug("New stage [" + stageName + "] started at "
                    + getTimestamp(startTime));
        }
    }

    /**
     * End the current stage.
     * 
     * @param reason
     *            is the reason for build failure if any.
     * @param currTime
     *            is the end time of the current stage.
     */
    private void endCurrentStage(String currentStageName, Stage currentStage,
            String reason, Long currTime) {
        if (currentStage != null) {
            BuildStatusReport report = constructBuildStatusReport(
                    currentStageName, currentStagesStartTime
                            .get(currentStageName), currTime, reason);
            statusReports.add(report);
            displaySummary = true;
            log.debug("Stage [" + currentStageName + "] finished at "
                    + getTimestamp(currTime));
            reset(currentStageName);
        }
    }

    /**
     * Reset the build stage variables to default.
     */
    private void reset(String stageName) {
        this.currentStages.remove(stageName);
        this.currentStagesStartTime.remove(stageName);
        this.completedStages.add(stageName);
    }

    /**
     * Search for the new Stage based on the given build event.
     * 
     * @param event
     *            is the build event fired.
     * @return a map with Stage Name and stage, if the build event marks the
     *         start of a configured Stage.
     */
    private TreeMap<String, Stage> searchNewStage(BuildEvent event) {
        TreeMap<String, Stage> result = new TreeMap<String, Stage>();
        String target = event.getTarget().getName();
        for (String stageName : stages.keySet()) {
            Stage stage = stages.get(stageName);
            if (!completedStages.contains(stageName)
                    && isStartingTarget(target, event.getProject(), stage)) {
                result.put(stageName, stage);
                break;
            }
        }
        return result;
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
                validateStageInformation(key, (Stage)value);
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
     * Generate build summary.
     * 
     */
    private void generateSummary(Project project) {
        if (template != null) {
            try {
                Configuration cfg = new Configuration();
                log.debug("Basedir: " + template.getParentFile());
                cfg.setTemplateLoader(new FileTemplateLoader(template.getParentFile()));
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
                project.log("I/O Error during template conversion: " + e.toString(),
                        Project.MSG_WARN);
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
        templateMap.put("statusReports", new ArrayList<BuildStatusReport>(
                statusReports));
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
     * Get the time duration for the given start and end times in String format.
     * 
     * @param startTime
     *            is the start time.
     * @param endTime
     *            is the end time.
     * @return
     */
    private String getTimeElapsed(Long startTime, Long endTime) {
        long timeElapsed = endTime - startTime;
        return DateUtils.formatElapsedTime(timeElapsed);
    }

    /**
     * Construct an instance of {@link BuildStatusReport} with the given
     * details.
     * 
     * @param phaseName
     *            is the name of the Phase.
     * @param startTime
     *            is the start time of the given Phase
     * @param endTime
     *            is the end time of given phase
     * @param reason
     *            is the cause of failure
     * @return
     */
    private BuildStatusReport constructBuildStatusReport(String phaseName,
            Long startTime, Long endTime, String reason) {
        return new BuildStatusReport(phaseName, getTimestamp(startTime),
                getTimeElapsed(startTime, endTime), reason);
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
}
