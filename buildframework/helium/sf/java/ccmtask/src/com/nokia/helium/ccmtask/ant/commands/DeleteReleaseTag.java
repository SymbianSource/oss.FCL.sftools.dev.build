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
 * This object contains info requred to delete the release tag.
 *
 */
public class DeleteReleaseTag extends CcmCommand
{
    
    private String newtag;
    
    private String release;
    
    private String purpose;
    
    private String project;

    /*
     * Helper function to get the project information for delete the new release tag.
     * @return the project used for creating new release tag.
     */
    public String getProject()
    {
        return project;
    }
    
    /*
     * Helper function to set the project information for delete the new release tag.
     * @param prj - project info to be set for deleting a new release tag.
     */
    public void setProject(String prj) {
        project = prj;
    }

    /*
     * Helper function to get the release information for delete the new release tag.
     * @param prj - project info to be set for deleting a new release tag.
     */
    public String getRelease()
    {
        return release;
    }

    /*
     * Helper function to set the release information for delete the new release tag.
     * @param rel - project info to be set for deleting a new release tag.
     */
    public void setRelease(String rel)
    {
        release = rel;
    }

    /**
     * Get the new release tag info.
     * @return newtag
     */
    public String getNewTag()
    {
        return newtag;
    }

    /**
     * Set the new release tag info.
     * @param tag - newtag information to be used to create the new release tag. 
     */
    public void setNewTag(String tag)
    {
        newtag = tag;
    }
}