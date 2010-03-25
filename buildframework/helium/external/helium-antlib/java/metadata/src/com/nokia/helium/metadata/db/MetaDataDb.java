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

import java.io.File;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;

import org.apache.log4j.Logger;
import org.apache.tools.ant.BuildException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;

/**
 * A database for storing metadata about build log information.
 */
public class MetaDataDb
{
    private static Logger log = Logger.getLogger(MetaDataDb.class);

    private static final String DRIVER_CLASS_NAME = "org.sqlite.JDBC";

    private static final String URL_PREFIX = "jdbc:sqlite:/";

    private static final int LOG_ENTRY_CACHE_LIMIT = 500;

    private static final int DB_SCHEMA_VERSION = 1;


    private static final String[] INIT_TABLES = {
        "CREATE TABLE schema (version INTEGER default " + DB_SCHEMA_VERSION + ")", 
        "CREATE TABLE metadata (priority_id INTEGER, component_id INTEGER, line_number INTEGER, data TEXT, logpath_id INTEGER)", 
        "CREATE TABLE component (id INTEGER PRIMARY KEY,component TEXT, logPath_id INTEGER, UNIQUE (logPath_id,component))", 
        "CREATE TABLE priority (id INTEGER PRIMARY KEY,priority TEXT)", 
        "CREATE TABLE logfiles (id INTEGER PRIMARY KEY, path TEXT)",
        "CREATE TABLE componenttime (cid INTEGER PRIMARY KEY, time DOUBLE default 0, UNIQUE (cid))"
    };

    private static final String INSERT_METADATA_ENTRY = "INSERT INTO metadata VALUES(?, ?, ?, ?, ?)";
    private static final String INSERT_LOGENTRY = "INSERT or IGNORE INTO logfiles VALUES(?, ?)";
    private static final String INSERT_PRIORITYENTRY = "INSERT INTO priority VALUES(?, ?)";
    private static final String INSERT_COMPONENTENTRY = "INSERT or IGNORE INTO component VALUES(?, ?, ?) ";;
    private static final String INSERT_COMPONENT_TIME = "INSERT or IGNORE INTO componenttime VALUES(?, ?)";
    
    private String dbPath;

    private String url;

    private boolean statementsInitialized;

    private Connection connection;

    private Connection readConnection;

    private PreparedStatement insertMetaDataEntryStmt;
    private PreparedStatement insertLogEntryStmt;
    private PreparedStatement insertComponentStmt;
    private PreparedStatement insertComponentTimeStmt;
    
    private int entryCacheSize;

    /**
     * Opens or creates a database and initialises the tables.
     * 
     * @param databasePath The path to the database
     */
    public MetaDataDb(String databasePath)
    {
        dbPath = databasePath;
        url = URL_PREFIX + dbPath;
        try
        {
            Class.forName(DRIVER_CLASS_NAME);
        }
        catch (java.lang.ClassNotFoundException e)
        {
            throw new BuildException("JDBC Driver could not be found");
        }
        
        synchronized (MetaDataDb.class) {
            // See if the database needs to be initialized
            boolean initializeDatabase = false;
            File dbFile = new File(dbPath);
            if (!dbFile.exists())
            {
                initializeDatabase = true;
            } else {
                try {
                    log.debug("checking for schema version of db");
                    initializeConnection();
                    Statement stmt = connection.createStatement();
                    ResultSet rs = stmt.executeQuery("select version from schema");
                    int version = -1;
                    if ( rs.next()) {
                        version = rs.getInt(1);
                    }
                    rs.close();
                    stmt.close();
                    log.debug("schema version of db:" + version);
                    if (version != DB_SCHEMA_VERSION) {
                        log.debug("Schema Not matched deleting db file");
                        dbFile.delete();
                        initializeDatabase = true;
                    }
                    finalizeConnection();
                } catch (SQLException ex) {
                    try {
                        finalizeConnection();
                    } catch (SQLException ex1) {
                        throw new BuildException("Exception while finalizing Metadata database. ", ex1);
                    }
                    // We are Ignoring the errors as no need to fail the build.
                    log.debug("Exception checking schema for db", ex);
                    dbFile.delete();
                    initializeDatabase = true;
                }
            }
            try
            {
                initializeConnection();
                connection.setAutoCommit(false);
                if (initializeDatabase)
                {
                    Statement statement = connection.createStatement();
                    //statement.setQueryTimeout(60);
                    // Create tables
                    for (int i = 0; i < INIT_TABLES.length; i++)
                    {
                        statement.addBatch(INIT_TABLES[i]);
                    }
    
                    // Fill out the priority table
                    Priority[] priorityValues = Priority.values();
                    for (int i = 0; i < priorityValues.length; i++)
                    {
                        statement.addBatch("INSERT INTO priority (priority) VALUES (\""
                                + priorityValues[i] + "\")");
                    }
                    statement.addBatch("INSERT INTO schema (version) VALUES (\"" + DB_SCHEMA_VERSION + " \")");
                    statement.addBatch("create unique index logfile_unique_1 on logfiles (path)");
    
                    int[] returnCodes = statement.executeBatch();
                    connection.commit();
                    connection.setAutoCommit(false);
                    statement.close();
                    finalizeConnection();
                }
            }
            catch (SQLException e)
            {
                throw new BuildException("Problem while initializing Metadata database. ", e);
            }
        }
    }    

