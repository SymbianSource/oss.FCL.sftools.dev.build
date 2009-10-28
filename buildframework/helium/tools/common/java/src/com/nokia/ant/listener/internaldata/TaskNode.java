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
 
package com.nokia.ant.listener.internaldata;

import org.apache.tools.ant.Task;
import java.util.Date;
/**
 * Object to set end time for a task.
 *
 */
public class TaskNode extends DataNode {

    private String name;

    // location
    private String filename;
    private int line = -1;

    public TaskNode(DataNode parent, Task task) {
        super(parent, task);
        this.setFilename(task.getLocation().getFileName());
        this.setLine(task.getLocation().getLineNumber());        
        name = task.getTaskName();
    }

    public String getName() {
        return name;
    } 

    public String getFilename() {
        return filename;
    }

    public void setFilename(String filename) {
        this.filename = filename;
    }

    public int getLine() {
        return line;
    }

    public void setLine(int line) {
        this.line = line;
    }

    public void setEndTime(Date endTime) {
        super.setEndTime(endTime);
        if ((endTime.getTime() - getStartTime().getTime() < 1000) && isEmpty() && getParent() != null) {
            getParent().remove(this);
        }
    }

}
