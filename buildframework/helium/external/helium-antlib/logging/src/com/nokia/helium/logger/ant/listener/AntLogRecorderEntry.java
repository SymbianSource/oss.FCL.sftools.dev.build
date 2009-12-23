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

import java.io.PrintStream;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildLogger;
import org.apache.tools.ant.DefaultLogger;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.SubBuildListener;
import org.apache.tools.ant.util.StringUtils;
import org.apache.tools.ant.BuildException;

import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Vector;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * This is a class that represents a recorder. This is the listener to the
 * build process.
 *
 * @since Ant 1.4
 */
public class AntLogRecorderEntry implements BuildLogger, SubBuildListener {

    //////////////////////////////////////////////////////////////////////
    // ATTRIBUTES

    /** The name of the file associated with this recorder entry.  */
    private String filename;
    /** The state of the recorder (recorder on or off).  */
    private boolean record = true;
    /** The current verbosity level to record at.  */
    private int loglevel = Project.MSG_INFO;
    /** The output PrintStream to record to.  */
    private PrintStream out;
    /** The start time of the last know target.  */
    private long targetStartTime;
    /** Strip task banners if true.  */
    private boolean emacsMode;
    /** project instance the recorder is associated with */
    private Project project;
    
    private Pattern pattern;
    
    private Vector<String> logRegExps = new Vector<String>();
    
    
    //////////////////////////////////////////////////////////////////////
    // CONSTRUCTORS / INITIALIZERS

    /**
     * @param name The name of this recorder (used as the filename).
     */
    public AntLogRecorderEntry(String name) {
        targetStartTime = System.currentTimeMillis();
        filename = name;
    }

    //////////////////////////////////////////////////////////////////////
    // ACCESSOR METHODS

    /**
     * @return the name of the file the output is sent to.
     */
    public String getFilename() {
        return filename;
    }

    /**
     * Turns off or on this recorder.
     *
     * @param state true for on, false for off, null for no change.
     */
    public void setRecordState(Boolean state) {
        if (state != null) {
            flush();
            record = state.booleanValue();
        }
    }
    
    /**
     * To set the regexp to filter the logging.
     * @param regexp
     */
    public void addRegexp(String regexp) {
        logRegExps.add(regexp);
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
            } else {
                out.println(StringUtils.LINE_SEP + "BUILD FAILED"
                            + StringUtils.LINE_SEP);
                error.printStackTrace(out);
            }
        }
        cleanup();
    }

    /**
     * Cleans up any resources held by this recorder entry at the end
     * of a subbuild if it has been created for the subbuild's project
     * instance.
     *
     * @param event the buildFinished event
     *
     * @since Ant 1.6.2
     */
    public void subBuildFinished(BuildEvent event) {
        if (event.getProject() == project) {
            cleanup();
        }
    }

    /**
     * Empty implementation to satisfy the BuildListener interface.
     *
     * @param event the buildStarted event
     *
     * @since Ant 1.6.2
     */
    public void subBuildStarted(BuildEvent event) {
    }

    /**
     * @see org.apache.tools.ant.BuildListener#targetStarted(BuildEvent)
     */
    /** {@inheritDoc}. */
    public void targetStarted(BuildEvent event) {
        log(">> TARGET STARTED -- " + event.getTarget(), Project.MSG_DEBUG);
        log(StringUtils.LINE_SEP + event.getTarget().getName() + ":",
            Project.MSG_INFO);
        targetStartTime = System.currentTimeMillis();
    }

    /**
     * @see org.apache.tools.ant.BuildListener#targetFinished(BuildEvent)
     */
    /** {@inheritDoc}. */
    public void targetFinished(BuildEvent event) {
        log("<< TARGET FINISHED -- " + event.getTarget(), Project.MSG_DEBUG);

        String time = formatTime(System.currentTimeMillis() - targetStartTime);

        log(event.getTarget() + ":  duration " + time, Project.MSG_VERBOSE);
        flush();
    }

    /**
     * @see org.apache.tools.ant.BuildListener#taskStarted(BuildEvent)
     */
    /** {@inheritDoc}. */
    public void taskStarted(BuildEvent event) {
        log(">>> TASK STARTED -- " + event.getTask(), Project.MSG_DEBUG);
    }

    /**
     * @see org.apache.tools.ant.BuildListener#taskFinished(BuildEvent)
     */
    /** {@inheritDoc}. */
    public void taskFinished(BuildEvent event) {
        log("<<< TASK FINISHED -- " + event.getTask(), Project.MSG_DEBUG);
        flush();
    }

    /**
     * @see org.apache.tools.ant.BuildListener#messageLogged(BuildEvent)
     */
    /** {@inheritDoc}. */
    public void messageLogged(BuildEvent event) {
        log("--- MESSAGE LOGGED", Project.MSG_DEBUG);

        StringBuffer buf = new StringBuffer();

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
    
    
    /**
     * To replace regExp matching with ****.
     * @param message
     * @return
     */
    private String filterMessage(String message) {
        for (String regExp : logRegExps) {
            pattern = Pattern.compile(regExp);
            if (pattern != null) {
                Matcher match = pattern.matcher(message);
                message = match.replaceAll("********");
            }
        }
        return message;
    }


    /**
     * The thing that actually sends the information to the output.
     *
     * @param mesg The message to log.
     * @param level The verbosity level of the message.
     */
    private void log(String mesg, int level) {
        if (record && (level <= loglevel) && out != null) {
            out.println(mesg);
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
            return Long.toString(minutes) + " minute"
                 + (minutes == 1 ? " " : "s ")
                 + Long.toString(seconds % 60) + " second"
                 + (seconds % 60 == 1 ? "" : "s");
        } else {
            return Long.toString(seconds) + " second"
                 + (seconds % 60 == 1 ? "" : "s");
        }
        // CheckStyle:MagicNumber ON
    }

    /**
     * Set the project associated with this recorder entry.
     *
     * @param project the project instance
     *
     * @since 1.6.2
     */
    public void setProject(Project project) {
        this.project = project;
        if (project != null) {
            project.addBuildListener(this);
        }
    }

    /**
     * @since 1.6.2
     */
    public void cleanup() {
        closeFile();
        if (project != null) {
            project.removeBuildListener(this);
        }
        project = null;
    }

    /**
     * Closes the file associated with this recorder.
     * Used by Recorder.
     * @since 1.6.3
     */
    public void closeFile() {
        if (out != null) {
            out.close();
            out = null;
        }
    }
    
    /**
     * Initially opens the file associated with this recorder.
     * Used by Recorder.
     * @param append Indicates if output must be appended to the logfile or that
     * the logfile should be overwritten.
     * @throws BuildException
     * @since 1.6.3
     */
    public void openFile(boolean append) {
        openFileImpl(append);
    }
    
    /**
     * Re-opens the file associated with this recorder.
     * Used by Recorder.
     * @throws BuildException
     * @since 1.6.3
     */
    public void reopenFile() {
        openFileImpl(true);
    }
    
    private void openFileImpl(boolean append) {
        if (out == null) {
            try {
                out = new PrintStream(new FileOutputStream(filename, append));
            } catch (IOException ioe) {
                throw new BuildException("Problems opening file using a "
                                         + "recorder entry", ioe);
            }
        }
    }
    
    /**
     * To add user message into log file.
     * @param message
     */
    public void addLogMessage(String message) {
        out.println(StringUtils.LINE_SEP + message);
        
    }
    

}
