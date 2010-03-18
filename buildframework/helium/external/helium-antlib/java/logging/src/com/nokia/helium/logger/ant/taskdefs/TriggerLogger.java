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
package com.nokia.helium.logger.ant.taskdefs;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;

import com.nokia.helium.logger.ant.listener.AntLoggingHandler;
import com.nokia.helium.logger.ant.listener.StatusAndLogListener;
import org.apache.log4j.Logger;

/**
 * This task is used to start the helium logging listener.
 * @ant.task name="triggerlogger" category="Logging"
 */
public class TriggerLogger extends Task {
    
    private Logger log = Logger.getLogger(TriggerLogger.class);
    
    public void execute() {
        log.debug("Registering Ant logging to StatusAndLogListener listener");
        if (StatusAndLogListener.getStatusAndLogListener() == null) {
            this.log("The StatusAndLogListener is not available.", Project.MSG_WARN);
            return;
        }
        AntLoggingHandler antLoggingHandler = (AntLoggingHandler)StatusAndLogListener.getStatusAndLogListener().getHandler(AntLoggingHandler.class);
        if (antLoggingHandler != null ) {
            if (!antLoggingHandler.getLoggingStarted()) {
                log.debug("Starting Logging using 'AntLoggingHandler' first time.");
                antLoggingHandler.setLoggingStarted(true);
            } else {
                log.debug("'AntLoggingHandler' is already started logging.");
            }
        } else {
            log.debug("Could not find the AntLoggingHandler instance.");
        }
    }

}
