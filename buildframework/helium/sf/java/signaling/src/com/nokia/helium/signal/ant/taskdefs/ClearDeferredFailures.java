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


package com.nokia.helium.signal.ant.taskdefs;

import org.apache.tools.ant.Task;
import com.nokia.helium.signal.SignalStatusList;

/**
 * This class implements a task that clear all pending failure. It is quite
 * useful for testing.
 * @ant.task name="clearDeferredFailures" category="Signaling"
 */
public class ClearDeferredFailures extends Task {

    /**
     * Does the cleaning.
     */
    @Override
    public void execute() {
        log("Clearing all pending failures.");
        SignalStatusList.getDeferredSignalList().clearStatusList();
    }

}
