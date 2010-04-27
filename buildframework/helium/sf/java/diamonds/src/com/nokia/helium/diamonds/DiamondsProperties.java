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



package com.nokia.helium.diamonds;

import java.util.Map;

/**
 * Helper class for Diamonds properties need to connect.
 * 
 */
public class DiamondsProperties {
    private Map<String, String> diamondsProperties;

    public DiamondsProperties(Map<String, String> configroperties) {
        diamondsProperties = configroperties;
    }

    /**
     * Gets the build id returned by Diamonds server.
     * 
     * @return build ID
     */
    public String getDiamondsBuildID() {
        return diamondsProperties.get("buildid");
    }

    /**
     * Sets the build id obtained from the server.
     * 
     * @param diamondsBuildID
     */
    public void setDiamondsBuildID(String diamondsBuildID) {
        diamondsProperties.put("buildid", diamondsBuildID);
    }

    /**
     * Returns the required property obtained from config
     * 
     * @param property
     *            for which the values needs to be obtained.
     * @return address of server
     */
    public String getProperty(String property) {
        // need to validate the properties while assigning in constructor
        return diamondsProperties.get(property);
    }
}