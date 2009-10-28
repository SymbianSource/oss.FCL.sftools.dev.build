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

import org.apache.tools.ant.Project;
/**
 * Utility class to read property value, if property is not defined it will raise an exception.
 *
 */
public final class Helper
{
    private Helper() { }
    
    public static String getProperty(Project project, String val) throws Exception
    {
        String prop = project.getProperty(val);
        if (prop == null)
            throw new Exception(val + " not defined");
        return prop;
    }
}