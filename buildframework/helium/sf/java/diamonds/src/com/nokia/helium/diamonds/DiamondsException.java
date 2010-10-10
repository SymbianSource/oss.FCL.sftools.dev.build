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


package com.nokia.helium.diamonds;

/**
 * Exception class for Diamonds implementation
 * 
 */
public class DiamondsException extends Exception {

    private static final long serialVersionUID = 8743300713686555395L;

    /**
     * Diamonds exception with error message.
     * @param message the error message.
     */
    public DiamondsException(String message) {
        super(message);
    }

    /**
     * Diamonds exception with error message and a root cause
     * @param message the error message
     * @param cause the root cause
     */
    public DiamondsException(String message, Throwable cause) {
        super(message, cause);
    }
}