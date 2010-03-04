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

import org.apache.tools.ant.types.EnumeratedAttribute;

/**
 * Enum class for the failbuild attribute.
 */
public class FailBuildEnum extends EnumeratedAttribute {

    /**
     * @return the list of allowed values.
     */
    @Override
    public String[] getValues() {
        String[] values = new String[3];
        values[0] = "now";
        values[1] = "defer";
        values[2] = "never";
        return values;
    }
}
