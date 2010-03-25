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


package com.nokia.helium.scm.ant.types;

import org.apache.tools.ant.types.DataType;

/**
 * The tag type store the value of a desired SCM tag.
 * 
 *  <pre>
 *  &lt;tag name="release_1.0" /&gt;
 *  </pre>
 *
 */
public class Tag extends DataType {

    private String name;
    
    /**
    * Sets the tag name  
     *  
     * @param name
     * @ant.required 
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * Get the tag value.
     * @return the tag value
     */
    public String getName() {
        return name;
    }
    
}
