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
package com.nokia.helium.antlint.ant;

import java.io.File;

import org.apache.tools.ant.Task;

/**
 * To report the antlint errors into antlint task.
 */

public interface Reporter {

    /**
     * Open the reporting session.
     * Ant attribute validation should preferably
     * happen here.
     * 
     */
    void open();

    /**
     * Closing the reporting session.
     */
    void close();
    
    /**
     * To report the errors into antlint task.
     * 
     * @param severity
     * @param message
     * @param filename
     * @param lineNo
     */
    void report(Severity severity, String message, File filename, int lineNo);

    /**
     * To set the task calling reporter.
     * 
     * @param task
     */
    void setTask(Task task);

}
