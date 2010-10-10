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

import hidden.org.codehaus.plexus.interpolation.os.Os;

import java.io.File;
import java.io.IOException;

import org.apache.tools.ant.BuildException;

import com.nokia.helium.blocks.BlocksException;
import com.nokia.helium.blocks.Workspace;
import com.nokia.helium.blocks.ant.AbstractBlocksTask;
import com.nokia.helium.core.filesystem.windows.Subst;

/**
 * Get the workspace based on the a name or a directory. The task fails if it can't find the information.
 * 
 * This call will set the id of the workspace named myworkspace into the wsid property: 
 * <pre>
 * &lt;hlm:blocksGetWorkspaceId wsidoutput="wsid" name="myworkspace"/&gt; 
 * </pre>
 * 
 * @ant.task name="blocksGetWorkspaceId" category="Blocks"
 */
public class GetWorkspaceIdTask extends AbstractBlocksTask {
    
    private File dir;
    private String name;
    private String wsidoutput;
   
    /**
     * The directory to get the wsid.
     * @param dir the directory
     * @ant.not-required
     */
    public void setDir(File dir) {
        this.dir = dir;
    }

    /**
     * The name of the workspace to get the wsid.
     * @param name the name of a workspace
     * @ant.not-required
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * The name of the output property.
     * @param wsidoutput
     * @ant.required
     */
    public void setWsidoutput(String wsidoutput) {
        this.wsidoutput = wsidoutput;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void execute() {
        if ((dir == null && name == null) || (dir != null && name != null)) {
            throw new BuildException("You must define either name or dir attribute");
        }
        
        Workspace fw = null;
        try {
            File realDir = getRealDir();
            for (Workspace workspace : getBlocks().listWorkspaces()) {
                if (workspace.getLocation().getCanonicalFile().equals(realDir) || workspace.getName().equals(name)) {
                    fw = workspace;
                    break;
                }
            }
            if (fw != null) {
                log("Found matching workspace: " + fw.getWsid());
                if (wsidoutput != null) {
                    log("Setting property  " + wsidoutput);
                    getProject().setNewProperty(wsidoutput, "" + fw.getWsid());
                }
            }
        } catch (BlocksException exc) {
            throw new BuildException(exc);
        } catch (IOException exc) {
            throw new BuildException(exc);
        }
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
