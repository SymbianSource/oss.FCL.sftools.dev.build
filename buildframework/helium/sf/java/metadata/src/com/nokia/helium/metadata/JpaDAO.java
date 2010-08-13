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
import java.lang.reflect.ParameterizedType;
import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

/**
 * Abstract class which implement the DAO pattern for the JPA
 * API. 
 *
 * @param <T> implementing the DAO for T.
 */
public abstract class JpaDAO<T> implements DAO<T> {
    
    private Class<T> entityBeanType;
   
    @PersistenceContext
    private EntityManager entityManager;

    /**
     * Default constructor. Does some basic internal configuration.
     */
    @SuppressWarnings("unchecked")
    public JpaDAO() {
        this.entityBeanType = (Class<T>) ((ParameterizedType) getClass()
                .getGenericSuperclass()).getActualTypeArguments()[0];
    }
    
    /**
     * @param entityManager the entityManager to set
     */
    public void setEntityManager(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    /**
     * @return the entityManager
     */
    protected EntityManager getEntityManager() {
        return entityManager;
    }
    
    /**
     * {@inheritDoc}
     */
    public T findById(Serializable id) {
        return entityManager.find(getEntityBeanType(), id);
    }
   
    /**
     * {@inheritDoc}
     */
    public List<T> findAll() {
        return entityManager.createQuery("from " +
                getEntityBeanType().getName(), getEntityBeanType()).getResultList();
    }
   
    /**
     * Get the class this object is implementing the DAO for.  
     * @return the class this object is implementing the DAO for.
     */
    protected Class<T> getEntityBeanType() {
        return entityBeanType;
    }
    
    /**
     * {@inheritDoc}
     */
    public void persist(T data) {
        entityManager.persist(data);
    }

    /**
     * {@inheritDoc}
     */
    public void remove(T data) {
        entityManager.remove(data);
    }
   
}
   