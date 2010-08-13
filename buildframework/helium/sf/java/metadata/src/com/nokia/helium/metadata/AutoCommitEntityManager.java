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

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;


/**
 * This class implements a simplified EntityManager
 * designed for batch committing.
 * Serial persists are committed and cleared each time
 * the limit is reached.  
 *
 */
public class AutoCommitEntityManager {
    private EntityManager entityManager;
    private int count;
    private int maxCount = 750;
    
    /**
     * Creating a new AutoCommitEntityManager. The entityManagerFactory will be 
     * used to get a new EntityManager.
     * @param entityManagerFactory the entity manager to use to create a EntityManager.
     */
    public AutoCommitEntityManager(EntityManagerFactory entityManagerFactory) {
        this.entityManager = entityManagerFactory.createEntityManager();
        entityManager.getTransaction().begin();
    }
    
    /**
     * Persisting an object into the database.
     * @param o the object to persist
     */
    public synchronized void persist(Object o) {
        entityManager.persist(o);
        count++;
        if (count >= maxCount) {
            entityManager.getTransaction().commit();
            entityManager.clear();
            count = 0;
            entityManager.getTransaction().begin();
        }
    }
    
    /**
     * Closing the current entity manager. Committing any 
     * pending operation.
     */
    public synchronized void close() {
        if (entityManager.getTransaction().isActive()) {
            entityManager.getTransaction().commit();
            entityManager.clear();
        }
        entityManager.close();
        entityManager = null;
    }

    /**
     * Internal EntityManager used to
     * @param <T>
     * @return the merged entity.
     */
    public <T> T merge(T entity) {
        return entityManager.merge(entity);
    }
    
}
