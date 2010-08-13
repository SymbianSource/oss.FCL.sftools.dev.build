/*
 * Copyright (c) 2010-2011 Nokia Corporation and/or its subsidiary(-ies).
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
 * Exception occuring during LDAP search.
 *  
 */
public class LDAPException extends Exception {

    private static final long serialVersionUID = -4843665216704377558L;

    /**
     * Create an exception with a message.
     * @param message the error message
     */
    public LDAPException(String message) {
        super(message);
    }

    /**
     * Create an exception with a message and a root cause.
     * @param message the error message
     * @param cause the root cause
     */
    public LDAPException(String message, Throwable cause) {
        super(message, cause);
    }
}
