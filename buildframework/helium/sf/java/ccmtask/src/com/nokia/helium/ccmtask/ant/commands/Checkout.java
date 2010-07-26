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

    /**
     * Get the project to checkout.
     * @return
     */
    public String getProject()
    {
        return project;
    }

    /**
     * Set the project to checkout.
     * @return the project four part name
     */
    public void setProject(String project)
    {
        this.project = project;
    }
    
    /**
     * Get the release to use for the checkout.
     * @return
     */
    public String getRelease()
    {
        return release;
    }

    /**
     * Set the release to use for the checkout.
     * @return the release
     */
    public void setRelease(String release)
    {
        this.release = release;
    }
    
    /**
     * Get the version to set while checking out.
     * @return
     */
    public String getVersion()
    {
        return version;
    }

    /**
     * Set the version
     * @param version
     */
    public void setVersion(String version)
    {
        this.version = version;
    }

    /**
     * Get the purpose of the checkout
     */
    public String getPurpose()
    {
        return purpose;
    }

    /**
     * Set the purpose of the checkout
     * @param purpose
     */
    public void setPurpose(String purpose)
    {
        this.purpose = purpose;
    }

    /**
     * Get the workarea location
     * @return
     */
    public String getWa()
    {
        return wa;
    }

    /**
     * Set the workarea location
     * @param wa
     */
    public void setWa(String wa)
    {
        this.wa = wa;
    }

    /**
     * Shall it be a recursive checkout
     * @return
     */
    public boolean getRecursive()
    {
        return recursive;
    }

    /**
     * Set if the checkout should be a recursive.
     * @param recursive
     */
    public void setRecursive(boolean recursive)
    {
        this.recursive = recursive;
    }

    /**
     * Shall subprojects workarea be maintained relatively to the parent.
     * @return
     */
    public boolean getRelative()
    {
        return relative;
    }

    /**
     * Set if the subprojects workarea be maintained relatively to the parent.
     * @param relative
     */
    public void setRelative(boolean relative)
    {
        this.relative = relative;
    }
}
