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
package com.nokia.helium.blocks;

/**
 * Exception thrown by the Bundle manipulation framework.
 *
 */
public class BundleException extends Exception {

    private static final long serialVersionUID = 1L;

    /**
     * Default constructor.
     * @param error the error message.
     */
    public BundleException(String error) {
        super(error);
    }

    /**
     * Constructor which accept a message and a cause.
     * @param error the error message.
     */
    public BundleException(String message, Throwable t) {
        super(message, t);
    }
}