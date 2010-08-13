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
 * LogSource exception handling class
 */
public class LogSourceException extends Exception {


    /**
     * Constructor
     * 
     * @param String
     *            exception message
     */
    public LogSourceException(String exception) {
        super(exception);
    }

}