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
package com.nokia.helium.sbs;

import java.io.File;
import java.util.HashMap;

import com.nokia.helium.core.plexus.CommandBase;

/**
 * Simple SBS wrapper based on the CommandBase class.
 *
 */
public class SBSCommandBase extends CommandBase<SBSException> {

    private File workingDir;
    
    private String cleanLogPath;

    private String whatLogPath;

    private String  executable = "sbs";
    
    /**
     * @return sbs.
     */
    @Override
    protected String getExecutable() {
        return executable;
    }
    
    

    /**
     * @param executable the executable to set
     */
    public void setExecutable(String executable) {
        this.executable = executable;
    }



    /**
     * {@inheritDoc}
     */
    @Override
    protected void throwException(String message, Throwable t) throws SBSException {
        throw new SBSException(message, t);
    }

    /**
     * Set the working directory where emake should be called.
     * @param workingDir the working directory.
     */
    public void setWorkingDir(File workingDir) {
        this.workingDir = workingDir;
    }

    /**
     * Get the workingDir defined by the user.
     * @return the working dir.
     */
    @Override
    public File getWorkingDir() {
        return workingDir;
    }

    public void setCleanLogFilePath(String path) {
        cleanLogPath = path;
    }

    public void setWhatLogFilePath(String path) {
        whatLogPath = path;
    }

    /**
     * Executes the command using as argline, instead of argument.
     * @param argLine, argline to execute.
     */
    public void execute(String argLine) throws SBSException {
        HashMap<String, String> envMap = new HashMap<String, String>();
        envMap.put("PYTHONPATH", "");
        if ( cleanLogPath != null) {
            envMap.put("SBS_CLEAN_LOG_FILE", cleanLogPath);
            envMap.put("SBS_WHAT_LOG_FILE", whatLogPath);
        }
        executeCmdLine(argLine, envMap, null);
    }
}
