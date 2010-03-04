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

package com.nokia.helium.metadata.db;


import com.nokia.helium.jpa.entity.metadata.MetadataUtil;
import java.io.File;
import org.apache.log4j.Logger;
import com.nokia.helium.jpa.entity.metadata.Metadata;

/**
 * Database class to write the contents to the database.
 */
public class ORMMetadataDB {

    private static Logger log = Logger.getLogger(ORMMetadataDB.class);

    private static final int LOG_ENTRY_CACHE_LIMIT = 500;

    private static final int DB_SCHEMA_VERSION = 1;

    private String dbPath;
    
    public ORMMetadataDB(String databasePath) {
        log.debug("initializing ORMMetadataDB: dbPath: " + databasePath);
        //mainly for dragonfly server
        File actualPath = new File(databasePath);
        String fileName = actualPath.getName();
        dbPath = new File(actualPath.getParent(), fileName.toLowerCase()).getPath();
        MetadataUtil.initializeORM(dbPath);
    }

    public void addLogEntry(Metadata.LogEntry entry) {
        //log.debug("addLogEntry : priority : " + entry.getPriorityText());
        //log.debug("addLogEntry : component : " + entry.getComponent());
        //log.debug("addLogEntry : line number : " + entry.getLineNumber());
        //log.debug("addLogEntry : text : " + entry.getText());
            MetadataUtil.addEntry(dbPath, entry);
    }

    public void removeEntries(String logPath) {
        MetadataUtil.removeEntries(dbPath, logPath);
    }

    public void finalizeMetadata(String logPath) {
        MetadataUtil.finalizeMetadata(logPath);
    }

    public void finalizeDB() {
        MetadataUtil.finalizeORM(dbPath);
    }

}