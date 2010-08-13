/*
 * Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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

package com.nokia.helium.environment.ant.listener;

import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.List;

import org.apache.log4j.Logger;
import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.RuntimeConfigurable;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.UnknownElement;

/**
 * Checks for uses of the <exec> task and logs them to a CSV file.
 * 
 * The ExecListener.file property should be used to define a file to log the output to.
 */
public class ExecListener implements BuildListener {
    private static List<String> execCalls = new ArrayList<String>();
    
    private Logger logger = Logger.getLogger(this.getClass());
    
    public static List<String> getExecCalls() {
        return execCalls;
    }

    @Override
    public void buildStarted(BuildEvent event) {
        logger.debug("ExecListener started");
    }

    @Override
    public void buildFinished(BuildEvent event) {
        try {
            String file = event.getProject().getProperty("ExecListener.file");
            if (file != null && file.length() > 0) {
                FileWriter out = new FileWriter(file);
                for (Iterator<String> iterator = execCalls.iterator(); iterator.hasNext();) {
                    String execCall = (String) iterator.next();
                    out.write(execCall + "\n");
                }
                out.close();
            }
        }
        catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void messageLogged(BuildEvent event) {
    }

    @Override
    public void targetStarted(BuildEvent event) {
    }

    @Override
    public void targetFinished(BuildEvent event) {
    }

    @Override
    public void taskStarted(BuildEvent event) {
    }

    /**
     * Attempt to log the name of the an exec task if one is executed.
     */
    @SuppressWarnings("unchecked")
    @Override
    public void taskFinished(BuildEvent event) {
        Task task = event.getTask();
        String taskName = task.getTaskName();
        if (taskName != null && taskName.equals("exec")) {
            logger.debug("Found exec task");
            if (task instanceof UnknownElement) {
                RuntimeConfigurable configurable = ((UnknownElement) task).getRuntimeConfigurableWrapper();
                Hashtable<String, String> map = configurable.getAttributeMap();
                String executable = (String) map.get("executable");
                Project project = event.getProject();
                executable = project.replaceProperties(executable);
                logger.debug("ExecListener: executable is run: " + executable);
                execCalls.add(executable);
            }
        }
    }
}



