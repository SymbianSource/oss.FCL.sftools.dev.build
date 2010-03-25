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
 
package com.nokia.helium.imaker.ant.types;

import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.BuildException;

/**
 * Configure a variable for iMaker.
 * @ant.type name="variable" category="imaker"
 */
public class Variable extends DataType
{
    private String mName;
    private String mValue;
    
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

    /**
     * Validate if the configuration is defined properly.
     * Throws BuildException in case of error.
     */
    public void validate() {
        if (getName() == null) {
            throw new BuildException("The variable element doesn't define a 'name' attribute.");
        }
        if (getValue() == null) {
            throw new BuildException("The variable element doesn't define a 'value' attribute.");
        }
    }
}