    /** Levels of log entry types. */
    public enum Priority
    {
        // The values assigned to these enums should match the 
        // automatically assigned values created in the database table
        FATAL(1), ERROR(2), WARNING(3), INFO(4), REMARK(5), DEFAULT(6), CRITICAL(7);
        private final int value;
        Priority(int value)
        {
            this.value = value;
        }
        public int getValue() {
            return value;
        }

        public  static Priority getPriorityEnum( int i ) {
            final Priority[] values  = values();
            return i >= 0 && i < values .length ? values[i] : FATAL;
        }
    };


    /**
     * Helper class to store the log entry , used to write to the database
     * 
     * @param databasePath The path to the database
     */
    public static class LogEntry
    {
        private String text;

        private Priority priority;

        private String component;
        
        private int lineNumber;
        
        private String logPath;
        
        private float elapsedTime;
        
        private String priroityText;

    /**
     * Constructor for the helper class 
     */
        public LogEntry(String text, Priority priority, String component, 
                String logPath, int lineNumber, float time)
        {
            this.text = text;
            this.priority = priority;
            this.component = component;
            this.lineNumber = lineNumber;
            this.logPath = logPath;
            this.elapsedTime = time;
        }

    /**
     * Constructor for the helper class 
     */
        public LogEntry(String text, Priority priority, String component, 
                String logPath, int lineNumber)
        {
            this(text, priority, component, logPath, lineNumber, -1);
        }

    /**
     * Constructor for the helper class 
     */
        public LogEntry(String text, String priorityTxt, String component, String logPath, 
                int lineNumber, float time) throws Exception
        {
            Priority prty = null;
            String prtyText = priorityTxt.trim().toLowerCase();
            priroityText =  prtyText;
            if (prtyText.equals("error")) {
                prty = Priority.ERROR;
            } else if (prtyText.equals("warning")) {
                prty = Priority.WARNING;
            } else if (prtyText.equals("fatal")) {
                prty = Priority.FATAL;
            } else if (prtyText.equals("info")) {
                prty = Priority.INFO;
            } else if (prtyText.equals("remark")) {
                prty = Priority.REMARK;
            } else if (prtyText.equals("default")) {
                prty = Priority.DEFAULT;
            } else if (prtyText.equals("critical")) {
                prty = Priority.CRITICAL;
            } else {
                log.debug("Error: priority " + prtyText + " is not acceptable by metadata and set to Error");
                prty = Priority.ERROR;
                priroityText =  "error";
                //throw new Exception("priority should not be null");
            }

            this.logPath = logPath;
            this.text = text;
            priority = prty;
            
            this.component = component;
            this.lineNumber = lineNumber;
            this.elapsedTime = time;
        }

