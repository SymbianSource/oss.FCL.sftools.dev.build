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
 
package com.nokia.ant.types.ccm;

import org.apache.tools.ant.types.DataType;

/**
 * This class abstract a synergy session.
 * It store the address to an already existing session. 
 */
public class Task extends DataType {
    // store the ccm_addr value
    private String name;
    
    /**
     * Sets the synergy address.
     * @param name string representing the ccm_addr
     */
    public void setName(String name) {
        this.name = name;
    }
    
    /**
     * Get the synergy address.
     * @return string representing the ccm_addr
     */
    public String getName() {
        return name;
    }
}

