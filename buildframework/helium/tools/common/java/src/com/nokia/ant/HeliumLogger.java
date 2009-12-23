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

package com.nokia.ant;

import java.io.File;
import java.io.FileOutputStream;
import java.io.DataOutputStream;
import java.io.PrintStream;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.concurrent.TimeUnit;
import java.util.Hashtable;
import java.util.ArrayList;
import java.util.Calendar;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.Project;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.tools.ant.DefaultLogger;

/**
 * Logger class that can connect to Ant and log information regarding to build
 * times, number of errors and such. Data is sent to Diamonds server, where it
 * is processed further.
 * 
 * This class is listening all build related events. It catches the build
 * start-finish, target start-finish events of Ant and gather build start-end
 * time, errors/warnings and store in BuildData class. Stored data will be
 * exported to XML and uploaded to Diamonds server after each specific target.
 * For example after target "create-bom" this class will upload all BOM data to
 * Diamonds.
 * 
 * 
 */
public class HeliumLogger extends DefaultLogger {

    private static boolean stopLogToConsole;

    private Date endOfPreviousTarget;

    private Project project;

    private Log log = LogFactory.getLog(HeliumLogger.class);

    private boolean isInitialized;

    private String directory;

    private SimpleDateFormat timeFormat;

    private Date buildStartTime;

    private Date buildEndTime;

    private Date targetStartTime;

    private ArrayList<String> targetTable;

    private Hashtable tempStartTime;

    private StringBuffer allStages;

    /**
     * Ant call this function when bjuild start.
     */
    public void buildStarted(BuildEvent event) {
        project = event.getProject();

        // Record build start time
        endOfPreviousTarget = new Date();
        buildStartTime = new Date();
        endOfPreviousTarget = new Date();

        targetTable = new ArrayList<String>();
        tempStartTime = new Hashtable();

        // For Stage start time
        allStages = new StringBuffer("\t<stages>");

        super.buildStarted(event);
    }

    /**
     * Triggered when a target starts.
     */
    public void targetStarted(BuildEvent event) {
        String targetName = event.getTarget().getName();
        targetStartTime = new Date();

        logTargetEvent(targetName, "start");

        if (!isInitialized) {
            initializeLogger();
        }
        if (isInitialized) {
            // Record the target start time
            tempStartTime.put(targetName, new Date());
        }
        super.targetStarted(event);
    }

    private void initializeLogger() {
        directory = project.getProperty("build.log.dir");
        isInitialized = true;
    }

    /**
     * Log the start or end of the build as a event.
     * 
     * @param targetName
     *            The name of the current target.
     * @param event
     *            A string description of the event.
     */
    private void logTargetEvent(String targetName, String event) {
        String logTargetProperty = project.getProperty("log.target");
        if ((logTargetProperty != null) && (logTargetProperty.equals("yes"))) {
            log.info("Target #### " + targetName + " ####: " + event);
        }
    }

    /**
     * Triggered when a target finishes.
     */
    public void targetFinished(BuildEvent event) {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        String time = sdf.format(Calendar.getInstance().getTime());
        
        String targetName = time + "," + event.getTarget().getName();

        logTargetEvent(targetName, "finish");
        logTargetTime(targetName);
    }

    private void logTargetTime(String targetName) {
        Date targetFinishTime = new Date();
        long targetLengthMSecs = targetFinishTime.getTime()
                - targetStartTime.getTime();
        Long outputSecs = TimeUnit.MILLISECONDS.toSeconds(targetLengthMSecs);
        targetTable.add(targetName + "," + outputSecs.toString());
    }

    /**
     * Triggered when the build finishes.
     */
    public void buildFinished(BuildEvent event) {
        if (isInitialized) {
            if (directory != null && new File(directory).exists()) {
                try {
                    // Log target times to file
                    String timesLogFileName = directory + File.separator + project.getProperty("build.id") + "_targetTimesLog.csv";
                    File timesLogFile = new File(timesLogFileName);

                    FileOutputStream timesLogFileStream = new FileOutputStream(
                            timesLogFileName, true);
                    DataOutputStream timesLogOut = new DataOutputStream(
                            timesLogFileStream);
                    // Display (sorted) hashtable.
                    for (String s : targetTable)
                        timesLogOut.writeBytes(s + "\n");
                    timesLogOut.close();
                } catch (Exception ex) {
                    // We are Ignoring the errors as no need to fail the build.
                    log.fatal("Exception has occurred", ex);
                    ex.printStackTrace();
                }
            }
            cleanup();
        }
        super.buildFinished(event);
    }

    /**
     * See if build needs a final cleanup target to be called.
     */
    private void cleanup() {
        String loggingoutputfile = project.getProperty("logging.output.file");
        if (loggingoutputfile != null) {
            File f = new File(loggingoutputfile);
            if (f.exists()) {
                f.delete();
            }
        }

        if ((project.getProperty("call.cleanup") != null)
                && (project.getProperty("call.cleanup").equals("yes"))) {
            project.executeTarget("cleanup-all");
        }
    }

    /**
     * Get log to console status
     */
    public static boolean getStopLogToConsole() {
        return stopLogToConsole;
    }

    /**
     * Set log to console status
     */
    public static void setStopLogToConsole(boolean stop) {
        stopLogToConsole = stop;
    }

    /**
     * {@inheritDoc}
     */
    protected void printMessage(final String message, final PrintStream stream,
            final int priority) {
        if (!stopLogToConsole) {
            stream.println(message);
        }
    }
}
