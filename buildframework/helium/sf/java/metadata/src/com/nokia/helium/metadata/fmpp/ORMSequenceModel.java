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

import org.apache.log4j.Logger;

import freemarker.template.SimpleNumber;
import freemarker.template.SimpleScalar;
import freemarker.template.TemplateModel;
import freemarker.template.TemplateSequenceModel;

class ORMSequenceModel implements TemplateSequenceModel {
    public static final int PAGE_SIZE = 750;
    private static Logger log = Logger.getLogger(ORMSequenceModel.class);
    private Query query;
    private int currentPage;
    private List<Object> data;
    private int size;
    private EntityManager entityManager;
    private String queryString;    

    @SuppressWarnings("unchecked")
    public ORMSequenceModel(EntityManager entityManager, String queryString) {
        log.debug("ORMSequenceModel: " + queryString);
        this.queryString = queryString;
        this.entityManager = entityManager;
        // Caching the full size
        int page = 0;
        do {
            query = entityManager.createQuery(queryString);
            query.setFirstResult(PAGE_SIZE * page);
            query.setMaxResults(PAGE_SIZE);
            data = query.getResultList();
            // incrementing the size and page.
            size += data.size();
            page++;
        } while (data.size() == PAGE_SIZE);

        // First query
        currentPage = 0;
        query = entityManager.createQuery(queryString);
        query.setFirstResult(currentPage);
        query.setMaxResults(PAGE_SIZE);
        data = query.getResultList();
    }
    
    /**
     * {@inheritDoc}
     */
    public int size() {
        return size;
    }

    /**
     * {@inheritDoc}
     */
    @SuppressWarnings("unchecked")
    public synchronized TemplateModel get(int index) {
        // Calculating the requested page
        int page = index / PAGE_SIZE;
        // Shall we load a new page
        if (page != currentPage) {
            query = entityManager.createQuery(queryString);
            query.setFirstResult(page * PAGE_SIZE);
            query.setMaxResults(PAGE_SIZE);
            data = query.getResultList();
            currentPage = page;
            if (data.size() == 0) {
                return null;
            }
        }
        // Are we out of bound.
        if (data.size() <= index % PAGE_SIZE) {
            return null;
        }
        // Let's get the object.
        Object obj = data.get(index % PAGE_SIZE);
        if (obj instanceof String) {
            return new SimpleScalar((String)obj);
        } else if (obj instanceof Number) {
            return new SimpleNumber((Number)obj);
        } else if (obj == null) {
            return null;
        } else {
            return new ORMObjectModel(obj);
        }
    }
    
}