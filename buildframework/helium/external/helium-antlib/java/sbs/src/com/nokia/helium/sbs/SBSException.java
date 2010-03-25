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
package com.nokia.helium.sbs;

/**
 * Exception raise by the SBS Modules.
 *
 */
public class SBSException extends Exception {

    /**
     * An exception with message. 
     * @param message
     */
    public SBSException(String message) {
        super(message);
    }

    /**
     * An exception with message and cause.
     * @param message
     */
    public SBSException(String message, Throwable t) {
        super(message, t);
    }
    
}