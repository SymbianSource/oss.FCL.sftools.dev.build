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

import java.util.Date;

/**
 * Signal data holder;
 */
public class SignalStatus {

    // Signal attributes.
    private String name;
    private String message;
    private String targetName;
    private Date signalTimeStamp;

    /**
     * Deferred signal holder.
     * 
     * @param signalName
     *            name of the signal been raised
     * @param message
     *            message for the user
     * @param targetName
     *            current target.
     */
    public SignalStatus(String signalName, String message, String targetName, Date signalDateAndTime) {
        this.name = signalName;
        this.message = message;
        this.targetName = targetName;
        this.signalTimeStamp = signalDateAndTime;
        
    }
    /**
     * Returns the signal message.
     * @return
     */
    public String getMessage() {
        return message;
    }

    /**
     * Returns signal name.
     * @return
     */
    public String getName() {
        return name;
    }

    /**
     * Returns target name.
     * @return
     */
    public String getTargetName() {
        return targetName;
    }
    
    /**
     * Returns signal date and time.
     * @return
     */
    public Date getTimestamp() {
        return signalTimeStamp;
    }
    
    /**
     * Converts signal status object to string.
     */
    public String toString() {
        return name + ": " + message + " : " + targetName;
    }
}