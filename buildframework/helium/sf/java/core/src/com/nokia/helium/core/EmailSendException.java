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
 * Email sending exception handling class
 */
public class EmailSendException extends Exception {

    private static final long serialVersionUID = 7997902958106522082L;

    /**
     * Constructor
     * 
     * @param String
     *            exception message
     */
    public EmailSendException(String exception) {
        super(exception);
    }

    public EmailSendException(String exception, Throwable cause) {
        super(exception, cause);
    }
}