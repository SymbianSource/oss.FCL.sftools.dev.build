
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
package com.nokia.helium.jpa.entity.metadata;

import java.util.HashMap;
import com.nokia.helium.jpa.ORMEntityManager;
import com.nokia.helium.jpa.ORMUtil;
import org.apache.log4j.Logger;

/**
 * Utility class for writing metadata information to db
 * using JPA.
 */
public final class MetadataUtil {

    private static Logger log = Logger.getLogger(MetadataUtil.class);
    
    private static Metadata metadata;
    
    private static HashMap<String, Metadata> metadataMap = new HashMap<String, Metadata>();
    
    private static Object mutexObject = new Object();
    

    private MetadataUtil() {

    }

    /**
     * Initialize the orm, calls ORMUtil initialize function to create
     * entity manager and commit count objects.
     * @param urlPath - url path for which the connection needs to be
     * initialized.
     */
    public static void initializeORM(String urlPath) {
        synchronized (mutexObject) {
            ORMUtil.initializeORM(urlPath);
        }
    }

    /**
     * Finalize the orm, calls ORMUtil finalize function to close
     * entity manager.
     */
    public static void finalizeORM(String urlPath) {
        synchronized (mutexObject) {
            log.debug("finalizing orm");
            ORMUtil.finalizeORM(urlPath);
        }
    }

    /**
     * Finalize the orm, calls ORMUtil finalize function to close
     * entity manager.
     */
    public static void finalizeMetadata(String logPath) {
        synchronized (mutexObject) {
            log.debug("finalizing metadata");
            metadataMap.remove(logPath);
        }
    }

    /**
     * Adding entry to the database.
     * @param priority - priority of the log data to be added
     * @param comp - component for which the details to be added
     * @param lineNo - line number at which the severity happened.
     * @param logText - text message of the error.
     * @param logPath - log file path where the error happened.
     * @param elapsedTime - time durartion for building the component.
     */
    public static void addEntry(String urlPath, Metadata.LogEntry entry) {
        synchronized (mutexObject) {
            metadata = getMetadata(entry.getLogPath(), urlPath);
            metadata.addEntry(entry);
        }
    }

    /**
     * Remove entry from the database for specific log file.
     * @param urlPath - db path
     * @param logPath - log file for which all the entries to be removed.
     */
    public static void removeEntries(String urlPath, String logPath) {
        synchronized (mutexObject) {
            metadata = getMetadata(logPath, urlPath);
            metadata.removeEntries();
            finalizeMetadata(logPath);
        }
    }

    /**
     * Returns the metadata associated with the log path, if metadata doesn't 
     * exists in the cache, creates it.
     * @param urlPath - db path
     * @param logPath - log file for which all the entries to be removed.
     */
    private static Metadata getMetadata(String logPath, String urlPath) {
        ORMEntityManager manager = ORMUtil.getEntityManager(urlPath);
        metadata = metadataMap.get(logPath);
        if (metadata == null) {
            log.debug("initializing metadatamap for logpath" + logPath);
            metadata = new Metadata(manager, logPath);
            
            metadataMap.put(logPath, metadata);
        }
        return metadata;
    }
}