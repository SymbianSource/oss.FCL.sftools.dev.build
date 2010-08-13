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
 
package com.nokia.helium.ccmtask.ant.types;

import java.util.Vector;

import org.apache.tools.ant.types.DataType;

/**
 * This class abstract a synergy session.
 * It store the address to an already existing session. 
 */
public class TaskSet extends DataType {
    // store the Task objects
    private Vector<Task> tasks = new Vector<Task>();
    
    /**
     * Create and register a Session object. 
     * @return a Session object.
     */
    public Task createTask() {
        Task task = new Task();
        tasks.add(task);
        return task;
    }
    
    /**
     * Returns an array of Session object.
     * @returns an array of Session object
     */
    public Task[] getSessions() {
        Task[] result = new Task[tasks.size()];
        tasks.copyInto(result);
        return result; 
    }
}

