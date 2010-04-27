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
 
package com.nokia.ant.taskdefs.ccm.commands;

/**
 * This object contains the current release tag.
 *
 */
public class ChangeReleaseTag extends CcmCommand
{
    private String folder;
    private String newreleasetag;
    
    
    public String getFolder()
    {
        return folder;
    }

    public void setFolder(String folder)
    {
        this.folder = folder;
    }
    
    public String getReleaseTag()
    {
        return newreleasetag;
    }

    public void setReleasetag(String newreleasetag)
    {
        this.newreleasetag = newreleasetag;
    }

}
