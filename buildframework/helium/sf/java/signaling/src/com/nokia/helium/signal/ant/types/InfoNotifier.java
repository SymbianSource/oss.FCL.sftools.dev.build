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

import java.io.File;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.types.ResourceCollection;

import com.nokia.helium.core.ant.ResourceCollectionUtils;
import com.nokia.helium.signal.ant.Notifier;

/**
 * The InfoNotifier provides you an easy way to inform the
 * user about the log file where the build failed.
 * @ant.type name="infoNotifier" category="Signaling"
 */
public class InfoNotifier extends DataType implements Notifier {
    
    /**
     * {@inheritDoc}
     */
    public void sendData(String signalName, boolean failStatus,
            ResourceCollection notifierInput, String message ) {
        if (notifierInput != null) {
            File logFile = ResourceCollectionUtils.getFile(notifierInput, ".*.log");
            log("Error in log file: " + logFile, Project.MSG_ERR);
        }
    }
}