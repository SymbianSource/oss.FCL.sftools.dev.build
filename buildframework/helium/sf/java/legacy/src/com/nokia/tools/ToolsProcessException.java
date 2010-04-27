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


package com.nokia.tools;

/**
 * Exception handling for command line tool wrapper 
 */
public class ToolsProcessException extends Exception {

    private static final long serialVersionUID = 4033843732177214806L;

    /**
     * Constructor
     * @param message exception message
     */    
    public ToolsProcessException(String message) {
        super("ToolsProcessException: " + message);
    }
}