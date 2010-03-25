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

package com.nokia.helium.signal.ant.types;

import com.nokia.helium.signal.Notifier;
import org.apache.tools.ant.types.DataType;
import org.apache.log4j.Logger;
import java.util.List;
import java.io.File;

/**
 * The InfoNotifier provides you an easy way to inform the
 * user about the log file where the build failed.
 * @ant.type name="infoNotifier" category="Signaling"
 */
public class InfoNotifier extends DataType implements Notifier {

    private Logger log = Logger.getLogger(InfoNotifier.class);
    /**
     * Rendering the template, and sending the result through email.
     * @deprecated
     * @param signalName
     *            - Name of the signal that has been raised.
     */
    @SuppressWarnings("unchecked")
    public void sendData(String signalName, boolean failStatus,
            List<String> fileList) {
    }
    
    /**
     * Rendering the template, and sending the result through email.
     * 
     * @param signalName - is the name of the signal that has been raised.
     * @param failStatus - indicates whether to fail the build or not
     * @param notifierInput - contains signal notifier info
     * @param message - is the message from the signal that has been raised. 
     */

    @SuppressWarnings("unchecked")
    public void sendData(String signalName, boolean failStatus,
            NotifierInput notifierInput, String message ) {
        File logFile = notifierInput.getFile(".*.log");
        log.error("Error in log file: " + logFile);
    }
}