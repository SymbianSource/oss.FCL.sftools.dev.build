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


package com.nokia.helium.core;

/**
 * Exception class for Message creation implementation
 * 
 */
public class MessageCreationException extends Exception {
    private static final long serialVersionUID = 330899302955104898L;

    /**
     * Create a MessageCreationException with an error message
     * @param message the error message.
     */
    public MessageCreationException(String message) {
        super("Message Creation Error: " + message);
    }

    /**
     * Creating a MessageCreationException with a message and a cause.
     * @param message the message
     * @param cause the root cause
     */
    public MessageCreationException(String message, Throwable cause) {
        super("Message Creation Error: " + message, cause);
    }
}