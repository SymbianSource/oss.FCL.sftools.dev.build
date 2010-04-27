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
 * This object is used to check out a ccm project.
 *
 */
public class Checkout extends CcmCommand
{
    private String project;
    private String release;
    private String version;
    private String purpose;
    private String wa;
    private boolean recursive;
    private boolean relative;

    public String getProject()
    {
        return project;
    }

    public void setProject(String project)
    {
        this.project = project;
    }
    
    public String getRelease()
    {
        return release;
    }

    public void setRelease(String release)
    {
        this.release = release;
    }
    
    public String getVersion()
    {
        return version;
    }

    public void setVersion(String version)
    {
        this.version = version;
    }

    public String getPurpose()
    {
        return purpose;
    }

    public void setPurpose(String purpose)
    {
        this.purpose = purpose;
    }

    public String getWa()
    {
        return wa;
    }

    public void setWa(String wa)
    {
        this.wa = wa;
    }

    public boolean getRecursive()
    {
        return recursive;
    }

    public void setRecursive(boolean recursive)
    {
        this.recursive = recursive;
    }

    public boolean getRelative()
    {
        return relative;
    }

    public void setRelative(boolean relative)
    {
        this.relative = relative;
    }
}
