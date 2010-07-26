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
     * Constructor
     * 
     * @exception - exception to be processed.
     */

    public DiamondsException(String exception) {
        super(exception);
    }
}