    /**
     * Constructor for the helper class 
     */
        public LogEntry(String text, String priorityTxt, String component, String logPath, 
                int lineNumber) throws Exception
        {
            this(text, priorityTxt, component, logPath, lineNumber, -1);
        }

    /**
     * Helper function to return to getLogPath
     * @
     */

        public String getLogPath()
        {
            return logPath;
        }

        
        public int getLineNumber()
        {
            return lineNumber;
        }
        
        public String getText()
        {
            return text;
        }

        public void setText(String text)
        {
            this.text = text;
        }

        public Priority getPriority()
        {
            return priority;
        }

        public String getPriorityText() {
            return priroityText;
        }
        
        public double getElapsedTime() {
            return elapsedTime;
        }

        public void setPriority(Priority priority)
        {
            this.priority = priority;
        }

        public String getComponent()
        {
            return component;
        }

        public void setComponent(String component)
        {
            this.component = component;
        }

    }

    public void initializeConnection() throws SQLException {
        new File(dbPath).getParentFile().mkdirs();
        connection = DriverManager.getConnection(url);
    }


    public void finalizeStatements() throws SQLException {
        if (statementsInitialized) {
            if ( entryCacheSize > 0) {
                entryCacheSize = 0;
                writeLogDataToDB();
            }
            insertLogEntryStmt.close();
            insertComponentStmt.close();
            insertMetaDataEntryStmt.close();
        }
    }
    
    private void finalizeConnection() throws SQLException {
        if (connection != null) {
            connection.close();
        }
    }

    public void finalizeDB() {
        try {
            synchronized (MetaDataDb.class) {
                finalizeStatements();
                finalizeConnection();
            }
        } catch (SQLException ex) {
            // We are Ignoring the errors as no need to fail the build.
            log.debug("Exception while finalizing the Metadata database. ", ex);
        }
    }
    
    /*
     *  Todo: Further Optimize to merge with getRecords and also use
     *  primary key instead of the first column as index. 
     */
    //Note: Always the query should be in "/" format only
    public Map<String, List<String>> getIndexMap(String query) {
        Map<String, List<String>> indexMap = new LinkedHashMap<String, List<String>>();
        try {
            initializeConnection();
            Statement stmt = connection.createStatement();
            ResultSet rs = stmt.executeQuery(query);
            ResultSetMetaData rsmd = rs.getMetaData();
            int numberOfColumns = rsmd.getColumnCount();
            if (rs.isBeforeFirst()) {
                while (rs.next()) {
                    List<String> dataList = new ArrayList<String>();
                    String key = null;
                    for (int i = 1; i <= numberOfColumns; i++) {
                        String data = null;
                        int type = rsmd.getColumnType(i);
                        if (type == java.sql.Types.INTEGER ) {
                            data = "" + rs.getInt(i);
                        } else if (type == java.sql.Types.DOUBLE ) {
                            data = "" + rs.getDouble(i);
                        } else {
                            data = rs.getString(i);
                        }
                        if ( i == 1) {
                            key = data;
                        } else {
                            dataList.add(data);
                        }
                    }
                    indexMap.put(key, dataList);
                }
            }
            stmt.close();
            finalizeConnection();
        } catch (Exception ex) {
            // We are Ignoring the errors as no need to fail the build.
            log.debug("Warning: Exception while getting the index map", ex);
        }
        return indexMap;
    }

