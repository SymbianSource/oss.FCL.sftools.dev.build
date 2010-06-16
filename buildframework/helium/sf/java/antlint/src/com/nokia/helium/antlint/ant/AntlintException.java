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
package com.nokia.helium.antlint.ant;

/**
 * Exception class for Antlint implementation
 * 
 */
public class AntlintException extends Exception {

    private static final long serialVersionUID = 3420280191500760182L;

    /**
     * Constructor.
     * 
     * @param message
     */
    public AntlintException(String message) {
        super(message);
    }

}
