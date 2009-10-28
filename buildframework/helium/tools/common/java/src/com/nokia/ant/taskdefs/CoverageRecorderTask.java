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

/* Portion Copyright (c) 2007-2008 Nokia Corporation and/or its subsidiary(-ies). All rights reserved. */

package com.nokia.ant.taskdefs;

import java.util.Hashtable;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.taskdefs.Recorder;

/**
 * Adds a listener, which inherits the Ant Record task, to the current build process that records the
 * output to a XML file.
 */
public class CoverageRecorderTask extends Recorder {

    //////////////////////////////////////////////////////////////////////
    // ATTRIBUTES
    
    /** The list of recorder entries. */
    private static Hashtable recorderEntries = new Hashtable();
    
    /** The name of the file to record to. */
    private String filename;
    /**
     * Whether or not to append. Need Boolean to record an unset state (null).
     */
    private Boolean append;
    /**
     * Whether to start or stop recording. Need Boolean to record an unset
     * state (null).
     */
    private Boolean start;
    /** The level to log at. A level of -1 means not initialized yet. */
    private int loglevel = -1;
    /** Strip task banners if true.  */
    private boolean emacsMode;

    //////////////////////////////////////////////////////////////////////
    // ACCESSOR METHODS

    /**
     * Sets the name of the file to log to, and the name of the recorder
     * entry.
     *
     * @param fname File name of logfile.
     */
    public void setName(String fname) {
        filename = fname;
    }


    /**
     * Sets the action for the associated recorder entry.
     *
     * @param action The action for the entry to take: start or stop.
     */
    public void setAction(ActionChoices action) {
        if (action.getValue().equalsIgnoreCase("start")) {
            start = Boolean.TRUE;
        } else {
            start = Boolean.FALSE;
        }
    }


    /**
     * Whether or not the logger should append to a previous file.
     * @param append if true, append to a previous file.
     */
    public void setAppend(boolean append) {
        this.append = append ? Boolean.TRUE : Boolean.FALSE;
    }


    /**
     * Set emacs mode.
     * @param emacsMode if true use emacs mode
     */
    public void setEmacsMode(boolean emacsMode) {
        this.emacsMode = emacsMode;
    }


    /**
     * Sets the level to which this recorder entry should log to.
     * @param level the level to set.
     * see VerbosityLevelChoices
     */
    public void setLoglevel(VerbosityLevelChoices level) {
        loglevel = level.getLevel();
    }

    //////////////////////////////////////////////////////////////////////
    // CORE / MAIN BODY

    /**
     * The main execution.
     * @throws BuildException on error
     */
    public void execute() {
        if (filename == null) {
            throw new BuildException("No filename specified");
        }

        getProject().log("setting a recorder for name " + filename,
            Project.MSG_DEBUG);
        
        String recordTaskName = this.getTaskName();
        
        // get the recorder entry
        CoverageRecorderEntry recorder = getRecorder(filename, getProject(), recordTaskName);
        // set the values on the recorder
        recorder.setMessageOutputLevel(loglevel);
        recorder.setEmacsMode(emacsMode);
        if (start != null) {
            if (start.booleanValue()) {
                //recorder.reopenFile();
                recorder.setRecordState(start);
            } else {
                recorder.setRecordState(start);
                recorder.cleanup();
            }
        }
    }

    /**
     * Gets the recorder that's associated with the passed in name. If the
     * recorder doesn't exist, then a new one is created.
     * @param name the name of the recoder
     * @param proj the current project
     * @return a recorder
     * @throws BuildException on error
     */
    protected CoverageRecorderEntry getRecorder(String name, Project proj, String recordTaskName)
    {
        Object o = recorderEntries.get(name);
        CoverageRecorderEntry entry;

        if (o == null) {
            // create a recorder entry
            entry = new CoverageRecorderEntry(name, recordTaskName);

            /*if (append == null) {
                entry.openFile(false);
            } else {
                entry.openFile(append.booleanValue());
            }*/
            entry.setProject(proj);
            recorderEntries.put(name, entry);
        } else {
            entry = (CoverageRecorderEntry) o;
        }
        return entry;
    }
}

