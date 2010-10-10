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
package com.nokia.helium.blocks;

/**
 * This class represents information related to
 * a group. 
 *
 */
public class Group {
    private String name;

    /**
     * Create a new Group with a name.
     * @param name
     */
    public Group(String name) {
        this.name = name;
    }

    /**
     * Get the group name.
     * @return the group name as a string.
     */
    public String getName() {
        return name;
    }
    
}
