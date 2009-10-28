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
 * HlmAntlib exception handling class
 */
public class HlmAntLibException extends RuntimeException {

    private static final long serialVersionUID = -2504337723465536053L;

    /**
     * Constructor
     * 
     * @param String
     *            exception message
     */
    public HlmAntLibException(String msg) {
        super("HlmAntLibException:generic:" + msg);
    }

    /**
     * Constructor
     * 
     * @param String
     *            module which throws the exception
     * @param String
     *            exception message
     */
    public HlmAntLibException(String module, String msg) {
        super("HlmAntLibException:" + module + ":" + msg);
    }
}