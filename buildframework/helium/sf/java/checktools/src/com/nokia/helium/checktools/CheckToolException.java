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
package com.nokia.helium.checktools;

/**
 * CheckToolException is a runtime exception used to indicate an error or a
 * failure occurred during checking of tools required by the Helium.
 * 
 */
public class CheckToolException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    /**
     * Create an instance of CheckToolException.
     * 
     * @param message
     *            is the failure message.
     */
    public CheckToolException(String message) {
        super(message);
    }

    /**
     * Create an instance of CheckToolException.
     * 
     * @param th
     *            is the actual error thrown.
     */
    public CheckToolException(Throwable th) {
        super(th);
    }
}
