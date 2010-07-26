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
 * This interface describe the methods a Mapped 
 * parameter must implement. 
 */
public interface MappedVariable extends Variable {

    /**
     * Get the name of the parameter.
     * @return the parameter name
     */
    String getName();
    
    /**
     * Get the value of the parameter 
     * @return the value.
     */
    String getValue();

}
