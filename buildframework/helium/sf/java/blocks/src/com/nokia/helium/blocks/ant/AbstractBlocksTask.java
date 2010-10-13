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
package com.nokia.helium.blocks.ant;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;

import com.nokia.helium.blocks.Blocks;
import com.nokia.helium.core.plexus.AntStreamConsumer;

/**
 * This class implement an abstract Blocks task. It predefines 
 * some method to handle the workspace id. 
 *
 */
public abstract class AbstractBlocksTask extends Task {

    private Blocks blocks;
    private boolean verbose;
    private Integer wsid;

    /**
     * The workspace id.
     * @param wsid
     * @ant.not-required
     */
    public void setWsid(Integer wsid) {
        this.wsid = wsid;
    }

    /**
     * Get the workspace id, it throws a BuildException if not set.
     * @return
     */
    public int getWsid() {
        if (wsid == null) {
            throw new BuildException("wsid has not been specified.");
        }
        return wsid.intValue();
    }
    
    
    /**
     * Are we execution the task in verbose mode.
     * @return
     */
    public boolean isVerbose() {
        return verbose;
    }

    /**
     * Set true to show the output from blocks command execution.
     * @param verbose
     * @ant.not-required Default to false.
     */
    public void setVerbose(boolean verbose) {
        this.verbose = verbose;
    }

    protected Blocks getBlocks() {
        if (blocks == null) {
            blocks = new Blocks();
            if (isVerbose()) {
                blocks.addOutputLineHandler(new AntStreamConsumer(this, Project.MSG_INFO));
            } else {
                blocks.addOutputLineHandler(new AntStreamConsumer(this, Project.MSG_DEBUG));
            }
            blocks.addErrorLineHandler(new AntStreamConsumer(this, Project.MSG_ERR));
        }
        return blocks;
    }

}
