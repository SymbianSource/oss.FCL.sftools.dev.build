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

import java.util.ArrayList;
import java.util.List;

import org.apache.tools.ant.types.DataType;

/**
 * This Ant type defines a set of system definition
 * filters.
 * @ant.type name="sysdefFilterSet" category="Sysdef"
 */
public class FilterSet extends DataType {
    private List<Filter> filters = new ArrayList<Filter>();
    
    /**
     * Create a new nested filter.
     */
    public SysdefFilter createFilter() {
        SysdefFilter filter = new SysdefFilter();
        filters.add(filter);
        return filter;
    }
    
    /**
     * Get the list of filter
     * @return a list of filters
     */
    public List<Filter> getFilters() {
        return filters;
    }

    /**
     * Create a config filter.
     * @return a config filter.
     */
    public SysdefConfig createConfig() {
        SysdefConfig filter = new SysdefConfig();
        filters.add(filter);
        return filter;
    }
    
}
