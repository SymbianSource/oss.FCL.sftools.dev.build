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

import java.io.*;
import org.apache.tools.ant.util.DOMElementWriter;
import org.apache.tools.ant.util.DateUtils;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.apache.tools.ant.*;
import java.util.*;

/**
 * This is a class that represents a XML recorder. This is the listener to the
 * build process.
 *
 */
public class CoverageRecorderEntry implements BuildLogger, SubBuildListener {

    //////////////////////////////////////////////////////////////////////
    // ATTRIBUTES
    
    /** XML element name for a build. */
    private static final String BUILD_TAG = "build";
    /** XML element name for a target. */
    private static final String TARGET_TAG = "target";
    /** XML element name for a task. */
    private static final String TASK_TAG = "task";
    /** XML attribute name for a name. */
    private static final String NAME_ATTR = "name";
    /** XML attribute name for a time. */
    private static final String TIME_ATTR = "time";
    /** XML attribute name for a file location. */
    private static final String LOCATION_ATTR = "location";
    
    /** DocumentBuilder to use when creating the document to start with. */
    private static DocumentBuilder builder = getDocumentBuilder();
    
    private String recordTaskName;
    
    /** The name of the file associated with this recorder entry.  */
    private String filename;
    /** The state of the recorder (recorder on or off).  */
    private boolean record = true;
    /** The current verbosity level to record at.  */
    private int loglevel = Project.MSG_INFO;
    /** The output PrintStream to record to.  */
    private PrintStream outStream;
    /** The start time of the last know target.  */
    private long targetStartTime;
    /** Strip task banners if true.  */
    private boolean emacsMode;
    /** project instance the recorder is associated with */
    private Project project;

    /** The complete log document for this build. */
    private Document doc = builder.newDocument();
    /** Mapping for when tasks started (Task to TimedElement). */
    private Hashtable tasks = new Hashtable();
    /** Mapping for when targets started (Task to TimedElement). */
    private Hashtable targets = new Hashtable();
    /**
     * Mapping of threads to stacks of elements
     * (Thread to Stack of TimedElement).
     */
    private Hashtable threadStacks = new Hashtable();
    /**
     * When the build started.
     */
    private TimedElement buildElement;
    
    //////////////////////////////////////////////////////////////////////
    // CONSTRUCTORS / INITIALIZERS

    /**
     * @param name The name of this recorder (used as the filename).
     */
    protected CoverageRecorderEntry(String name, String recordTaskName) {
        filename = name;
        this.recordTaskName = recordTaskName;
        startBuild();
    }
    
    /**
     * Returns a default DocumentBuilder instance or throws an
     * ExceptionInInitializerError if it can't be created.
     *
     * @return a default DocumentBuilder instance.
     */
    protected static DocumentBuilder getDocumentBuilder() {
        try {
            return DocumentBuilderFactory.newInstance().newDocumentBuilder();
        } catch (Exception exc) {
            throw new ExceptionInInitializerError(exc.getMessage());
        }
    }
    
    /** Utility class representing the time an element started. */
    protected static class TimedElement {
        /**
         * Start time in milliseconds
         * (as returned by <code>System.currentTimeMillis()</code>).
         */
        private long startTime;
        /** Element created at the start time. */
        private Element element;
        public String toString() {
            return element.getTagName() + ":" + element.getAttribute("name");
        }
    }
    
