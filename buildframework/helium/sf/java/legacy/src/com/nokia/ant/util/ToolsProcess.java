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

package com.nokia.ant.util;

import java.util.Hashtable;

import com.nokia.tools.Tool;
import com.nokia.tools.ToolsProcessException;
import org.apache.log4j.Logger;
/**
 * Utility class to read property value, if property is not defined it will raise an exception.
 *
 */
public final class ToolsProcess {
    private static Hashtable tools = new Hashtable();

    private static Logger log;
    
    private ToolsProcess() { }

    public static Tool getTool(String reqTool) throws ToolsProcessException {
        if (log == null) {
            log = Logger.getLogger(ToolsProcess.class);
        }
        log.info("processing for tool" + reqTool);
        Class toolClass = null;
        String className = "com.nokia.tools."
            + reqTool.toLowerCase() + "." + reqTool.toUpperCase()
            + "Tool";
        try {
            toolClass = Class.forName(className);
            Tool tool = (Tool) toolClass.newInstance();
            log.debug("Found tool" + reqTool);
            return tool;
        } catch (ClassNotFoundException e1) {
            throw new ToolsProcessException("tool not supported: " + className);
        } catch (InstantiationException e2) {
            throw new ToolsProcessException("tool " + toolClass
                    + "cannot be instantiated");
        } catch (IllegalAccessException e3) {
            throw new ToolsProcessException("tool " + toolClass
                    + " cannot be accessed");
        }
    }
}