    //Note: Always the query should be in "/" format only
    public List<Map<String, Object>> getRecords(String query) {
        List<Map<String, Object>> rowList = new ArrayList<Map<String, Object>>();
        try {
            initializeConnection();
            Statement stmt = connection.createStatement();
            ResultSet rs = stmt.executeQuery(query);
            ResultSetMetaData rsmd = rs.getMetaData();

            int numberOfColumns = rsmd.getColumnCount();
            List<String> columnNames = new ArrayList<String>();
            for (int i = 1; i <= numberOfColumns; i++) {
                columnNames.add(rsmd.getColumnName(i));
            }
            if (rs.isBeforeFirst()) {
                while (rs.next()) {
                    Map<String, Object> recordMap = new LinkedHashMap<String, Object>();
                    for (int i = 1; i <= numberOfColumns; i++) {
                        int type = rsmd.getColumnType(i);
                        String columnName = columnNames.get(i - 1);
                        if (type == java.sql.Types.INTEGER ) {
                            Integer data = new Integer(rs.getInt(i));
                            recordMap.put(columnName, data);
                        } else {
                            String data = rs.getString(i);
                            recordMap.put(columnName, data );
                        }
                    }
                    rowList.add(recordMap);
                }
            }
            stmt.close();
            finalizeConnection();
        } catch (Exception ex) {
            // We are Ignoring the errors as no need to fail the build.
            log.warn("Warning: Exception while getting the record details", ex);
        }
        return rowList;
    }

    public List<Map<String, Object>> getRecords(String query, int recordLimit, int offsetValue) {
        String updatedQuery = query + " limit " + recordLimit + " offset " 
            + offsetValue + ";";
        return getRecords(updatedQuery);
    }

    /*
     * Two ways to update the metadata table for log id and component id.
     * 1. Get the last inserted record for metadata and update the individual
     * id by multiple update calls.
     * 2. Get all the ids and insert the record in metadata table. In this case
     * all the ids should be present in respective table before te insertion is
     * happened. The main reason why is done with 2. approach is that
     * while executing prepared statement, the getGeneratedKey() (which returns
     * the last inserted record, function cannot be executed during batch execution.
     * @param entries - entries for which the log and component table needs to be updated.
     */
    private void updateIndexTables(LogEntry entry) throws SQLException
    {
        connection.setAutoCommit(false);
        insertLogEntryStmt.setNull(1, 4);
        insertLogEntryStmt.setString(2, entry.getLogPath());
        insertLogEntryStmt.addBatch();
        insertLogEntryStmt.executeBatch();
        connection.commit();
        readConnection = DriverManager.getConnection(url);
        readConnection.setAutoCommit(false);
        Statement stmt = readConnection.createStatement();
        ResultSet rs = stmt.executeQuery("select id from logfiles where path='" +
                entry.getLogPath().trim() + "'");
        int logPathId = 0;
        if ( rs.next()) {
            logPathId = rs.getInt(1);
        }
        stmt.close();
        readConnection.close();
        insertComponentStmt.setNull(1, 4);
        insertComponentStmt.setString(2, entry.getComponent());
        insertComponentStmt.setInt(3, logPathId);
        insertComponentStmt.addBatch();
        insertComponentStmt.executeBatch();
        connection.commit();
        insertLogEntryStmt.clearBatch();
        insertComponentStmt.clearBatch();
    }

    private void writeLogDataToDB() throws SQLException {
        insertMetaDataEntryStmt.executeBatch();
        connection.commit();
        insertMetaDataEntryStmt.clearBatch();
    }
    
    public void removeLog(String log) throws Exception
    {
        initializeConnection();
        Statement stmt = connection.createStatement();
        stmt.executeUpdate("DELETE FROM metadata WHERE logpath_id IN (SELECT id from metadata, logfiles WHERE logfiles.id=metadata.logpath_id and logfiles.path='" + log + "')");
        stmt.close();
    }
    
