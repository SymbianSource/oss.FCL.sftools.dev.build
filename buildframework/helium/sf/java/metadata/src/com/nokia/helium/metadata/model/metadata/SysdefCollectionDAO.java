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
package com.nokia.helium.metadata.model.metadata;

import java.util.Hashtable;
import java.util.Map;

import javax.persistence.NoResultException;
import javax.persistence.TypedQuery;

import com.nokia.helium.metadata.JpaDAO;

/**
 * Implements DAO for the Collection.
 * Contains all helpers related to Collection manipulation.
 *
 */
public class SysdefCollectionDAO extends JpaDAO<SysdefCollection> {

    /**
     * Get a map of collections rows based on the collection name.
     * @return a map of (collectionName, collection).
     */
    public Map<String, SysdefCollection> getCollections() {
        Map<String, SysdefCollection> result = new Hashtable<String, SysdefCollection>();
        for (SysdefCollection collection : this.getEntityManager().createQuery("SELECT c from SysdefCollection c", SysdefCollection.class).getResultList()) {
            result.put(collection.getCollectionId(), collection);
        }
        return result;
    }

    /**
     * Get a collection based on its model Id.
     * @param id
     * @return the entity representing the collection of null if not found.
     */
    public SysdefCollection getCollectionById(String id) {
        TypedQuery<SysdefCollection> query = this.getEntityManager().createQuery("SELECT c from SysdefCollection c where c.collectionId=?1", SysdefCollection.class);
        query.setParameter(1, id);
        try {
            return query.getSingleResult();
        } catch (NoResultException ex) {
            return null;
        }
    }
}
