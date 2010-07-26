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
package com.nokia.helium.ccmtask.ant.commands;

/**
 * This object is used to switch synergy role.
 *
 */
public class Role extends CcmCommand {
    private String role;

    /**
     * Set the role to switch to.
     * @param role
     */
    public void setRole(String role) {
        this.role = role;
    }

    /**
     * Get the role to switch to.
     * @return
     */
    public String getRole() {
        return role;
    }
    
}
