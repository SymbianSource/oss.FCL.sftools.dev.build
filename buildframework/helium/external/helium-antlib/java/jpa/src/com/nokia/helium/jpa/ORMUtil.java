
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
import java.util.HashMap;
import org.apache.tools.ant.BuildException;

/**
 * Utility class to communicate to the database using JPA entity
 * manager.
 */
public final class ORMUtil {

    private static Logger log = Logger.getLogger(ORMUtil.class);
    
    private static final int PERSISTANCE_COUNT_LIMIT = 1000;

    private static final int READ_CACHE_LIMIT = 30000;

    private static HashMap<String, ORMEntityManager> emMap = 
        new HashMap<String, ORMEntityManager>();

    private ORMUtil() {
    }
    
    /**
     * Initializes the entity manager and begins the transcations.
     * @param urlPath - database path to be connected to.
     */
    public static synchronized void initializeORM(String urlPath) {
        ORMEntityManager manager = emMap.get(urlPath);
        log.debug("initializeORM: urlpath: " + urlPath);
        if (manager == null) {
            try {
                manager = new ORMEntityManager(urlPath);
                emMap.put(urlPath, manager);
                log.debug("initializeORM: manager: " + manager);
                log.debug("initializeORM: manager: " + manager.getEntityManager());
            } catch ( Exception ex ) {
                throw new BuildException("Entity Manager creation failure");
            }
        }
    }

    /**
     * Helper Function to return the entity manager.
     * @return entity manager created during initialization.
     */
    public static ORMEntityManager getEntityManager(String urlPath) {
        log.debug("getEntityManager: urlpath: " + urlPath);
        ORMEntityManager manager = emMap.get(urlPath);
        if (manager != null) {
            log.debug("getEntityManager: manager: " + manager);
            log.debug("getEntityManager: manager.entityManager: " + manager.getEntityManager());
            return manager;
        } else {
            log.debug("getEntityManager: manager: is null");
            throw new BuildException("ORM entity manager is null");
        }
    }
    
    /**
     * Finalize the entity manager and release all the objects.
     */
    public static void finalizeORM(String urlPath) {
        ORMEntityManager manager = emMap.get(urlPath);
        log.debug("finalizeORM: urlpath: " + urlPath);
        if (manager != null) {
            manager.finalizeEntityManager();
            manager = null;
            log.debug("finalizeORM: manager" + manager);
            emMap.remove(urlPath);
        }
    }
}