/*
 *  Licensed to the Apache Software Foundation (ASF) under one or more
 *  contributor license agreements.  See the NOTICE file distributed with
 *  this work for additional information regarding copyright ownership.
 *  The ASF licenses this file to You under the Apache License, Version 2.0
 *  (the "License"); you may not use this file except in compliance with
 *  the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
/* * Portion Copyright (c) 2007-2008 Nokia Corporation and/or its subsidiary(-ies). All rights reserved.*/

package com.nokia.helium.logger.ant.listener;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.DefaultLogger;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.util.StringUtils;

/**
 * This is a class that represents a recorder. This is the listener to the build process.
 * 
 * @since Ant 1.4
 */
public class RecorderEntry implements BuildEventHandler, TargetEventHandler, TaskEventHandler,
    MessageEventHandler, SubBuildEventHandler {

    /** The name of the file associated with this recorder entry. */
    private File filename;
    /** The state of the recorder (recorder on or off). */
    private boolean record = true;
    /** The current verbosity level to record at. */
    private int loglevel = Project.MSG_INFO;
    /** The output PrintStream to record to. */
    private PrintStream out;
    /** The start time of the last know target. */
    private long targetStartTime;
    /** Strip task banners if true. */
    private boolean emacsMode;

    // defines if this recorder entry should notify the stage logger about project to exclude from recording.
    private boolean excludeSubProject;
    private List<Project> excludedProjects = new ArrayList<Project>();
    private List<Project> includedProjects = new ArrayList<Project>();

    private List<Pattern> logRegExps = new ArrayList<Pattern>();

    /**
     * Create a RecorderEntry using a filename. 
     * @param name the filename of the log file.
     */
    public RecorderEntry(File name) {
        targetStartTime = System.currentTimeMillis();
        filename = name;
    }

    /**
     * New RecorderEntry using a filename and allow sub project exclusion.
     * @param name the log filename
     * @param excludeSubProject If true this recorder entry will notify 
     *                          the stage logger about projects to exclude 
     *                          from recording. If false, then only non-excluded
     *                          project message will be handled.
     */
    public RecorderEntry(File name, boolean excludeSubProject) {
        targetStartTime = System.currentTimeMillis();
        filename = name;
        this.excludeSubProject = true;
    }

    /**
     * @return the name of the file the output is sent to.
     */
    public File getFilename() {
        return filename;
    }

    /**
     * Turns off or on this recorder.
     * 
     * @param state true for on, false for off, null for no change.
     */
    public void setRecordState(boolean state) {
        flush();
        record = state;
    }

    /**
     * Get the current state of the recorder
     * 
     * @param state
     */
    public boolean getRecordState() {
        return record;
    }

    /**
     * To set the regexp to filter the logging.
     * 
     * @param regexp
     */
    public void addRegexp(Pattern pattern) {
        logRegExps.add(pattern);
    }

    /**
     * To clear all regexp set.
     */
    public void resetRegExp() {
        logRegExps.clear();
    }

    /**
     * @see org.apache.tools.ant.BuildListener#buildStarted(BuildEvent)
     */
    /** {@inheritDoc}. */
    public void buildStarted(BuildEvent event) {
        log("> BUILD STARTED", Project.MSG_DEBUG);
    }

    /**
     * @see org.apache.tools.ant.BuildListener#buildFinished(BuildEvent)
     */
    /** {@inheritDoc}. */
    public void buildFinished(BuildEvent event) {        
        log("< BUILD FINISHED", Project.MSG_DEBUG);

        if (record && out != null) {
            Throwable error = event.getException();

            if (error == null) {
                out.println(StringUtils.LINE_SEP + "BUILD SUCCESSFUL");
            }
            else {
                out.println(StringUtils.LINE_SEP + "BUILD FAILED" + StringUtils.LINE_SEP);
                error.printStackTrace(out);
            }
        }
        cleanup();
    }

    /**
     * Cleans up any resources held by this recorder entry at the end of a subbuild if it has been
     * created for the subbuild's project instance.
     * 
     * @param event the buildFinished event
     * 
     * @since Ant 1.6.2
     */
    public void subBuildFinished(BuildEvent event) {
        log("< SUBBUILD FINISHED", Project.MSG_DEBUG);
        if (excludeSubProject && CommonListener.getCommonListener() != null) {
            AntLoggingHandler antLogger = CommonListener.getCommonListener().getHandler(AntLoggingHandler.class);
            if (antLogger != null) {
                antLogger.removeRecordExclusion(event.getProject());
            }
        }
        excludedProjects.remove(event.getProject());
        includedProjects.remove(event.getProject());
    }

    /**
     * Empty implementation to satisfy the BuildListener interface.
     * 
     * @param event the buildStarted event
     * 
     * @since Ant 1.6.2
     */
    public void subBuildStarted(BuildEvent event) {
        log("< SUBBUILD STARTED", Project.MSG_DEBUG);
        includedProjects.add(event.getProject());
        if (excludeSubProject && CommonListener.getCommonListener() != null) {
            AntLoggingHandler antLogger = CommonListener.getCommonListener().getHandler(AntLoggingHandler.class);
            if (antLogger != null) {
                antLogger.addRecordExclusion(event.getProject());
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    public void targetStarted(BuildEvent event) {
        if ((!excludeSubProject && !excludedProjects.contains(event.getTarget().getProject())) ||
                (this.excludeSubProject && this.includedProjects.contains(event.getTarget().getProject()))) {
            log(">> TARGET STARTED -- " + event.getTarget(), Project.MSG_DEBUG);
            log(StringUtils.LINE_SEP + event.getTarget().getName() + ":", Project.MSG_INFO);
        }
        targetStartTime = System.currentTimeMillis();
    }

    /**
     * {@inheritDoc}
     */
    public void targetFinished(BuildEvent event) {
        if ((!excludeSubProject && !excludedProjects.contains(event.getTarget().getProject())) || 
            (this.excludeSubProject && this.includedProjects.contains(event.getTarget().getProject()))) {
            log("<< TARGET FINISHED -- " + event.getTarget(), Project.MSG_DEBUG);

            String time = formatTime(System.currentTimeMillis() - targetStartTime);

            log(event.getTarget() + ":  duration " + time, Project.MSG_VERBOSE);
            flush();
        }
    }

    /**
     * @see org.apache.tools.ant.BuildListener#taskStarted(BuildEvent)
     */
    /** {@inheritDoc}. */
    public void taskStarted(BuildEvent event) {
        if ((!excludeSubProject && !excludedProjects.contains(event.getTask().getProject())) ||
            (this.excludeSubProject && this.includedProjects.contains(event.getTask().getProject()))) {
            log(">>> TASK STARTED -- " + event.getTask(), Project.MSG_DEBUG);
        }
    }

    /**
     * @see org.apache.tools.ant.BuildListener#taskFinished(BuildEvent)
     */
    /** {@inheritDoc}. */
    public void taskFinished(BuildEvent event) {
        if ((!excludeSubProject && !excludedProjects.contains(event.getTask().getProject())) ||
            (this.excludeSubProject && this.includedProjects.contains(event.getTask().getProject()))) {
            log("<<< TASK FINISHED -- " + event.getTask(), Project.MSG_DEBUG);
            flush();
        }
    }

    /**
     * @see org.apache.tools.ant.BuildListener#messageLogged(BuildEvent)
     */
    /** {@inheritDoc}. */
    public void messageLogged(BuildEvent event) {
        Project project = event.getProject();
        if (project == null && event.getTask() != null) {
            project = event.getTask().getProject();
        }
        if (project == null && event.getTarget() != null) {
            project = event.getTarget().getProject();
        }
        if ((!excludeSubProject && !excludedProjects.contains(project))
            || (excludeSubProject && includedProjects.contains(project))) {
            log("--- MESSAGE LOGGED", Project.MSG_DEBUG);

            StringBuilder buf = new StringBuilder();

            if (event.getTask() != null) {
                String name = event.getTask().getTaskName();

                if (!emacsMode) {
                    String label = "[" + name + "] ";
                    int size = DefaultLogger.LEFT_COLUMN_SIZE - label.length();

                    for (int i = 0; i < size; i++) {
                        buf.append(" ");
                    }
                    buf.append(label);
                }
            }
            String messgeToUpdate = filterMessage(event.getMessage());
            buf.append(messgeToUpdate);
            log(buf.toString(), event.getPriority());
        }
    }

    /**
     * To replace regExp matching with ****.
     * 
     * @param message
     * @return
     */
    private String filterMessage(String message) {
        for (Pattern pattern : logRegExps) {
            Matcher match = pattern.matcher(message);
            message = match.replaceAll("********");
        }
        return message;
    }

    /**
     * The thing that actually sends the information to the output.
     * 
     * @param mesg The message to log.
     * @param level The verbosity level of the message.
     */
    private void log(String msg, int level) {
        if (record && (level <= loglevel) && out != null) {
            out.println(msg);
        }
    }

    private void flush() {
        if (record && out != null) {
            out.flush();
        }
    }

    /**
     * @see BuildLogger#setMessageOutputLevel(int)
     */
    /** {@inheritDoc}. */
    public void setMessageOutputLevel(int level) {
        if (level >= Project.MSG_ERR && level <= Project.MSG_DEBUG) {
            loglevel = level;
        }
    }

    /**
     * @see BuildLogger#setOutputPrintStream(PrintStream)
     */
    /** {@inheritDoc}. */
    public void setOutputPrintStream(PrintStream output) {
        closeFile();
        out = output;
    }

    /**
     * @see BuildLogger#setEmacsMode(boolean)
     */
    /** {@inheritDoc}. */
    public void setEmacsMode(boolean emacsMode) {
        this.emacsMode = emacsMode;
    }

    /**
     * @see BuildLogger#setErrorPrintStream(PrintStream)
     */
    /** {@inheritDoc}. */
    public void setErrorPrintStream(PrintStream err) {
        setOutputPrintStream(err);
    }

    private static String formatTime(long millis) {
        // CheckStyle:MagicNumber OFF
        long seconds = millis / 1000;
        long minutes = seconds / 60;

        if (minutes > 0) {
            return Long.toString(minutes) + " minute" + (minutes == 1 ? " " : "s ")
                + Long.toString(seconds % 60) + " second" + (seconds % 60 == 1 ? "" : "s");
        }
        else {
            return Long.toString(seconds) + " second" + (seconds % 60 == 1 ? "" : "s");
        }
        // CheckStyle:MagicNumber ON
    }

    /**
     * @since 1.6.2
     */
    public void cleanup() {
        closeFile();
    }

    /**
     * Closes the file associated with this recorder. Used by Recorder.
     * 
     * @since 1.6.3
     */
    public void closeFile() {
        if (out != null) {
            out.close();
            out = null;
        }
    }

    /**
     * Initially opens the file associated with this recorder. Used by Recorder.
     * 
     * @param append Indicates if output must be appended to the logfile or that the logfile should
     *        be overwritten.
     * @throws BuildException
     * @since 1.6.3
     */
    public void openFile(boolean append) {
        openFileImpl(append);
    }

    /**
     * Re-opens the file associated with this recorder. Used by Recorder.
     * 
     * @throws BuildException
     * @since 1.6.3
     */
    public void reopenFile() {
        openFileImpl(true);
    }

    private void openFileImpl(boolean append) {
        if (out == null) {
            try {
                if (!filename.getParentFile().exists()) {
                    filename.getParentFile().mkdirs();
                }
                out = new PrintStream(new FileOutputStream(filename, append));
            }
            catch (IOException ioe) {
                throw new BuildException("Problems opening file using a " + "recorder entry: "
                    + ioe.getMessage(), ioe);
            }
        }
    }

    /**
     * To add user message into log file.
     * 
     * @param message
     */
    public void addLogMessage(String message) {
        if (out != null) {
            out.println(StringUtils.LINE_SEP + message);
        }
    }

    /**
     * 
     * @param excludedProjects
     */
    public void setExcludedProject(List<Project> excludedProjects) {
        this.excludedProjects = new ArrayList<Project>(excludedProjects);
    }

    /**
     * Defines the root project a recorder entry should record 
     * from. (this one and sub-project). List will be cleared
     * if the project is null. 
     * @param project
     */
    public void setRecorderProject(Project project) {
        if (project != null) {
            this.includedProjects.add(project);
        } else {
            this.includedProjects.clear();
        }
    }
}
