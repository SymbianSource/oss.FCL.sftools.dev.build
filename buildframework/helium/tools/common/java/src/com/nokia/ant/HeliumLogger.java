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
import java.io.PrintStream;
import java.text.SimpleDateFormat;
import java.util.Calendar;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.DefaultLogger;
import org.apache.tools.ant.Project;

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

    private Project project;
    private Log log = LogFactory.getLog(HeliumLogger.class);


    /**
     * Ant call this function when bjuild start.
     */
    public void buildStarted(BuildEvent event) {
        project = event.getProject();
        super.buildStarted(event);
    }

    /**
     * Triggered when a target starts.
     */
    public void targetStarted(BuildEvent event) {
        /** The "if" condition to test on execution. */
        String ifCondition = "";
        /** The "unless" condition to test on execution. */
        String unlessCondition = "";
        String targetName = event.getTarget().getName();
        logTargetEvent(targetName, "start");

        /**get the values needed from the event **/
        ifCondition = event.getTarget().getIf();
        unlessCondition = event.getTarget().getUnless();
        project = event.getProject();

        super.targetStarted(event);

        /**if the target is not going to execute (due to 'if' or 'unless' conditions) 
        print a message telling the user why it is not going to execute**/
        if (!testIfCondition(ifCondition) && ifCondition != null) {
            project.log("Skipped because property '"
                + project.replaceProperties(ifCondition)
                + "' not set.", Project.MSG_INFO);
        } else if (!testUnlessCondition(unlessCondition) && unlessCondition != null) {
            project.log("Skipped because property '"
                + project.replaceProperties(unlessCondition)
                + "' set.", Project.MSG_INFO);
        }
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
    }

    /**
     * Triggered when the build finishes.
     */
    public void buildFinished(BuildEvent event) {
        // re-enabling output of messages at the end of the build
        stopLogToConsole = false;
        cleanup();
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
    
    /**
     * Tests whether or not the "if" condition is satisfied.
     *
     * @return whether or not the "if" condition is satisfied. If no
     *         condition (or an empty condition) has been set,
     *         <code>true</code> is returned.
     */
    private boolean testIfCondition(String ifCondition) {
        if ("".equals(ifCondition)) {
            return true;
        }

        String test = project.replaceProperties(ifCondition);
        return project.getProperty(test) != null;
    }

    /**
     * Tests whether or not the "unless" condition is satisfied.
     *
     * @return whether or not the "unless" condition is satisfied. If no
     *         condition (or an empty condition) has been set,
     *         <code>true</code> is returned.
     */
    private boolean testUnlessCondition(String unlessCondition) {
        if ("".equals(unlessCondition)) {
            return true;
        }
        String test = project.replaceProperties(unlessCondition);
        return project.getProperty(test) == null;
    }
}
