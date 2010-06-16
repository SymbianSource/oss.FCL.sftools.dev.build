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
 
package com.nokia.helium.core.ant;

/**
 * This interface describe the methods a command line variable
 * must implement.
 */
public interface Variable
{
    
    /**
     * Get the command line parameter. It uses '=' character as the default
     * separator.
     * @return the parameter as a command line string
     */
    String getParameter();

    /**
     * Get the command line parameter. Use custom parameter for joining
     * the mapped parameters.
     * @param separator mapped value separator
     * @return the parameter as a command line string
     */
    String getParameter(String separator);

}