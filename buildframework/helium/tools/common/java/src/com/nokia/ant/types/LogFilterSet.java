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
 
package com.nokia.ant.types;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;
import java.util.Vector;

/**
 * Helper class to store the log filter set.
 * @ant.type name="logfilterset"
 * @Deprecated Start using hlm:recordfilterset.
 */
@Deprecated 
public class LogFilterSet extends DataType {
    
    private Vector filters = new Vector();
    
    public LogFilterSet() {
        log("Deprecated Start using hlm:recordfilterset", Project.MSG_WARN);
    }    

    public LogFilter createLogFilter() {
        LogFilter filter =  new LogFilter();
        add(filter);
        return filter;
    }
    
    public void add(LogFilter filter) {
        filters.add(filter);
    }
    
    public Vector getFilters() {
        return filters;
    }
    
}
