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

import org.apache.tools.ant.types.EnumeratedAttribute;

/**
 * This class defines the keyword supported by the type
 * attribute of the Filter class.
 *
 * It currenly defines the following keywords: only, with, has.
 */
public class SydefFilterTypeEnum extends EnumeratedAttribute {
    private String[] values = {"only", "with", "has"};
    
    /**
     * {@inheritDoc}
     */
    @Override
    public String[] getValues() {
        return values;
    }
}
