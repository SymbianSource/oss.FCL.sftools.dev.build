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

package com.nokia.helium.signal.ant;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.ant.HlmExceptionHandler;

/**
 * Class to check the signal is present in the deferred and now signal list.
 * Print the message on the shell "Build completed with errors and warnings".
 * 
 */

public class SignalExceptionMessage extends DataType implements
        HlmExceptionHandler {

    /**
     * Implements the Exception method to print the build completed message.
     * 
     * @param project
     * @param module
     * @param e
     */
    public void handleException(Project project, Exception e) {
        if (!Signals.getSignals().getDeferredSignalList().isEmpty()
                || !Signals.getSignals().getNowSignalList().isEmpty()) {
            log("Build completed with errors and warnings.", Project.MSG_WARN);
        }
    }
}