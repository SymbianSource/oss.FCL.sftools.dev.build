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
 * This object contains the current release tag.
 *
 */
public class ChangeReleaseTag extends CcmCommand
{
    private String folder;
    private String newreleasetag;
    
    /**
     * Get the folder to scan.
     * @return the folder, or null if not defined.
     */
    public String getFolder()
    {
        return folder;
    }

    /**
     * Set the folder to update the task.
     * @param folder
     */
    public void setFolder(String folder)
    {
        this.folder = folder;
    }
    
    /**
     * Get the release to re-tag the tasks with.
     * @param newreleasetag
     */
    public String getReleaseTag()
    {
        return newreleasetag;
    }

    /**
     * Set the release to re-tag the tasks with.
     * @param newreleasetag
     */
    public void setReleasetag(String newreleasetag)
    {
        this.newreleasetag = newreleasetag;
    }

}
