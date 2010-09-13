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
package com.nokia.helium.metadata;

import java.io.Serializable;
import java.util.List;

/**
 * Interface to implement the Data Access Object pattern. 
 *
 * @param <T> the type of the object to persist.
 */
public interface DAO<T> {
    
    /**
     * Find a particular T object based on it's id. 
     * @param id the id to look for.
     * @return the retrieved object, or null if not found.
     */
    T findById(Serializable id);
    
    /**
     * Finding all rows from the database.
     * @return the list of T objects.
     */
    List<T> findAll();
    
    /**
     * Persisting the data object from the database. 
     * @param data the object to persist
     */
    void persist(T data);

    /**
     * Removing the data object from the database.
     * @param data the row to be removed
     */
    void remove(T data);
}
