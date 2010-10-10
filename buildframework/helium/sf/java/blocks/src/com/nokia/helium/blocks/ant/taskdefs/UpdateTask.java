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
 * Updating a workspace content.
 * 
 * This call will update the workspace &quot;1&quot;: 
 * <pre>
 * &lt;hlm:blocksUpdate wsid=&quot;1&quot; /&gt; 
 * </pre>
 * 
 * @ant.task name="blocksUpdate" category="Blocks"
 */
public class UpdateTask extends AbstractBlocksTask {
    

    /**
     * {@inheritDoc}
     */
    @Override
    public void execute() {
        try {
            log("Updating workspace " + getWsid() + ".");
            getBlocks().update(getWsid());
            log("Workspace " + getWsid() + " updated successfully.");
        } catch (BlocksException exc) {
            throw new BuildException(exc);
        }
    }

}
