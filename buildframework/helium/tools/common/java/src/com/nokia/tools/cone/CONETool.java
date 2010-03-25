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

package com.nokia.tools.cone;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

import org.apache.tools.ant.Project;

import com.nokia.helium.core.ant.types.VariableSet;
import com.nokia.tools.Tool;
import com.nokia.tools.ToolsProcessException;


/**
 * To generate the cenrep files using ConE tool.
 * 
 *
 */
public class CONETool implements Tool {
    
    private Map<String, String> varMapping = new HashMap<String, String>();

    public void execute(VariableSet varSet, Project prj)
            throws ToolsProcessException {
        // TODO Auto-generated method stub

    }
    
    
    /**
     * Run the cone command with arguments from hashmap.
     * @param prj
     * @throws ToolsProcessException
     */
    public void execute(Project prj) throws ToolsProcessException {
        
        org.apache.tools.ant.taskdefs.ExecTask task = new org.apache.tools.ant.taskdefs.ExecTask();
        task.setTaskName("ConE");
        task.setDir(new java.io.File(varMapping.get("path")));
        task.setExecutable("cmd.exe");
        task.setOutput(new File(varMapping.get("output")));
        task.createArg().setValue("/c");
        task.setAppend(true);
        task.createArg().setValue("cone.cmd");
        task.createArg().setValue("generate");
        for (Map.Entry<String, String> varEntry : varMapping.entrySet() ) {
            if ( !varEntry.getKey().equals("path") && !varEntry.getKey().equals("output")) {
                task.createArg().setValue(varEntry.getKey());
                task.createArg().setValue(varEntry.getValue());
            }
        }
        task.execute();
    }
    
    /**
     * To Store the variable and it value into hashmap to read them later.
     * @param name
     * @param value
     */
    public void storeVariables(String name, String value) {
        varMapping.put(name, value);
    }

}
