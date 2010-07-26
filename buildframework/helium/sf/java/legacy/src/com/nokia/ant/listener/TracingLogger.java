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
 
package com.nokia.ant.listener;

import java.io.FileNotFoundException;
import java.io.PrintWriter;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.lang.management.MemoryUsage;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.Project;
/**
 * This subclass of BuildListener object is to trace heap memory usages for task, target and build.
 *
 */
public class TracingLogger implements BuildListener
{
    private Project project;

    private MemoryMXBean mbean;

    private boolean loggingEnabled;

    private PrintWriter out;
    
    private String currentTarget;

    public void buildFinished(BuildEvent event)
    {
        out.close();
    }

    public void buildStarted(BuildEvent event)
    {
        mbean = ManagementFactory.getMemoryMXBean();
        // mbean.setVerbose(true);
        project = event.getProject();
    }

    public void messageLogged(BuildEvent event)
    {
    }

    public void targetFinished(BuildEvent event)
    {
//        logMemoryUsage("target", event.getTarget().getName());
        currentTarget = "";
    }

    public void targetStarted(BuildEvent event)
    {
        currentTarget = event.getTarget().getName();
        try
        {
            if (!loggingEnabled)
            {
                loggingEnabled = true;
                String tracingFile = project.getProperty("tracing.csv.file");
                out = new PrintWriter(tracingFile);
                out.print("target,task,committed,used,timestamp\n");
            }
//            logMemoryUsage("target", event.getTarget().getName());
        }
        catch (FileNotFoundException e)
        {
            throw new BuildException(e.getMessage(), e);
        }
    }

    public void taskFinished(BuildEvent event)
    {
        logMemoryUsage("task", event.getTask().getTaskName());
    }

    public void taskStarted(BuildEvent event)
    {
        logMemoryUsage("task", event.getTask().getTaskName());
    }

    private void logMemoryUsage(String type, String label)
    {
        if (loggingEnabled)
        {
            MemoryUsage heapMemory = mbean.getHeapMemoryUsage();
            project.log("Build event: " + label, Project.MSG_DEBUG);
            project.log("Max memory = " + heapMemory.getMax(), Project.MSG_DEBUG);
            project.log("Committed memory = " + heapMemory.getCommitted(), Project.MSG_DEBUG);
            project.log("Used memory = " + heapMemory.getUsed(), Project.MSG_DEBUG);
            long timestamp = System.currentTimeMillis();
            out.print(currentTarget + "," + label  + ","
                    + heapMemory.getCommitted() + "," + heapMemory.getUsed() + "," + String.valueOf(timestamp) + "\n");
        }
    }
}
