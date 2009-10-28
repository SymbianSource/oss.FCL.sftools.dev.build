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

import java.util.Vector;
import com.nokia.ant.types.ccm.Task;

/**
 * This object creates new ccm task and contains all the Tasks in a list.
 *
 */
public class AddTask extends CcmCommand
{
    private String folder;
    private Vector tasks = new Vector();

    public String getFolder()
    {
        return folder;
    }

    public void setFolder(String folder)
    {
        this.folder = folder;
    }
    
    public Task createTask() {
        Task task = new Task();
        tasks.add(task);
        return task;
    }
    
    public Task[] getTasks() {
        Task[] result = new Task[tasks.size()];
        tasks.copyInto(result);
        return result;
    }
}
