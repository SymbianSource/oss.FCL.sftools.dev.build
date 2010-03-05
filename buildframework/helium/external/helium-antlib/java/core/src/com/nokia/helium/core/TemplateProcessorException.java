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
 * Template Exception handler.
 * 
 */
public class TemplateProcessorException extends RuntimeException {
    
    private static final long serialVersionUID = 1L;

    /**
     * Default constructor.
     * @param message the error message.
     */
    public TemplateProcessorException(String message) {
        super(message);
    }
}