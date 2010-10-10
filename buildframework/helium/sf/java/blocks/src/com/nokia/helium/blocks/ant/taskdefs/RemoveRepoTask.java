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
 * Remove a repository from a workspace.
 * 
 * The repository named &quot;my-repository-name&quot; will be removed from workspace 1:
 * <pre>
 * &lt;hlm:blocksRemoveRepository wsid=&quot;1&quot; name=&quot;my-repository-name&quot; /&gt; 
 * </pre>

 * The repository 1 will be removed from workspace 1:
 * <pre>
 * &lt;hlm:blocksRemoveRepository wsid=&quot;1&quot; repositoryId=&quot;1&quot; /&gt; 
 * </pre>
 * 
 * @ant.task name="blocksRemoveRepository" category="Blocks"
 */
public class RemoveRepoTask extends AbstractBlocksTask {
    private Integer repositoryId;
    private String name;

    /**
     * Remove the repository using its id. 
     * workspace.
     * @param repositoryId the repository id
     * @ant.required
     */
    public void setRepositoryId(Integer repositoryId) {
        this.repositoryId = repositoryId;
    }

    /**
     * Remove the repository using its name. 
     * workspace.
     * @param name the repository name
     * @ant.not-required
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * {@inheritDoc}
     */
    public void execute() {
        if (repositoryId == null && name == null) {
            throw new BuildException("Either 'repositoryId' or 'name' attribute must be defined.");            
        }
        if (repositoryId != null && name != null) {
            throw new BuildException("'repositoryId' and 'name' attribute cannot be defined at the same time.");            
        }
        try {
            if (name != null) {
                getBlocks().removeRepository(getWsid(), name);
                log("The repository " + name + " has been removed successfully from workspace " + getWsid() + ".");
            } else {
                getBlocks().removeRepository(getWsid(), repositoryId.intValue());
                log("The repository " + repositoryId + " has been removed successfully from workspace " + getWsid() + ".");
            }
        } catch (BlocksException e) {
            throw new BuildException(e.getMessage(), e);
        }
    }
    

}
