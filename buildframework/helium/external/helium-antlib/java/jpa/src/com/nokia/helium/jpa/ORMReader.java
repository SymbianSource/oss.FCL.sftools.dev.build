
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

package com.nokia.helium.jpa;


import org.apache.log4j.Logger;
import java.util.List;
import javax.persistence.Query;

/**
 * This class provides an interface to read data from the 
 * database using JPA.
 */
public class ORMReader {

    private static Logger log = Logger.getLogger(ORMReader.class);
    
    private static final int READ_CACHE_LIMIT = 30000;

    private ORMEntityManager manager;
    
    private int startPos;

    /**Constructor:
     * @param dbPath - path of the database to connect to.
     */
    public ORMReader(String dbPath) {
        ORMUtil.initializeORM(dbPath);
        manager = ORMUtil.getEntityManager(dbPath);
    }

    /**
     * Executes native sql query and returns List of objects
     * of return type mentioned by type.
     * @param queryString - sql query to be executed.
     * @param type - return type.
     * @return List of objects of return type.
     */
    public List executeNativeQuery(String queryString, String type) {
        int maxResults = READ_CACHE_LIMIT;
        String queryWithSubSet = queryString + " OFFSET " + startPos +
                " ROWS FETCH FIRST " + maxResults + " ROW ONLY";
        Query query = null;
        try {
            query = manager.getEntityManager().createNativeQuery(queryWithSubSet,
                    Class.forName(type));
        } catch (Exception ex) {
            log.debug("Exception during native query", ex);
        }
        query.setHint("eclipselink.maintain-cache", "false");
        List results = query.getResultList();
        int resultsSize = results.size();
        if (resultsSize == 0 || resultsSize < READ_CACHE_LIMIT) {
            startPos += resultsSize;
        } else {
            startPos += maxResults;
        }
        return results;
    }

    /**
     * Executes sql query which results in single result.
     * @param queryString - sql query to be executed.
     * @param type - return type.
     * @return an Object of return type.
     */
    public Object  executeSingleResult(String queryString, String type) {
        log.debug("executeSingleResult: " + queryString);
        Query query = manager.getEntityManager().createQuery(queryString);
        query.setHint("eclipselink.persistence-context.reference-mode", "WEAK");
        query.setHint("eclipselink.maintain-cache", "false");
        query.setHint("eclipselink.read-only", "true");
        Object obj = null;
        try {
            obj = query.getSingleResult();
        } catch (javax.persistence.NoResultException nex) {
            log.debug("no results:", nex);
        } catch (javax.persistence.NonUniqueResultException nux) {
            log.debug("more than one result returned:", nux);
        }
        return obj;
    }

    /**
     * Executes query using JPQL.
     * @param queryString - jpa query string
     * @return List of objects read from database.
     */
    public List executeQuery (String queryString) {
        int maxResults = READ_CACHE_LIMIT;
        Query query = manager.getEntityManager().createQuery(queryString);
        query.setHint("eclipselink.persistence-context.reference-mode", "WEAK");
        query.setHint("eclipselink.maintain-cache", "false");
        query.setHint("eclipselink.read-only", "true");
        query.setFirstResult(startPos);
        query.setMaxResults(maxResults);
        List results = (List) query.getResultList();
        int resultsSize = results.size();
        log.debug("result size: " + resultsSize);
        if (results.size() == 0 || resultsSize < READ_CACHE_LIMIT) {
            startPos += resultsSize;
        } else {
            startPos += maxResults;
        }
        return results;
    }
}