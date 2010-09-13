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
package com.nokia.helium.logger.ant.taskdefs;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.DefaultLogger;
import org.apache.tools.ant.MagicNames;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.ProjectHelper;
import org.apache.tools.ant.RuntimeConfigurable;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.TaskContainer;
import org.apache.tools.ant.UnknownElement;
import org.apache.tools.ant.taskdefs.Recorder.VerbosityLevelChoices;

/**
 * The taskRecorder task allows you to record the output of the execution
 * of a set of task into a log file. The output is not redirected to any 
 * other recorders, so nothing will appear on the console.  
 * 
 * Example of usage:
 * <pre>
 * &lt;hlm:taskRecorder output=&quot;output.log&quot; logLevel=&quot;verbose&quot; &gt;
 *     &lt;echo&gt;This output will be recorded under output.log&lt;/echo&gt;
 *     &lt;property name=&quot;new.property&quot; value=&quot;value&quot; /&gt;
 * &lt;/hlm:taskRecorder&gt;
 * </pre>
 * 
 * In the previous example the output of echo task is redirected to the output log.
 * 
 * @ant.task name="taskRecorder" category="Logging"
 */
public class TaskRecorder extends Task implements TaskContainer {
    private List<Task> tasks = new ArrayList<Task>(); 
    private File output;
    private int logLevel = Project.MSG_INFO;
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void addTask(Task task) {
        tasks.add(task);
    }
        
    /**
     * {@inheritDoc}
     */
    public void execute() {
        if (output == null) {
            throw new BuildException("The output attribute has not been defined.");            
        }
        
        // creating a project delegator, which will propagate the properties into
        // the parent project
        ProjectDelegator subProject = new ProjectDelegator(getProject());
        getProject().initSubProject(subProject);
        // set user-defined properties
        getProject().copyUserProperties(subProject);
        subProject.initProperties();
        ProjectHelper.configureProject(subProject, new File(getProject().getProperty(MagicNames.ANT_FILE)));

        // The delegator enables the property propagation.
        subProject.setUseDelegate(true);
        // Let's replicate all our childs into a sequential task which is 
        // going to use the delegate project.
        UnknownElement subTask = new UnknownElement("sequential");
        subTask.setTaskName("sequential");
        subTask.setNamespace("");
        subTask.setQName("sequential");
        subTask.setProject(subProject);
        new RuntimeConfigurable(subTask, "sequential");
        for (Task task : this.tasks) {
            if (task instanceof UnknownElement) {
                UnknownElement ue = ((UnknownElement)task).copy(subProject);            
                ue.setProject(subProject);
                subTask.addChild(ue);
                subTask.getWrapper().addChild(ue.getWrapper());
            } else {
                log("Task " + task.getTaskName() + " is not a UnknownElement. Element will be ignored.", Project.MSG_WARN);
            }
        }
        
        PrintStream out = null;
        DefaultLogger logger = null;
        try {
            // Creating the a logger to record the execution
            out = new PrintStream(new FileOutputStream(output));
            logger = new DefaultLogger();
            logger.setMessageOutputLevel(this.logLevel);
            logger.setOutputPrintStream(out);
            logger.setErrorPrintStream(out);
            subProject.addBuildListener(logger);
            log("Recording output to " + output.getAbsolutePath());
            subTask.perform();
        } catch (IOException ex) {
            log("Can't set output to " + output + ": " + ex.getMessage(), Project.MSG_ERR);
            throw new BuildException("Can't set output to " + output + ": " + ex.getMessage());
        } finally {
            if (logger != null) {
                subProject.removeBuildListener(logger);
            }
            if (out != null) {
                out.close();
            }
            subProject = null;
        }
    }

    /**
     * Defines the output log.
     * @param output
     * @ant.required
     */
    public void setOutput(File output) {
        this.output = output;
    }

    /**
     * Defines the logging level (e.g error, warning, info, verbose, debug).
     * @param logLevel
     * @ant.not-required Default is info.
     */
    public void setLogLevel(VerbosityLevelChoices logLevel) {
        this.logLevel = logLevel.getLevel();
    }
    
    
    /**
     * Project used to delegate property manipulation
     * calls to a delegate project. 
     *
     */
    class ProjectDelegator extends Project {
        private Project delegate;
        private boolean useDelegate;

        public ProjectDelegator(Project delegate) {
            this.delegate = delegate;
        }
        
        /**
         * @return the useDelegate
         */
        public boolean isUseDelegate() {
            return useDelegate;
        }

        /**
         * @param useDelegate the useDelegate to set
         */
        public void setUseDelegate(boolean useDelegate) {
            this.useDelegate = useDelegate;
        }

        /**
         * @return
         * @see org.apache.tools.ant.Project#getProperties()
         */
        public Hashtable getProperties() {
            if (useDelegate) {
                return delegate.getProperties();
            } else {
                return super.getProperties();
            }
        }
        /**
         * @param propertyName
         * @return
         * @see org.apache.tools.ant.Project#getProperty(java.lang.String)
         */
        public String getProperty(String propertyName) {
            if (useDelegate) {
                return delegate.getProperty(propertyName);
            } else {
                return super.getProperty(propertyName);
            }
        }

        /**
         * @return
         * @see org.apache.tools.ant.Project#getUserProperties()
         */
        public Hashtable getUserProperties() {
            if (useDelegate) {
                return delegate.getUserProperties();
            } else {
                return super.getUserProperties();
            }
        }
        /**
         * @param propertyName
         * @return
         * @see org.apache.tools.ant.Project#getUserProperty(java.lang.String)
         */
        public String getUserProperty(String propertyName) {
            if (useDelegate) {
                return delegate.getUserProperty(propertyName);
            } else {
                return super.getUserProperty(propertyName);
            }
        }
        /**
         * @param value
         * @return
         * @throws BuildException
         * @see org.apache.tools.ant.Project#replaceProperties(java.lang.String)
         */
        public String replaceProperties(String value) {
            if (useDelegate) {
                return delegate.replaceProperties(value);
            } else {
                return super.replaceProperties(value);
            }
        }

        /**
         * @param name
         * @param value
         * @see org.apache.tools.ant.Project#setNewProperty(java.lang.String, java.lang.String)
         */
        public void setNewProperty(String name, String value) {
            if (useDelegate) {
                delegate.setNewProperty(name, value);
            } else {
                super.setNewProperty(name, value);
            }
        }

        /**
         * @param name
         * @param value
         * @see org.apache.tools.ant.Project#setProperty(java.lang.String, java.lang.String)
         */
        public void setProperty(String name, String value) {
            if (useDelegate) {
                delegate.setProperty(name, value);
            } else {
                super.setProperty(name, value);
            }
        }

        /**
         * @param name
         * @param value
         * @see org.apache.tools.ant.Project#setUserProperty(java.lang.String, java.lang.String)
         */
        public void setUserProperty(String name, String value) {
            if (useDelegate) {
                delegate.setUserProperty(name, value);
            } else {
                super.setUserProperty(name, value);
            }
        }
    }
}
