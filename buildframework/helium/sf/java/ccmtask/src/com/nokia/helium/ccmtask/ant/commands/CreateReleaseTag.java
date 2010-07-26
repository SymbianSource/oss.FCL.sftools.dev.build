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
 * This object stores the new releast tag creation information.
 *
 */
public class CreateReleaseTag extends CcmCommand
{
    private String newtag;
    
    private String release;
    
    private String project;
    
    public String getProject()
    {
        return project;
    }
    
    /*
     * Helper function to set the project information for creating the new release.
     * @param prj - project info to be set for creating a new release tag.
     */
    public void setProject(String prj) {
        project = prj;
    }

    /*
     * Helper function to get the release information for creating the new release tag.
     * @return  - release info to be used to create the new release tag.
     */
    public String getRelease()
    {
        return release;
    }

    /*
     * Helper function to set the release information for creating the new release tag.
     * @param rel  - release info to be used to create the new release tag.
     */
    public void setRelease(String rel)
    {
        release = rel;
    }

    /**
     * Get the release tag to be created.
     * @return newreleasetag to create it.
     */
    public String getNewTag()
    {
        return newtag;
    }

    /**
     * Set the new release tag to be used. 
     * @param newtag
     */
    public void setNewTag(String tag)
    {
        newtag = tag;
    }
}