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
package com.nokia.helium.imaker;

/**
 * Exception raise by the iMaker framework.
 *
 */
public class IMakerException extends Exception {

    private static final long serialVersionUID = -6918895304070211899L;

    /**
     * An exception with message. 
     * @param message
     */
    public IMakerException(String message) {
        super(message);
    }

    /**
     * An exception with message and cause.
     * @param message
     */
    public IMakerException(String message, Throwable t) {
        super(message, t);
    }
    
}
