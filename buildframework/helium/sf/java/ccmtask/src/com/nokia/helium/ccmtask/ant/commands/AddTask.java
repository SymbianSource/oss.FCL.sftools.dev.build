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

import java.util.Vector;

import com.nokia.helium.ccmtask.ant.types.Task;

/**
 * This object creates new ccm task and contains all the Tasks in a list.
 *
 */
public class AddTask extends CcmCommand
{
    private String folder;
    private Vector<Task> tasks = new Vector<Task>();

    /**
     * Get the dest folder.
     * @return the dest folder, or null if not defined.
     */
    public String getFolder()
    {
        return folder;
    }

    /**
     * Define the folder to add the task in.
     * @param folder
     */
    public void setFolder(String folder)
    {
        this.folder = folder;
    }
    
    /**
     * Add a nested task element.
     * @return a Task element
     */
    public Task createTask() {
        Task task = new Task();
        tasks.add(task);
        return task;
    }
    
    /**
     * Get all nested tasks
     * @return an array of nested tasks
     */
    public Task[] getTasks() {
        return tasks.toArray(new Task[tasks.size()]);
    }
}