    /**
     * Returns the stack of timed elements for the current thread.
     * @return the stack of timed elements for the current thread
     */
    protected Stack getStack() {
        Stack threadStack = (Stack) threadStacks.get(Thread.currentThread());
        if (threadStack == null) {
            threadStack = new Stack();
            threadStacks.put(Thread.currentThread(), threadStack);
        }
        /* For debugging purposes uncomment:
        org.w3c.dom.Comment s = doc.createComment("stack=" + threadStack);
        buildElement.element.appendChild(s);
         */
        return threadStack;
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
            record = state.booleanValue();
        }
    }

    /**
     * @see org.apache.tools.ant.BuildListener#buildStarted(BuildEvent)
     */
    /** {@inheritDoc}. */
    public void buildStarted(BuildEvent event) {
        
    }

    /**
     * @see org.apache.tools.ant.BuildListener#buildFinished(BuildEvent)
     */
    /** {@inheritDoc}. */
    public void buildFinished(BuildEvent event) {
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
        Target target = event.getTarget();
        TimedElement targetElement = new TimedElement();
        targetElement.startTime = System.currentTimeMillis();
        targetElement.element = doc.createElement(TARGET_TAG);
        targetElement.element.setAttribute(NAME_ATTR, target.getName());
        targets.put(target, targetElement);
        getStack().push(targetElement);
    }

    /**
     * @see org.apache.tools.ant.BuildListener#targetFinished(BuildEvent)
     */
    /** {@inheritDoc}. */
    public void targetFinished(BuildEvent event) {
        Target target = event.getTarget();
        TimedElement targetElement = (TimedElement) targets.get(target);
        if (targetElement != null) {
            long totalTime
                    = System.currentTimeMillis() - targetElement.startTime;
            targetElement.element.setAttribute(TIME_ATTR,
                    DateUtils.formatElapsedTime(totalTime));

            TimedElement parentElement = null;
            Stack threadStack = getStack();
            if (!threadStack.empty()) {
                TimedElement poppedStack = (TimedElement) threadStack.pop();
//                if (poppedStack != targetElement) {
//                    throw new RuntimeException("Mismatch - popped element = "
//                            + poppedStack
//                            + " finished target element = "
//                            + targetElement);
//                }
                if (!threadStack.empty()) {
                    parentElement = (TimedElement) threadStack.peek();
                }
            }
            if (parentElement == null) {
                buildElement.element.appendChild(targetElement.element);
            } else {
                parentElement.element.appendChild(targetElement.element);
            }
        }
        targets.remove(target);
    }

    /**
     * @see org.apache.tools.ant.BuildListener#taskStarted(BuildEvent)
     */
    /** {@inheritDoc}. */
    public void taskStarted(BuildEvent event) {
        TimedElement taskElement = new TimedElement();
        taskElement.startTime = System.currentTimeMillis();
        taskElement.element = doc.createElement(TASK_TAG);

        Task task = event.getTask();
        String name = event.getTask().getTaskName();
        if (name == null) {
            name = "";
        }
        taskElement.element.setAttribute(NAME_ATTR, name);
        taskElement.element.setAttribute(LOCATION_ATTR,
                event.getTask().getLocation().toString());
        tasks.put(task, taskElement);
        getStack().push(taskElement);
    }

    /**
     * @see org.apache.tools.ant.BuildListener#taskFinished(BuildEvent)
     */
    /** {@inheritDoc}. */
    public void taskFinished(BuildEvent event) {
        
//        if (event.getTask().getTaskName() != recordTaskName) {
            Task task = event.getTask();
            TimedElement taskElement = (TimedElement) tasks.get(task);
            if (taskElement != null) {
                long totalTime = System.currentTimeMillis() - taskElement.startTime;
                taskElement.element.setAttribute(TIME_ATTR,
                        DateUtils.formatElapsedTime(totalTime));
                Target target = task.getOwningTarget();
                TimedElement targetElement = null;
                if (target != null) {
                    targetElement = (TimedElement) targets.get(target);
                }
                if (targetElement == null) {
                    buildElement.element.appendChild(taskElement.element);
                } else {
                    targetElement.element.appendChild(taskElement.element);
                }
                Stack threadStack = getStack();
                if (!threadStack.empty()) {
                    TimedElement poppedStack = (TimedElement) threadStack.pop();
//                    if (poppedStack != taskElement) {
//                        throw new RuntimeException("Mismatch - popped element = "
//                                + poppedStack + " finished task element = "
//                                + taskElement);
//                    }
                }
                tasks.remove(task);
//            } else {
//                throw new RuntimeException("Unknown task " + task + " not in " + tasks);
//            }
        }
    }
    
    /**
     * Get the TimedElement associated with a task.
     *
     * Where the task is not found directly, search for unknown elements which
     * may be hiding the real task
     */
    protected TimedElement getTaskElement(Task task) {
        TimedElement element = (TimedElement) tasks.get(task);
        if (element != null) {
            return element;
        }

        for (Enumeration e = tasks.keys(); e.hasMoreElements();) {
            Task key = (Task) e.nextElement();
            if (key instanceof UnknownElement) {
                if (((UnknownElement) key).getTask() == task) {
                    return (TimedElement) tasks.get(key);
                }
            }
        }
        return null;
    }
    
    /**
     * @see org.apache.tools.ant.BuildListener#messageLogged(BuildEvent)
     */
    /** {@inheritDoc}. */
    public void messageLogged(BuildEvent event) {
        
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
        outStream = output;
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
    void closeFile() {
        finishBuild();
        Writer out = null;
        try {
            // specify output in UTF8 otherwise accented characters will blow
            // up everything
            OutputStream stream = outStream;
            if (stream == null) {
                stream = new FileOutputStream(filename);
            }
            out = new OutputStreamWriter(stream, "UTF8");
            out.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
            (new DOMElementWriter()).write(buildElement.element, out, 0, "\t");
            out.flush();
        } catch (IOException exc) {
            throw new BuildException("Unable to write log file " + exc.getMessage(), exc);
        } finally {
            if (out != null) {
                try {
                    out.close();
                } catch (IOException e) {
                    e = null; // ignore
                }
            }
        }
        buildElement = null;
    }
    
    void startBuild() {
        buildElement = new TimedElement();
        buildElement.startTime = System.currentTimeMillis();
        buildElement.element = doc.createElement(BUILD_TAG);
    }
    
    void finishBuild() {
        long totalTime = System.currentTimeMillis() - buildElement.startTime;
        buildElement.element.setAttribute(TIME_ATTR,
                DateUtils.formatElapsedTime(totalTime));
    }
}
