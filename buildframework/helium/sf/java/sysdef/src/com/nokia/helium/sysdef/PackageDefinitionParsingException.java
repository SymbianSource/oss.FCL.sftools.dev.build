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
package com.nokia.helium.sysdef;

/**
 * Exception thown by the PackageMap class while
 * parsing a file.
 *
 */
public class PackageDefinitionParsingException extends Exception {

    private static final long serialVersionUID = 6940770114328037199L;

    /**
     * Exception with error message.
     * @param message the error message
     */
    public PackageDefinitionParsingException(String message) {
        super(message);
    }
    
    /**
     * Exception with an error message and a root cause.
     * @param message the error message
     * @param cause the root cause
     */
    public PackageDefinitionParsingException(String message, Throwable cause) {
        super(message, cause);
    }
}
