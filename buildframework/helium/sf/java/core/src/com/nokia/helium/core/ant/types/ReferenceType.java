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

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.types.Reference;

/**
 * Helper class to force the user providing a reference. 
 * It doesn't implement any particular Ant interface.
 * 
 * @param <T> The type the user should provide.
 */
public class ReferenceType<T> extends DataType {
    /**
     * Returns the referenced object.
     * 
     * @return the reference object.
     */
    @SuppressWarnings("unchecked")
    public T getReferencedObject() {
        Reference reference = getRefid();
        Object obj = reference.getReferencedObject(getProject());
        Class<T> clazz = (Class<T>)getClass().getTypeParameters()[0].getBounds()[0];
        if (clazz.isInstance(obj)) {
            return clazz.cast(obj);
        } else {
            throw new BuildException("Type referenced by " + reference.getRefId() + " is not a " + clazz.getSimpleName());
        }
    }
}