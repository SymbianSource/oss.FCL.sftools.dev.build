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
 * This object is used to reconcile a ccm project.
 *
 */
public class Reconcile extends CcmCommand
{
    private String project;

    /**
     * Get the project to reconcile.
     * @return
     */
    public String getProject()
    {
        return project;
    }

    /**
     * Set the project to reconcile.
     * @param project
     */
    public void setProject(String project)
    {
        this.project = project;
    }
}
