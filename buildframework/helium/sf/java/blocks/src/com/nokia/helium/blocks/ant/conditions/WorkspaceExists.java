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
package com.nokia.helium.blocks.ant.conditions;

import hidden.org.codehaus.plexus.interpolation.os.Os;

import java.io.File;
import java.io.IOException;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.taskdefs.condition.Condition;

import com.nokia.helium.blocks.Blocks;
import com.nokia.helium.blocks.BlocksException;
import com.nokia.helium.blocks.Workspace;
import com.nokia.helium.blocks.ant.AbstractBlocksTask;
import com.nokia.helium.core.filesystem.windows.Subst;

/**
 * The blocksWorkspaceExists condition help you to check the existence of a workspace  
 * based on his name or location.
 * 
 * In the following example the property 'exists' is set if the blocks workspace named 'workspace_name' exists:
 * <pre>
 * &lt;condition property="exists" &gt;
 *     &lt;hlm:blocksWorkspaceExists  name="workspace_name" /&gt;
 * &lt;/condition&gt;
 * </pre>
 * 
 * @ant.type name="blocksWorkspaceExists" category="Blocks"
 */
public class WorkspaceExists extends AbstractBlocksTask implements Condition {
    
    private File dir;
    private String name;
    
    /**
     * The directory of the workspace to check the existence.
     * @param dir
     * @ant.not-required
     */
    public void setDir(File dir) {
        this.dir = dir;
    }

    /**
     * The name of the workspace to check the existence.
     * @param name
     * @ant.not-required
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public boolean eval() {
        if (dir == null && name == null) {
            throw new BuildException("Either name or dir should be defined.");
        }
        if (dir != null && name != null) {
            throw new BuildException("name or dir should not be defined at the same time.");
        }
        
        Blocks blocks = getBlocks();
        try {
            for (Workspace workspace : blocks.listWorkspaces()) {
                if (dir != null && getRealDir().equals(workspace.getLocation().getCanonicalFile())) {
                    return true;
                }
                if (name != null && name.equals(workspace.getName())) {
                    return true;
                }
            }
        } catch (BlocksException e) {
            throw new BuildException(e);
        } catch (IOException e) {
            throw new BuildException(e);
        }
        return false;
    }
    
    /**
     * Solve subst drives on windows.
     * @return the realpath.
     * @throws IOException
     */
    protected File getRealDir() throws IOException {
        if (Os.isFamily(Os.FAMILY_WINDOWS) && dir != null) {
            Subst subst = new Subst();
            log("Real path: " + subst.getRealPath(dir).getCanonicalFile());
            return subst.getRealPath(dir).getCanonicalFile();            
        }        
        return dir != null ? dir.getCanonicalFile() : null;
    }        
}
