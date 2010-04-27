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

import java.util.Vector;

import org.apache.log4j.Logger;

/**
 * This class implements at storage for SignalStatus object.
 * It cannot be instantiated, it must be used through the typed list:
 * getDeferredSignalList, getNowSignalList, getNeverSignalList
 *
 */
public final class SignalStatusList {
    
    private static SignalStatusList deferSignalList = new SignalStatusList();
    private static SignalStatusList nowSignalList = new SignalStatusList();
    private static SignalStatusList neverSignalList = new SignalStatusList();

    private Vector<SignalStatus> signals = new Vector<SignalStatus>();
    
    private Logger log = Logger.getLogger(this.getClass());
    
    
    private SignalStatusList() { }
    
    /**
     * Get the list of stored SignalStatus object.
     * @return a Vector of SignalStatus instances.
     */
    public Vector<SignalStatus>getSignalStatusList() {
        return new Vector<SignalStatus>(signals);
    }
    
    /**
     * Add a SignalStatus object to the list.
     * 
     * @param status
     *            a signal
     */
    public void addSignalStatus(SignalStatus status) {
        log.debug("SignalStatusList:addSignalStatus:msg:" + status);
        signals.add(status);
    }

    /**
     * Converts the error list into a user readable message.
     * 
     * @return the error message.
     */
    public String getErrorMsg() {
        StringBuffer statusBuffer = new StringBuffer();
        for (SignalStatus signalStatus : signals) {
            statusBuffer.append(signalStatus);
            statusBuffer.append("\n");
        }
        log.debug("getErrorMsg:msg:" + statusBuffer.toString());
        return statusBuffer.toString();
    }

    /**
     * Check if it has any pending signals stored.
     * 
     * @return true if any signal are pending.
     */
    public boolean hasSignalInList() {
        log.debug("asDeferMsgInList:size:"
                + signals.size());
        return signals.size() > 0;
    }

    /**
     * Clear all deferred signals.
     */
    public void clearStatusList() {
        log.debug("clearStatusList:size1:"
                + signals.size());
        signals.clear();
        log.debug("clearStatusList:size2:"
                + signals.size());
    }
    
    /*
     * Returns the deferred signal list.
     */
    public static SignalStatusList getDeferredSignalList() {
        return deferSignalList;
    }
    
    /*
     * Returns the now signal list.
     */
    public static SignalStatusList getNowSignalList() {
        return nowSignalList;
    }
    
    /*
     * Returns the never signal list.
     */
    public static SignalStatusList getNeverSignalList() {
        return neverSignalList;
    }

}
