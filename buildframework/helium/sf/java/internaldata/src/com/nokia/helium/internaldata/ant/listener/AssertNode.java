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
 
package com.nokia.helium.internaldata.ant.listener;

//import com.nokia.ant.taskdefs.HlmAssertMessage;
import com.nokia.helium.internaldata.ant.taskdefs.HlmAssertMessage;
/**
 * Object to set end time for a task.
 *
 */
public class AssertNode extends DataNode {

    private String name;
    
    
    // location
    private String filename;
    private String message;
    private int line = -1;
    private String assertName;
    
     public AssertNode(DataNode parent, HlmAssertMessage task) {
        super(parent, task);
        name = task.getTaskName();
        this.setFilename(task.getLocation().getFileName());
        this.setLine(task.getLocation().getLineNumber());
        message = task.getMessage();
        assertName = task.getAssertName();
    }
    /**
     * Return the assert message
     * @return
     */
     public String getMessage() {
        return message;
    }
    /**
     * Return the assert task name.
     * @return
     */
    public String getName() {
        return name;
    } 
    /**
     * Return the assert name.
     * @return
     */
    public String getAssertName() 
    {
        return assertName;
    }
    /**
     * Return the path to file name.
     * @return
     */
    public String getFilename() {
        return filename;
    }
    /**
     * Sets the path to file name.
     * @param filename
     */
    public void setFilename(String filename) {
        this.filename = filename;
    }
    /**
     * Return the line number.
     * @return
     */
    public int getLine() {
        return line;
    }
    /**
     * Sets the line number.
     * @param line
     */
    public void setLine(int line) {
        this.line = line;
    }

}
