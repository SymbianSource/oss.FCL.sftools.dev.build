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
 
package com.nokia.ant.types.imaker;

import org.apache.tools.ant.types.DataType;

/**
 * Helper class to store the command line variables for imaker.
 * @ant.type name="variable" category="Imaker"
 */
public class Variable extends DataType
{
    private String mName;
    private String mValue;
    
    public Variable() {
    }
    
    /**
     * Set the name of the variable.
     * @param name
     */
    public void setName(String name) {
        mName = name;
    }

    
    /**
     * Get the name of the variable.
     * @return name.
     */
    public String getName() {
        return mName;
    }

    /**
     * Set the value of the variable.
     * @param value
     */
    public void setValue(String value) {
        mValue = value;
    }

    
    /**
     * Get the value of the variable.
     * @return value.
     */
    public String getValue() {
        return mValue;
    }

}