    public void removeEntries(List<String> logPathList) throws Exception {
        initializeConnection();
        Statement stmt = connection.createStatement();
        for (String logPath : logPathList) {
            log.debug("logpath for delete: " + logPath);
            log.debug("logpath delete query1 " + "DELETE FROM metadata WHERE logpath_id IN (SELECT id from logfiles WHERE path like '" + logPath + "')");
            stmt.executeUpdate("DELETE FROM metadata WHERE logpath_id IN (SELECT id from logfiles WHERE path like '%" + logPath + "%')");
            log.debug("logpath for delete2: " + "DELETE FROM component_time WHERE cid IN (select id from component where logpath_id in (select id from logfiles where path like '%" + logPath + "%'))");
            stmt.executeUpdate("DELETE FROM componenttime WHERE cid IN (select id from component where logpath_id in (select id from logfiles where path like '%" + logPath + "%'))");
            log.debug("logpath for delete3: " + "DELETE FROM component WHERE logpath_id IN (select id from logfiles where path like '%" + logPath + "%')");
            stmt.executeUpdate("DELETE FROM component WHERE logpath_id IN (select id from logfiles where path like '%" + logPath + "%')");
            log.debug("logpath for delete: " + "DELETE FROM logfiles WHERE path like ('%" + logPath + "%')");
            stmt.executeUpdate("DELETE FROM logfiles WHERE path like ('%" + logPath + "%')");
        }
        stmt.close();
        finalizeConnection();
    }
    
    public void addLogEntry(LogEntry entry) throws Exception
    {
       synchronized (MetaDataDb.class) {
            try {
                if (!statementsInitialized) {
                    log.debug("Initializing statements for JDBC");
                    initializeConnection();
                    insertMetaDataEntryStmt = connection.prepareStatement(INSERT_METADATA_ENTRY);
                    insertLogEntryStmt = connection.prepareStatement(INSERT_LOGENTRY);
                    insertComponentStmt = connection.prepareStatement(INSERT_COMPONENTENTRY);
                    insertComponentTimeStmt = connection.prepareStatement(INSERT_COMPONENT_TIME);
                    statementsInitialized = true;
                }
                connection.setAutoCommit(false);
                updateIndexTables(entry);
                double time = entry.getElapsedTime();
                int logPathId = 0;
                int componentId = 0;
                Statement stmt = null;
                ResultSet rs = null;
                if ((time != -1) || entry.getPriority() != Priority.DEFAULT) {
                    readConnection = DriverManager.getConnection(url);
                    stmt = readConnection.createStatement();
                    rs = stmt.executeQuery("select id from logfiles where path='" +
                            entry.getLogPath().trim() + "'");
                    if ( rs.next()) {
                        logPathId = rs.getInt(1);
                    }
                    rs.close();
                    stmt.close();
                    insertMetaDataEntryStmt.setInt(5, logPathId);
                    stmt = readConnection.createStatement();
                    rs = stmt.executeQuery("select id from component where component='" + 
                            entry.getComponent() + "' and logpath_id='" + logPathId + "'");
                    if ( rs.next()) {
                        componentId = rs.getInt(1);
                    }
                    rs.close();
                    stmt.close();
                }
                if (time != -1) {
                    connection.setAutoCommit(false);
                    insertComponentTimeStmt.setInt(1, componentId);
                    insertComponentTimeStmt.setDouble(2, 0);
                    insertComponentTimeStmt.addBatch();
                    insertComponentTimeStmt.executeBatch();
                    connection.commit();
                    insertComponentTimeStmt.clearBatch();
                    stmt = readConnection.createStatement();
                    stmt.executeUpdate("UPDATE componenttime SET time= (time  + " + time + 
                        ") WHERE cid = " + componentId );
                    stmt.close();
                    readConnection.close();
                }
                if ( entry.getPriority() != Priority.DEFAULT) {
                    insertMetaDataEntryStmt.setInt(1, entry.getPriority().getValue());
                    insertMetaDataEntryStmt.setInt(2, componentId);
                    insertMetaDataEntryStmt.setInt(3, entry.getLineNumber());
                    insertMetaDataEntryStmt.setString(4, entry.getText());
                    insertMetaDataEntryStmt.addBatch();
                    entryCacheSize ++;
                    if (entryCacheSize >= LOG_ENTRY_CACHE_LIMIT) {
                        writeLogDataToDB();
                        entryCacheSize = 0;
                    }
                }
            } catch (SQLException ex) {
                throw new BuildException("Exception while writing the records into Metadata DB", ex);
            } catch (Exception ex1) {
                throw new BuildException("Exception while writing the records into Metadata DB", ex1);
            }
        }
    }
}