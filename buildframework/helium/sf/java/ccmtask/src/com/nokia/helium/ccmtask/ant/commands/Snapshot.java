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
 
package com.nokia.helium.ccmtask.ant.commands;

/**
 * This object is used to snap shot a ccm project.
 *
 */
public class Snapshot extends CcmCommand
{
    private String project;
    private String dir;
    private boolean recursive;
    private boolean fast;

    /**
     * Get the project to snapshot.
     * @return
     */
    public String getProject()
    {
        return project;
    }

    /**
     * Set the project to snapshot.
     * @param project
     */
    public void setProject(String project)
    {
        this.project = project;
    }
    
    /**
     * Get the location where to snapshot
     * @return
     */
    public String getDir()
    {
        return dir;
    }

    /**
     * Set the location where to snapshot
     * @param dir
     */
    public void setDir(String dir)
    {
        this.dir = dir;
    }
    
    /**
     * Shall  sub-projects be snapshotted?
     * @return
     */
    public boolean getRecursive()
    {
        return recursive;
    }

    /**
     * Set if sub-projects should be snapshotted.
     * @return
     */
    public void setRecursive(boolean recursive)
    {
        this.recursive = recursive;
    }
    
    /**
     * Shall multi-threaded snapshot be used.?
     * @return
     */
    public boolean getFast()
    {
        return fast;
    }

    /**
     * Set if multi-threaded snapshot should be used.
     * @param fast
     */
    public void setFast(boolean fast)
    {
        this.fast = fast;
    }
}
