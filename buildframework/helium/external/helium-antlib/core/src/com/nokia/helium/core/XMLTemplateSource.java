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

 

package com.nokia.helium.core;

import java.io.File;

/**
 * HlmAntlib exception handling class
 */
public class XMLTemplateSource extends AbstractTemplateInputSource
{
    private File sourceLocation;

    /**
    * Constructor
    * 
    * @param String
    *            Name of template
    * @param String
    *            location of template 
    */
    public XMLTemplateSource(String name, File location) {
        setSourceName(name);
        sourceLocation = location;
    }
    
    /**
    * Get source location
    * 
    * @return 
    *            source location. 
    */
    public File getSourceLocation() {
        return sourceLocation;
    }
}
