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
package com.nokia.helium.core.plexus;

import java.io.File;
import java.util.Map;
import java.util.Vector;

import org.apache.log4j.Logger;
import org.codehaus.plexus.util.Os;
import org.codehaus.plexus.util.cli.CommandLineException;
import org.codehaus.plexus.util.cli.CommandLineUtils;
import org.codehaus.plexus.util.cli.Commandline;
import org.codehaus.plexus.util.cli.StreamConsumer;

/**
 * This abstract class implements some basic support to execute commands and 
 * redirect outputs to StreamConsumer. You can have common stream consumers or
 * execution base streamconsumers. The exception type raised 
 * can be controlled by the implementing class.
 *
 * @param <T>
 */
public abstract class CommandBase<T extends Exception> {
    private final Logger log = Logger.getLogger(getClass());
    private Vector<StreamConsumer> outputHandlers = new Vector<StreamConsumer>();
    private Vector<StreamConsumer> errorHandlers = new Vector<StreamConsumer>();

    /**
     * Get the executable name.
     * @return
     */
    protected abstract String getExecutable();

    /**
     * Throw an exception with message and cause.
     * @param message
     * @param t
     * @throws T
     */
    protected abstract void throwException(String message, Throwable t) throws T;

    /**
     * Throw an exception with message only.
     * @param message
     * @throws T
     */
    protected void throwException(String message) throws T {
        throwException(message, null);
    }

    /**
     * Location where to execute the command. The default location
     * is the current directory.
     * @return a File object pointing to a directory.
     */
    public File getWorkingDir() {
        return new File(".");
    }
    
    /**
     * Add a LineHandler to the CommandBase instance.
     * LineHandlers could be used to record/log the output stream
     * command invocation.
     * @param lineHandler a lineHandle instance
     */
    public void addOutputLineHandler(StreamConsumer lineHandler) {
        if (lineHandler != null) {
            outputHandlers.add(lineHandler);
        }
    }
    
    /**
     * Add a LineHandler to the CommandBase instance.
     * LineHandlers could be used to record/log the output error stream
     * command invocation.
     * @param lineHandler a lineHandle instance
     */
    public void addErrorLineHandler(StreamConsumer lineHandler) {
        if (lineHandler != null) {
            errorHandlers.add(lineHandler);
        }
    }

    /**
     * Execute the command defined by getExecutable with args as list of arguments.
     * 
     * @param args
     * @throws T extends
     */
    public void execute(String[] args) throws T {
        execute(args, null);
    }

    /**
     * Execute the command given by getExecutable with args as list of arguments and custom StreamConsumer.
     * 
     * @param args
     *            an array representing blocks arguments
     * @param output
     *            the StreamConsumer to analyze the output with. If null it is
     *            ignored.
     * @throws T
     */
    public void execute(String[] args, StreamConsumer output) throws T {
        execute(args, null, output);
    }

    /**
     * Execute the command given by getExecutable with args as list of arguments and custom StreamConsumer.
     * Also env content will be added to the environment. 
     * 
     * @param args
     *            an array representing blocks arguments
     * @param env
     *            additional key to add the environment
     * @param output
     *            the StreamConsumer to analyze the output with. If null it is
     *            ignored.
     * @throws T
     */
    public void executeCmdLine(String argLine, Map<String, String> env, StreamConsumer output)
            throws T {
        Commandline cmdLine = new Commandline();
        cmdLine.createArg().setValue(getExecutable());
        if (argLine != null) {
            cmdLine.createArg().setLine(argLine);
        }
        executeCmd(cmdLine, env, output);
    }

    private void executeCmd(Commandline cmdLine, Map<String, String> env, StreamConsumer output)     throws T  {
        if (env != null) {
            for (Map.Entry<String, String> entry : env.entrySet()) {
                cmdLine.addEnvironment(entry.getKey(), entry.getValue());
            }
        }
        cmdLine.setWorkingDirectory(getWorkingDir());
        
        // This is only needed on windows.
        if (Os.isFamily(Os.FAMILY_WINDOWS)) {
            cmdLine.createArg().setLine("&& exit %%ERRORLEVEL%%");    
        }
        

        StreamMultiplexer inputMux = new StreamMultiplexer();
        if (output != null) {
            inputMux.addHandler(output);
        }
        for (StreamConsumer lh : outputHandlers) {
            inputMux.addHandler(lh);
        }

        StreamMultiplexer errorMux = new StreamMultiplexer();
        StreamRecorder errorRecorder = new StreamRecorder();
        errorMux.addHandler(errorRecorder);
        for (StreamConsumer lh : errorHandlers) {
            errorMux.addHandler(lh);
        }

        try {
            int err = CommandLineUtils.executeCommandLine(cmdLine, inputMux,
                    errorMux);
            // check its exit value
            log.debug("Execution of " + getExecutable() + " returned: " + err);
            if (err != 0) {
                throwException(errorRecorder.getBuffer() + " (return code: " + err
                        + ")");
            }
        } catch (CommandLineException e) {
            throwException(
                    "Error executing " + getExecutable() + ": "
                            + e.toString());
        }
    }

    /**
     * Execute the command given by getExecutable with args as list of arguments and custom StreamConsumer.
     * Also env content will be added to the environment. 
     * 
     * @param args
     *            an array representing blocks arguments
     * @param env
     *            additional key to add the environment
     * @param output
     *            the StreamConsumer to analyze the output with. If null it is
     *            ignored.
     * @throws T
     */
    public void execute(String[] args, Map<String, String> env, StreamConsumer output)
            throws T {
        Commandline cmdLine = new Commandline();
        cmdLine.createArg().setValue(getExecutable());
        if (args != null) {
            cmdLine.addArguments(args);
        }
        executeCmd(cmdLine, env, output);
    }
    
}
