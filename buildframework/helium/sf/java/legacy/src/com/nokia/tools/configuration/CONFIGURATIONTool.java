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

package com.nokia.tools.configuration;

import com.nokia.helium.core.ant.types.VariableSet;
import com.nokia.helium.core.ant.types.Variable;
import com.nokia.tools.*;
import org.apache.tools.ant.Project;

/**
 * Command Line wrapper for configuration tools
 */
public class CONFIGURATIONTool implements Tool {

    /**
     * Sets the command line variables to be used to execute and validates for
     * the required parameters
     * 
     * @param varSet
     *            variable(name / value list)
     */
    public void execute(VariableSet varSet, Project prj)
            throws ToolsProcessException {
        String path = null;
        String masterConf = null;
        String confml = null;
        String impl = null;
        String iby = null;
        String keepGoing = "false";
        String report = null;
        String varName;
        String value;
        for (Variable variable : varSet.getVariables()) {
            varName = variable.getName();
            value = variable.getValue();
            if (varName.equals("path")) {
                path = value;
            } else if (varName.equals("master_conf")) {
                masterConf = value;
            } else if (varName.equals("confml")) {
                confml = value;
            } else if (varName.equals("impl")) {
                impl = value;
            } else if (varName.equals("iby")) {
                iby = value;
            } else if (varName.equals("keepgoing")) {
                keepGoing = value;
            } else if (varName.equals("report")) {
                report = value;
            }
        }
        if (path == null || masterConf == null || confml == null || iby == null) {
            throw new ToolsProcessException("Config Tool Parameter missing");
        }
        org.apache.tools.ant.taskdefs.ExecTask task = new org.apache.tools.ant.taskdefs.ExecTask();
        task.setTaskName("Configuration");
        task.setDir(new java.io.File(path));
        task.setExecutable(path + java.io.File.separator + "cli_build.cmd");
        if (keepGoing.equals("false")) {
            task.setFailonerror(true);
        } else {
            task.createArg().setValue("-ignore_errors");
        }
        task.createArg().setValue("-master_conf");
        task.createArg().setValue(masterConf);
        task.createArg().setValue("-impl");
        task.createArg().setValue(impl);
        task.createArg().setValue("-confml");
        task.createArg().setValue(confml);
        task.createArg().setValue("-iby");
        task.createArg().setValue(iby);
        if (report != null) {
            task.createArg().setValue("-report");
            task.createArg().setValue(report);
        }
        task.execute();
    }
}