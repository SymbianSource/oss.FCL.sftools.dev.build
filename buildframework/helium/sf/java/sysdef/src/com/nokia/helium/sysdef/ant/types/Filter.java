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
package com.nokia.helium.sysdef.ant.types;

/**
 * This type defines a system definition filter.
 *
 */
public class Filter {
    private String filter;
    private String type = "has";

    /**
     * Define the filter
     * @param filter the filter string.
     */
    public void setFilter(String filter) {
        this.filter = filter;
    }
    
    /**
     * Get the filter.
     */
    public String getFilter() {
        return filter;
    }

    /**
     * Define the filter type
     * @param type
     * @ant.not-required Default has.
     */
    public void setType(SydefFilterTypeEnum type) {
        this.type = type.getValue();
    }

    /**
     * Get the filter type.
     * @return
     */
    public String getType() {
        return type;
    }

}