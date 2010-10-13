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

import java.io.File;

/**
 * Holder for workspace information:
 *  - ID
 *  - Name
 *  - Location
 *
 */
public class Workspace {
    private int wsid;
    private String name;
    private File location;
    
    
    /**
     * Get the workspace id.
     * @return the workspace id.
     */
    public int getWsid() {
        return wsid;
    }
    
    /**
     * Set the workspace id. 
     * @param wsid the workspace id
     */
    public void setWsid(int wsid) {
        this.wsid = wsid;
    }
    
    /**
     * Get the workspace name.
     * @return the workspace name
     */
    public String getName() {
        return name;
    }
    
    /**
     * Set the workspace name.
     * @param name The workspace name
     */
    public void setName(String name) {
        this.name = name;
    }
    
    /**
     * Get the workspace location.
     * @return the workspace directory.
     */
    public File getLocation() {
        return location;
    }
    
    /**
     * Set the workspace location.
     * @param location the location to set.
     */
    public void setLocation(File location) {
        this.location = location;
    }
}
