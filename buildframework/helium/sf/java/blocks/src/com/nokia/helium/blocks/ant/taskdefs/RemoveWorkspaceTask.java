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

import org.apache.tools.ant.BuildException;

import com.nokia.helium.blocks.BlocksException;
import com.nokia.helium.blocks.ant.AbstractBlocksTask;

/**
 * Remove a Blocks workspace.
 * 
 * The workspace 1 will be removed: 
 * <pre>
 * &lt;hlm:blocksRemoveWorkspace wsid="1" /&gt; 
 * </pre>
 * 
 * @ant.task name="blocksRemoveWorkspace" category="Blocks"
 */
public class RemoveWorkspaceTask extends AbstractBlocksTask {

    /**
     * {@inheritDoc}
     */
    @Override
    public void execute() {
        try {
            getBlocks().removeWorkspace(getWsid());
            log("Workspace " + getWsid() + " removed successfully.");
        } catch (BlocksException e) {
            throw new BuildException(e);
        }
    }

}
