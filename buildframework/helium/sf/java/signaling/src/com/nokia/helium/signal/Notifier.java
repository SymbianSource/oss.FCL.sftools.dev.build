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


package com.nokia.helium.signal;

import java.util.List;
import org.apache.tools.ant.Project;
import com.nokia.helium.signal.ant.types.NotifierInput;

/**
 * This interface describe what method a Notifier needs to implement.
 * 
 */
public interface Notifier {

    /**
     * Setting the project.
     * 
     * @param project
     */
    void setProject(Project project);

    /**
     * Sends the data to the requested sender list with specified notifier
     * 
     * @param signalName is the name of the signal that has been raised.
     * @param failStatus indicates whether to fail the build or not
     * @param notifierInput contains signal notifier info
     * @param message is the message from the signal that has been raised.           
     */
    void sendData(String signalName, boolean failStatus,
            NotifierInput notifierInput, String message );

    /**
     * Sends the data to the requested sender list with specified notifier
     * 
     * @deprecated
     */    
    void sendData(String signalName, boolean failStatus,
            List<String> fileList);
}