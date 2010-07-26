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

    private String dbPath;
    
    public ORMMetadataDB(String databasePath) {
        log.debug("initializing ORMMetadataDB: dbPath: " + databasePath);
        // Lower case the filename because of SMB share.
        File actualPath = new File(databasePath);
        String fileName = actualPath.getName();
        dbPath = new File(actualPath.getParent(), fileName.toLowerCase()).getPath();
        MetadataUtil.initializeORM(dbPath);
    }

    public void addLogEntry(Metadata.LogEntry entry) {
        MetadataUtil.addEntry(dbPath, entry);
    }
    
    /**
     * Add an execution time record to the database for current log.
     * @param time
     */
    public void addExecutionTime(String logPath, int time) {
        MetadataUtil.addEntry(dbPath, logPath, time);
    }

    public void removeEntries(String logPath) {
        MetadataUtil.removeEntries(dbPath, logPath);
    }

    public void finalizeMetadata(String logPath) {
        MetadataUtil.finalizeMetadata(dbPath, logPath);
    }

    public void finalizeDB() {
        MetadataUtil.finalizeORM(dbPath);
    }

}