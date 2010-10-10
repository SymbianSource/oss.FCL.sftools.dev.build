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
package com.nokia.helium.blocks.ant.taskdefs;

import java.io.File;

import org.apache.tools.ant.BuildException;
import com.nokia.helium.blocks.BlocksException;
import com.nokia.helium.blocks.Workspace;
import com.nokia.helium.blocks.ant.AbstractBlocksTask;

/**
 * Declare a directory as a Blocks workspace.
 * 
 * <pre>
 * &lt;hlm:blocksAddWorkspace name="myworkspace" dir="/path/to/workspace/dir/" wsidproperty="wsid" /&gt; 
 * </pre>
 * 
 * @ant.task name="blocksAddWorkspace" category="Blocks"
 */
public class AddWorkspaceTask extends AbstractBlocksTask {

    private String name;
    private File dir;
    private String wsidproperty;
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void execute() {
        if (dir == null) {
            throw new BuildException("dir attribute is not defined.");
        }
        if (name == null) {
            throw new BuildException("name attribute is not defined.");
        }
        try {
            Workspace workspace = getBlocks().addWorkspace(dir, name);
            log("Workspace " + workspace.getWsid() + " has been created successfully.");
            if (wsidproperty != null) {
                getProject().setNewProperty(wsidproperty, "" + workspace.getWsid());
            }
        } catch (BlocksException exc) {
            throw new BuildException(exc);
        }
    }

    /**
     * The name of the output property.
     * @param wsidproperty
     * @ant.required
     */
    public void setWsidproperty(String wsidproperty) {
        this.wsidproperty = wsidproperty;
    }

    /**
     * The name of the workspace.
     * @param name
     * @ant.required
     */
    public void setName(String name) {
        this.name = name;
    }


    /**
     * The location of the workspace.
     * @param dir
     * @ant.required
     */
    public void setDir(File dir) {
        this.dir = dir;
    }
    
}
