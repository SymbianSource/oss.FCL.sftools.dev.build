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

import java.util.ArrayList;
import java.util.List;

import org.apache.tools.ant.types.DataType;

/**
 * This type will allow you to group Ant type with the same
 * interface or type.
 * @param <T> the class the type must implement.
 */
public class TypeSet<T> extends DataType {
    
    private List<T> data = new ArrayList<T>();
   
    /**
     * Add a new type object of type T.
     * @param type
     */
    public void add(T type) {
        data.add(type);
    }
    
    /**
     * Get all the collected objects.
     * @return a new list of collected type objects.
     */
    @SuppressWarnings("unchecked")
    public List<T> getData() {
        if (this.isReference()) {
            TypeSet<T> referencedObject = (TypeSet<T>)this.getRefid().getReferencedObject();
            return referencedObject.getData();
        }
        return new ArrayList<T>(data);
    }

}


