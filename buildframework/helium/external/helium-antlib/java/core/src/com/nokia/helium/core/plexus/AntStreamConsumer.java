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
package com.nokia.helium.core.plexus;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.codehaus.plexus.util.cli.StreamConsumer;

/**
 * Handle the output lines and redirect them to Ant logging.
 * The logging level is configurable.
 *
 */
public class AntStreamConsumer implements StreamConsumer {

    private Task task;
    private int level = Project.MSG_INFO;
    
    /**
     * Initialize the consumer with the task that will be used to 
     * redirect the consumed lines. Default logging level will be 
     * Project.MSG_INFO.
     * @param task an Ant task
     */
    public AntStreamConsumer(Task task) {
        this.task = task;
    }

    /**
     * Initialize the consumer with the task that will be used to 
     * redirect the consumed lines, and the level of logging.
     * @param task ant Ant task.
     * @param level ant logging level to use.
     */
    public AntStreamConsumer(Task task, int level) {
        this.task = task;
        this.level = level;
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void consumeLine(String line) {
        task.log(line, level);
    }

}
