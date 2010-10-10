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
 * This class stores the information related to a 
 * repository. 
 *
 */
public class Repository {
    private int id;
    private String name;
    private String url;

    /**
     * Set the repository id.
     * @param id
     */
    public void setId(int id) {
        this.id = id;
    }

    /**
     * Set the repository name.
     * @param id
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * Set the repository location.
     * @param id
     */
    public void setUrl(String url) {
        this.url = url;
    }

    /**
     * Get the repository id.
     * @param id
     */
    public int getId() {
        return id;
    }

    /**
     * Get the repository name.
     * @param id
     */
    public String getName() {
        return name;
    }


    /**
     * Get the repository location.
     * @param id
     */
    public String getUrl() {
        return url;
    }

}
