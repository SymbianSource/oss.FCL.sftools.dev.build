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
* Description:To print the message on the shell in case of build fails for deffered Signals. 
*
*/
 
package com.nokia.helium.signal;


import org.apache.tools.ant.Project;
import com.nokia.helium.core.ant.HlmExceptionHandler;
import org.apache.log4j.Logger;

/**
 * Class to check the signal is present in the deferred and now signal list.
 * Print the message on the shell "Build completed with errors and warnings".
 * 
 */

public class SignalExceptionMessage implements HlmExceptionHandler {
    private Logger log = Logger.getLogger(SignalExceptionMessage.class);
    
    /**
     * Implements the Exception method to print the build completed message.
     * @param project
     * @param module
     * @param e
     */
    public void handleException(Project project, String module, Exception e) {
        
        if (SignalStatusList.getDeferredSignalList().hasSignalInList()) {
            log.info("Build completed with errors and warnings.");
        }
        
        if (SignalStatusList.getNowSignalList().hasSignalInList()) {
            log.info("Build completed with errors and warnings.");
        }
    }
}