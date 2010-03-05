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
package com.nokia.helium.core.ant.listener;

import java.io.DataOutputStream;
import java.io.FileOutputStream;
import java.io.File;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.concurrent.TimeUnit;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.Project;

/**
 * <code>TargetTimesGeneratorListener</code> is a build listener used to
 * generate a comma separated value file of targets and the total time the
 * targets took to run.
 * 
 * Note: To generate a target times csv file make an entry of this listener in
 * the hlm.bat file.
 * 
 */
public class TargetTimesLogGeneratorListener implements BuildListener {

    private String targetTimesLogCsv;
    private List<String> targetTimesTable;

    private Project project;
    private Date targetStartTime;
    private boolean isInitialized;

    /**
     * Method initializes the listener on build start.
     * 
     * @param event
     *            is the build start event.
     */
    public void buildStarted(BuildEvent event) {

    }

    /**
     * Initialize the listener.
     * 
     * @param project
     *            is the current ant project running.
     */
    private void initialize(Project project) {
        this.project = project;
        targetTimesLogCsv = project.getProperty("target.times.log.file");
        targetTimesTable = new ArrayList<String>();
        isInitialized = true;
        if (targetTimesLogCsv == null) {
            this.project.log("TargetTimesLog csv file will not be generated. "
                    + "Reason: Property 'target.times.log.file' not set");
        }
    }

    /**
     * Method generates the comma separated value file of targets and their
     * times.
     * 
     * @param event
     *            is the build finish event.
     */
    public void buildFinished(BuildEvent event) {
        if (targetTimesLogCsv != null) {
            DataOutputStream timesLogOut = null;
            try {
                File dir = new File(targetTimesLogCsv).getParentFile();
                dir.mkdirs();
                if (dir.exists())
                {
                    FileOutputStream timesLogFileStream = new FileOutputStream(
                            targetTimesLogCsv, true);
                    timesLogOut = new DataOutputStream(timesLogFileStream);
                    // Display (sorted) hashtable.
                    for (String s : targetTimesTable)
                        timesLogOut.writeBytes(s + "\n");
                    timesLogOut.close();
                }
            } catch (Exception ex) {
                // We are Ignoring the errors as no need to fail the build.
                project.log("Exception has occurred", ex, Project.MSG_WARN);
                ex.printStackTrace();
            }
        }
    }

    /**
     * Method records the target start time.
     * 
     * @param event
     *            is the target start event.
     */
    public void targetStarted(BuildEvent event) {
        if (!isInitialized) {
            initialize(event.getProject());
        }
        targetStartTime = new Date();
    }

    /**
     * Method records the total time of the target.
     * 
     * @param event
     *            is the target finish event.
     */
    public void targetFinished(BuildEvent event) {
        String targetName = event.getTarget().getName();
        long time = getTargetRunTime();
        targetTimesTable.add(targetName + "," + time);
    }

    /**
     * Returns the total time the target run.
     * 
     * @return total target run time in seconds.
     */
    private long getTargetRunTime() {
        Date targetFinishTime = new Date();
        long targetLengthMSecs = targetFinishTime.getTime()
                - targetStartTime.getTime();
        return TimeUnit.MILLISECONDS.toSeconds(targetLengthMSecs);
    }

    /**
     * {@inheritDoc}
     */
    public void messageLogged(BuildEvent event) {
        // ignore
    }

    /**
     * {@inheritDoc}
     */
    public void taskFinished(BuildEvent event) {
        // ignore
    }

    /**
     * {@inheritDoc}
     */
    public void taskStarted(BuildEvent event) {
        // ignore
    }
}
