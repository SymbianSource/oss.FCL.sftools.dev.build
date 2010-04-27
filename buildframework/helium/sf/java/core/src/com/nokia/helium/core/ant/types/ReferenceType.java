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


package com.nokia.helium.core.ant.types;

import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.types.Reference;

/**
 * Helper class to force user providing a reference. It doesn't implement any
 * particular Ant interface.
 */
public class ReferenceType extends DataType {
    /**
     * Returns the referenced object.
     * 
     * @return the reference object.
     */
    public Object getReferencedObject() {
        Reference reference = getRefid();
        Object obj = reference.getReferencedObject(getProject());
        return obj;
    }
}