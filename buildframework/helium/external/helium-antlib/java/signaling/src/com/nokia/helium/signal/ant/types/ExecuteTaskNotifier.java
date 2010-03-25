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

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import org.apache.log4j.Logger;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.TaskContainer;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.signal.Notifier;

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
@SuppressWarnings("deprecation")
public class ExecuteTaskNotifier extends DataType implements Notifier,
        TaskContainer {

    private Logger log = Logger.getLogger(ExecuteTaskNotifier.class);
    private List<Task> tasks = new ArrayList<Task>();

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
            NotifierInput notifierInput, String message ) {
        try {
            // Configure the project
            Project prj = getProject().createSubProject();
            prj.initProperties();
            prj.setInputHandler(getProject().getInputHandler());
            for (BuildListener bl : (Vector<BuildListener>)getProject().getBuildListeners()) {
                prj.addBuildListener(bl);
            }
            getProject().copyUserProperties(prj);
            
            
            prj.setProperty("signal.name", signalName);
            prj.setProperty("signal.status", "" + failStatus);
            prj.setProperty("signal.message", message );
            // Converting the list of inputs into a string.
            String inputs = "";
            if (notifierInput != null) {
                inputs += notifierInput.getFile().toString();
            }
            prj.setProperty("signal.notifier.inputs", inputs);
            for (Task task : tasks) {
                log.debug("Executing task: " + task.getTaskName());
                task.setProject(prj);
                task.perform();
            }
        } catch (BuildException e) {
            // We are Ignoring the errors as no need to fail the build.
            log.debug(e.toString(), e);
        }
    }

    @Override
    public void addTask(Task task) {
        log.debug("Adding task: " + task.getTaskName());
        tasks.add(task);
    }

    @Override
    public void sendData(String signalName, boolean failStatus, List fileList) {        
    }

}
