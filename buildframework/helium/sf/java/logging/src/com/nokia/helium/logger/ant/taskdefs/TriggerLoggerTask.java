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
import com.nokia.helium.logger.ant.listener.CommonListener;

/**
 * This task is used to start the helium logging listener.
 * @ant.task name="triggerlogger" category="Logging"
 */
public class TriggerLoggerTask extends Task {
    
    
    public void execute() {
        log("Registering Ant logging to StatusAndLogListener listener", Project.MSG_DEBUG);
        if (CommonListener.getCommonListener() == null) {
            this.log("The CommonListener is not available.", Project.MSG_WARN);
            return;
        }
        AntLoggingHandler handler = CommonListener.getCommonListener().getHandler(AntLoggingHandler.class);
        if (handler != null) {
            log("Starting logging framework.", Project.MSG_DEBUG);
            handler.setRecordState(true);
        } else {
            log("Could not find the logging listener.", Project.MSG_WARN);
        }
    }

}
