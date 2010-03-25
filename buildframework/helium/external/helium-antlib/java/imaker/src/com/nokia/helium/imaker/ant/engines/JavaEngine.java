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
package com.nokia.helium.imaker.ant.engines;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map.Entry;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.plexus.StreamRecorder;
import com.nokia.helium.imaker.IMaker;
import com.nokia.helium.imaker.IMakerException;
import com.nokia.helium.imaker.ant.Command;
import com.nokia.helium.imaker.ant.Engine;
import com.nokia.helium.imaker.ant.taskdefs.IMakerTask;

/**
 * Engine purely based on Java. Parallelisation is
 * implemented using multithreading.
 * 
 * <pre>
 * &lt;defaultEngine id="imaker.default" threads="4" /&gt;
 * </pre>
 * 
 * @ant.type name=defaultEngine category="imaker"
 */
public class JavaEngine extends DataType implements Engine {

    private IMakerTask task;
    private OutputStreamWriter output;
    private int threads = 1;

    /**
     * {@inheritDoc}
     */
    @Override
    public void setTask(IMakerTask task) {
        this.task = task;
    }
    
    /**
     * Defines the number of iMaker jobs running in
     * parallel. 
     * @ant.not-required Default value is 1.
     */
    public void setThreads(int threads) {
        this.threads = threads;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void build(List<List<Command>> cmds) throws IMakerException {
        task.log("Building with Ant engine.");
        if (threads <= 0) {
            throw new BuildException("'threads' must be >= 0. (current value: " + threads + ")");
        }
        openLog();
        // Do something with the configurations
        for (List<Command> cmdlist : cmds) {
            task.log("Building command list in parallel.");
            if (cmdlist.size() > 0) {
                ArrayBlockingQueue<Runnable> queue = new ArrayBlockingQueue<Runnable>(cmdlist.size());
                ThreadPoolExecutor threadPool = new ThreadPoolExecutor(threads, threads, 10, TimeUnit.MILLISECONDS, queue);
                task.log("Adding " + cmdlist.size() + " to queue.");
                for (final Command cmd : cmdlist) {
                    // Create a Runnable to wrap the image
                    // building.
                    threadPool.execute(new Runnable() {
                        public void run() {
                            try {
                                buildCommand(cmd);
                            } catch (IMakerException e) {
                                task.log(e.getMessage(), Project.MSG_ERR);
                            }
                        }
                    });
                }
                threadPool.shutdown();
                try {
                    while (!threadPool.isTerminated()) {
                        threadPool.awaitTermination(100, TimeUnit.MILLISECONDS);
                    }
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
        closeLog();
    }

  
    /**
     * Build a Command.
     * @param cmd
     * @throws IMakerException
     */
    protected void buildCommand(Command cmd) throws IMakerException {
        IMaker imaker = task.getIMaker();
        StreamRecorder rec = new StreamRecorder();
        imaker.addOutputLineHandler(rec);
        imaker.addErrorLineHandler(rec);
        
        rec.consumeLine("-- " + cmd.getCmdLine());
        rec.consumeLine("++ Started at " + new Date());
        rec.consumeLine("+++ HiRes Start " + new Date().getTime());
        
        List<String> args = new ArrayList<String>();
        args.addAll(cmd.getArguments());
        // Setting the working dir for the image creation.
        File tempDir = imaker.createWorkDir();
        args.add("WORKDIR=" + tempDir.getAbsolutePath());
        // Pushing custom variables
        for (Entry<String, String> e : cmd.getVariables().entrySet()) {
            if (e.getKey().equals("WORKDIR")) {
                task.log("WORKDIR cannot be defined by the user, the value will be ignored.", Project.MSG_WARN);
            } else {
                args.add(e.getKey() + "=" + e.getValue());
            }
        }
        // Setting the target
        args.add(cmd.getTarget());                
        try {
            imaker.execute(args.toArray(new String[args.size()]));
        } catch (IMakerException e) {
            // logging iMaker execution error to the 
            // task and the output log.
            task.log(e.getMessage(), Project.MSG_ERR);
            rec.consumeLine(e.getMessage());
        } finally {
            rec.consumeLine("+++ HiRes End " + new Date().getTime());
            rec.consumeLine("++ Finished at " + new Date());
        }
        // writing data
        writeLog(rec.getBuffer().toString());
    }
    
    private void openLog() throws IMakerException {
        if (task.getOutput() != null) {
            try {
                output = new OutputStreamWriter(new FileOutputStream(task.getOutput()));
            } catch (FileNotFoundException e) {
                throw new IMakerException(e.getMessage(), e);
            }
        }
    }

    private synchronized void writeLog(String str) throws IMakerException {
        if (output != null) {
            try {
                output.write(str);
            } catch (IOException e) {
                throw new IMakerException(e.getMessage(), e);
            }
        }
    }
    
    private void closeLog() throws IMakerException {
        if (output != null) {
            try {
                output.close();
            } catch (IOException e) {
                throw new IMakerException(e.getMessage(), e);
            }
        }
    }
}
