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

 
package com.nokia.helium.signal.ant.types;

import org.apache.tools.ant.types.DataType;
import com.nokia.helium.core.LogSource;
import org.apache.tools.ant.BuildException;

import java.util.Vector;

    
/**
 * This type is used by the signalConfig to store a list of 
 * LogSource that will get passed to the notifiers.
 * 
 * @ant.type name="sources" category="Signaling"
 * 
 */
public class LogSourceList extends DataType {

    private Vector<LogSource> sourceList = new Vector<LogSource>();
    
    private String type;
    
    /**
     * Creates a type of LogSource.
     * @return logsource which will be processed during signaling.
     */
    public LogSource createLogSource() {
        LogSource source =  new LogSource();
        add(source);
        return source;
    }
    
    /**
     * Adding a logsource to signal config.
     * @param logsource
     */
    public void add(LogSource logSource) {
        sourceList.add(logSource);
    }

    public void setType(String sourcesType) {
        type = sourcesType; 
    }
    /**
     * Returns the list of logsource available 
     * @return logsource list
     */
    public Vector<LogSource> getLogSourceList() {
        if (sourceList.isEmpty()) {
            throw new BuildException("Signal notifierlist is empty.");
        }
        return sourceList;
    }

    public String getSourceType() {
        return type;
    }    
}
