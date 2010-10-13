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


package com.nokia.helium.signal.ant.types;

import java.io.File;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Vector;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.MagicNames;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.ProjectHelper;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.TaskContainer;
import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.types.Resource;
import org.apache.tools.ant.types.ResourceCollection;

import com.nokia.helium.signal.ant.Notifier;

/**
 * This notifier allows you to execute a task sequence when a specific signal
 * is raised.
 * 
 * Task are executed in a subproject, and the 'signal.name' property is set
 * to the emit signal name. The 'signal.status' property will contains the 
 * status of the signal. Finally the 'signal.notifier.inputs' property will
 * contains the list of NotifierInput passed to this Notifier.
 * 
 * If an error occur during the execution of the task sequence it will get ignored.
 * 
 * E.g:
 * <pre>
 * &lt;hlm:executeTaskNotifier&gt;
 *    &lt;echo&gt;Something goes wrong, signal ${signal.name} has been raised.&lt;/echo&gt;
 * &lt;/hlm:executeTaskNotifier&gt;
 * </pre>
 * 
 * @ant.type name="executeTaskNotifier" category="Signaling"
 */
public class ExecuteTaskNotifier extends DataType implements Notifier,
        TaskContainer {
    private List<Task> tasks = new ArrayList<Task>();
    private boolean failOnError;

    
    /**
     * Method executes a series of given tasks on raising of the specified signal.
     * 
     * @param signalName is the name of the signal that has been raised.
     * @param failStatus indicates whether to fail the build or not
     * @param notifierInput contains signal notifier info
     * @param message is the message from the signal that has been raised.           
     */
    @SuppressWarnings("unchecked")
    public void sendData(String signalName, boolean failStatus,
            ResourceCollection notifierInput, String message ) {
        try {
            // Configure the project
            Project prj = getProject().createSubProject();
            getProject().initSubProject(prj);
            prj.initProperties();
            prj.setInputHandler(getProject().getInputHandler());
            for (BuildListener bl : (Vector<BuildListener>)getProject().getBuildListeners()) {
                prj.addBuildListener(bl);
            }
            getProject().copyUserProperties(prj);
            getProject().copyInheritedProperties(prj);
            // We need to autoconfigure the project - target and tasks-...
            ProjectHelper.configureProject(prj, new File(getProject().getProperty(MagicNames.ANT_FILE)));
            prj.inheritIDReferences(getProject());
            
            
            prj.setProperty("signal.name", signalName);
            prj.setProperty("signal.status", "" + failStatus);
            prj.setProperty("signal.message", message );
            // Converting the list of inputs into a string.
            String inputs = "";
            if (notifierInput != null) {
                Iterator<Resource> ri = notifierInput.iterator();
                while (ri.hasNext()) {
                    inputs += ri.next().toString();
                    if (ri.hasNext()) {
                        inputs += File.pathSeparator;
                    }
                }
            }
            prj.setProperty("signal.notifier.inputs", inputs);
            for (Task task : tasks) {
                log("Executing task: " + task.getTaskName(), Project.MSG_DEBUG);
                task.setProject(prj);
                task.perform();
            }
        } catch (BuildException e) {
            if (isFailOnError()) {
                throw e;
            } else {
                // We are Ignoring the errors as no need to fail the build.
                log("[" + this.getDataTypeName() + "] ERROR: " + e.getMessage(), Project.MSG_ERR);
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    public void addTask(Task task) {
        tasks.add(task);
    }

    /**
     * Defines if an error happens while executing 
     * @param failonerror
     */
    public void setFailOnError(boolean failonerror) {
        this.failOnError = failonerror;
    }

    public boolean isFailOnError() {
        return failOnError;
    }

}
