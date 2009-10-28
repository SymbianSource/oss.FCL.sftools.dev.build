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

import com.nokia.ant.taskdefs.CcmTask;

/**
 * Creates command string based on runtime class name.
 *
 */
public class CcmCommand
{
    private CcmTask task;

    /**
     * @return the task
     */
    public CcmTask getTask()
    {
        return task;
    }

    /**
     * @param task
     *            the task to set
     */
    public void setTask(CcmTask task)
    {
        this.task = task;
    }
    
    
    public String getName()
    {
        String className = getClass().getName();
        String commandName = className.substring(className.lastIndexOf('.') + 1).toLowerCase();
        return commandName;
    }
}
