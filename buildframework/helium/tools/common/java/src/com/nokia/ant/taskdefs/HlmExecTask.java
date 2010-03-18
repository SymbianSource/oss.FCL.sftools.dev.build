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

package com.nokia.ant.taskdefs;

import org.apache.tools.ant.taskdefs.ExecTask;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.BuildException;

import java.util.concurrent.*;

/**
 * Exec task using shared thread pool
 * @ant.task name="exec"
 */
public class HlmExecTask extends ExecTask
{   
    private static int poolSize = Runtime.getRuntime().availableProcessors();
    private static int maxPoolSize = poolSize * 2;
    private static ExecutorService threadPool = Executors.newFixedThreadPool(maxPoolSize);
    private final Object semaphore = new Object();
    
    /**
      * Submit exec into pool and throw exceptions
      */
    public void execute()
    {
        String p = project.getProperty("number.of.threads");
        if (p != null)
        {
            ((ThreadPoolExecutor)threadPool).setCorePoolSize(Integer.parseInt(p));
            ((ThreadPoolExecutor)threadPool).setMaximumPoolSize(Integer.parseInt(p));
        }
        TaskRunnable tr = new TaskRunnable();
        threadPool.submit(tr);
        try {
            synchronized (semaphore) {
                while (!tr.isFinished())
                    semaphore.wait();
            }
        } catch (InterruptedException e) { e.printStackTrace(); }
          
        Throwable t = tr.getException();
        if (t != null)
        {
            if (t instanceof BuildException)
                throw (BuildException)t;
            else
                t.printStackTrace();
        }
    }
    
    private class TaskRunnable implements Runnable {
        private Task task;
        private boolean finished;
        private volatile Thread thread;
        private Throwable exception;

        /**
         * Executes the task within a thread and takes care about
         * Exceptions raised within the task.
         */
        public void run() {
            try {
                thread = Thread.currentThread();
                HlmExecTask.super.execute();
            } catch (Throwable t) {
                exception = t;
            } finally {
                synchronized (semaphore) {
                    finished = true;
                    semaphore.notifyAll();
                }
            }
        }
        
        /**
         * get any exception that got thrown during execution;
         * @return an exception or null for no exception/not yet finished
         */
        public Throwable getException() {
            return exception;
        }
        
        /**
         * Provides the indicator that the task has been finished.
         * @return Returns true when the task is finished.
         */
        boolean isFinished() {
            return finished;
        }

        void interrupt() {
            thread.interrupt();
        }
    }
}