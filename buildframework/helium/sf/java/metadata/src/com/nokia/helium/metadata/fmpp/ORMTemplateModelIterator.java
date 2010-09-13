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
package com.nokia.helium.metadata.fmpp;

import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.Query;

import freemarker.template.SimpleScalar;
import freemarker.template.TemplateModel;
import freemarker.template.TemplateModelIterator;

/**
 * Internal Iterator class which provides data as collection. 
 */
class ORMTemplateModelIterator implements TemplateModelIterator {
    
    private static final int PAGE_SIZE = 2000;
    private String queryString;
    private Query query;
    private int index;
    private String returnType;
    private boolean nativeQuery;
    private EntityManager entityManager;
    private List<Object> data;
    private int currentPage;
    private Object next;
    
    public ORMTemplateModelIterator(EntityManager entityManager, String queryString, String type, String retType) {
        this.entityManager = entityManager;
        this.queryString = queryString;
        returnType = retType;
        if (type.startsWith("native")) {
            nativeQuery = true;
        }
        index = 0;
    }

    /**
     * {@inheritDoc}
     */
    public TemplateModel next() {
        Object value = next;
        next = null;
        if (value != null) {
            if (nativeQuery && returnType.equals("java.lang.String")) {
                return new SimpleScalar((String)value);
            } else {
                return new ORMObjectModel(value);
            }
        }
        return null;
    }
    
    /**
     * {@inheritDoc}
     */
    @SuppressWarnings("unchecked")
    public boolean hasNext() {
        int page = index / PAGE_SIZE;
        if (query == null || page != currentPage) {
            if (nativeQuery) {
                query = entityManager.createNativeQuery(queryString);
            } else {
                query = entityManager.createQuery(queryString);
            }
            query.setFirstResult(page * PAGE_SIZE);
            query.setMaxResults(PAGE_SIZE);
            data = query.getResultList();
            currentPage = page;
        }
        if (next == null && index < data.size()) {
            next = data.get(index);
            index++;
        }
        return next != null;
    }
}
