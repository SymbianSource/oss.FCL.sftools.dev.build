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
//import java.sql.DatabaseMetaData;
import org.apache.log4j.Logger;
import org.apache.tools.ant.BuildException;
import java.util.HashMap;
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

    //private static final int RECORD_LIMIT recordLimit = 5000;
    
    private static final String[] INIT_TABLES = {
        "CREATE TABLE metadata (priority_id INTEGER, component_id INTEGER, line_number INTEGER, data TEXT, logpath_id INTEGER)", 
        "CREATE TABLE component (id INTEGER PRIMARY KEY,component TEXT, logPath_id INTEGER, UNIQUE (logPath_id,component))", 
        "CREATE TABLE priority (id INTEGER PRIMARY KEY,priority TEXT)", 
        "CREATE TABLE logfiles (id INTEGER PRIMARY KEY, path TEXT)"
    };

    private static final String INSERT_METADATA_ENTRY = "INSERT INTO metadata VALUES(?, ?, ?, ?, ?)";
    private static final String INSERT_LOGENTRY = "INSERT or IGNORE INTO logfiles VALUES(?, ?)";
    private static final String INSERT_PRIORITYENTRY = "INSERT INTO priority VALUES(?, ?)";
    private static final String INSERT_COMPONENTENTRY = "INSERT or IGNORE INTO component VALUES((SELECT max(id) FROM component)+1, ?, ?) ";
    
    private String dbPath;

    private String url;

    private boolean statementsInitialized;

    private Connection connection;

    private Connection readConnection;

    private PreparedStatement insertMetaDataEntryStmt;
    private PreparedStatement insertLogEntryStmt;
    private PreparedStatement insertComponentStmt;
    
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
            log.debug("No JDBC Driver found");
            throw new BuildException("JDBC Driver could not be found");
        }
        
        synchronized (MetaDataDb.class) {
            // See if the database needs to be initialized
            boolean initializeDatabase = false;
            if (!new File(dbPath).exists())
            {
                initializeDatabase = true;
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
                    statement.addBatch("create unique index logfile_unique_1 on logfiles (path)");
                    //statement.addBatch("create unique index component_unique_1 on component (component)");
    
                    int[] returnCodes = statement.executeBatch();
                    connection.commit();
                    connection.setAutoCommit(false);
                    statement.close();
                    finalizeConnection();
                }
            }
            catch (SQLException e)
            {
                log.debug("problem initializing database",e);
                throw new BuildException("Problem initializing database");
            }
        }
    }    

    /** Levels of log entry types. */
    public enum Priority
    {
        // The values assigned to these enums should match the 
        // automatically assigned values created in the database table
        FATAL(1), ERROR(2), WARNING(3), INFO(4), REMARK(5), DEFAULT(6);
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


    public static class LogEntry
    {
        private String text;

        private Priority priority;

        private String component;
        
        private int lineNumber;
        
        private String logPath;
        
        public LogEntry(String text, Priority priority, String component, 
                String logPath, int lineNumber)
        {
            this.text = text;
            this.priority = priority;
            this.component = component;
            this.lineNumber = lineNumber;
            this.logPath = logPath;
        }

        public LogEntry(String text, String priorityTxt, String component, String logPath, 
                int lineNumber) throws Exception
        {
            Priority prty = null;
            String prtyText = priorityTxt.trim().toLowerCase();
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
            } else {
                log.debug("Error: priority " + prtyText + " is not acceptable by metadata and set to Error");
                prty = Priority.ERROR;
                //throw new Exception("priority should not be null");
            }

            this.logPath = logPath;
            this.text = text;
            priority = prty;
            
            this.component = component;
            this.lineNumber = lineNumber;
        }
        
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
                //log.debug("writing to database");
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
            log.debug("exception while finalizing the db", ex);
            //throw ex;
        }
    }
    
    /*
     *  Todo: Further Optimize to merge with getRecords and also use
     *  primary key instead of the first column as index. 
     */
    //Note: Always the query should be in "/" format only
    public Map<String, List<String>> getIndexMap(String query) {
        Map<String, List<String>> indexMap = new HashMap<String, List<String>>();
        log.debug("sql query" + query);
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
                        } else {
                            data = rs.getString(i);
                        }
                        log.debug("data:" + data);
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
            log.debug("Warning: Exception while getting the index map", ex);
            //throw ex;
        }
        return indexMap;
    }

    //Note: Always the query should be in "/" format only
    public List<Map<String, Object>> getRecords(String query) {
        List<Map<String, Object>> rowList = new ArrayList<Map<String, Object>>();
        log.debug("sql query" + query);
        try {
            initializeConnection();
            Statement stmt = connection.createStatement();
            ResultSet rs = stmt.executeQuery(query);
            ResultSetMetaData rsmd = rs.getMetaData();

            int numberOfColumns = rsmd.getColumnCount();
            List<String> columnNames = new ArrayList<String>();
            for (int i = 1; i <= numberOfColumns; i++) {
                columnNames.add(rsmd.getColumnName(i));
                log.debug("columnName:" + rsmd.getColumnName(i));
            }

            log.debug("resultSet MetaData column Count=" + numberOfColumns);
            if (rs.isBeforeFirst()) {
                while (rs.next()) {
                    Map<String, Object> recordMap = new HashMap<String, Object>();
                    log.debug("adding records");
                    for (int i = 1; i <= numberOfColumns; i++) {
                        int type = rsmd.getColumnType(i);
                        String columnName = columnNames.get(i - 1);
                        //log.debug("columnName:" + columnName);
                        if (type == java.sql.Types.INTEGER ) {
                            Integer data = new Integer(rs.getInt(i));
                            recordMap.put(columnName, data);
                            log.debug("data:" + data);
                        } else {
                            String data = rs.getString(i);
                            recordMap.put(columnName, data );
                            log.debug("data:" + data);
                        }
                    }
                    rowList.add(recordMap);
                }
            }
            stmt.close();
            finalizeConnection();
        } catch (Exception ex) {
            log.debug("Warning: Exception while getting the record details", ex);
            //throw ex;
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
        //log.debug("updating logpath: " + entry.getLogPath());
        insertLogEntryStmt.setNull(1, 4);
        insertLogEntryStmt.setString(2, entry.getLogPath());
        insertLogEntryStmt.addBatch();
        insertLogEntryStmt.executeBatch();
        connection.commit();
        readConnection = DriverManager.getConnection(url);
        readConnection.setAutoCommit(false);
        Statement stmt = readConnection.createStatement();
        log.debug("exiting synchronization---2");
        ResultSet rs = stmt.executeQuery("select id from logfiles where path='" +
                entry.getLogPath().trim() + "'");
        int logPathId = 0;
        if ( rs.next()) {
            logPathId = rs.getInt(1);
        }
        stmt.close();
        readConnection.close();
        log.debug("exiting synchronization---5");
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
    
    public void addLogEntry(LogEntry entry) throws Exception
    {
       synchronized (MetaDataDb.class) {
            try {
                if (!statementsInitialized) {
                    log.debug("initializing statements for JDBC");
                    initializeConnection();
                    insertMetaDataEntryStmt = connection.prepareStatement("INSERT INTO metadata VALUES(?, ?, ?, ?, ?)");
                    insertLogEntryStmt = connection.prepareStatement("INSERT or IGNORE INTO logfiles VALUES(?, ?)");
                    insertComponentStmt = connection.prepareStatement("INSERT or IGNORE INTO component VALUES(?, ?, ?) ");
                    statementsInitialized = true;
                }
                log.debug("MetaDataDB:entry:priority: " + entry.getPriority());
                connection.setAutoCommit(false);
                updateIndexTables(entry);
                if ( entry.getPriority() != Priority.DEFAULT) {
                    readConnection = DriverManager.getConnection(url);
                    Statement stmt = readConnection.createStatement();
                    ResultSet rs = stmt.executeQuery("select id from logfiles where path='" +
                            entry.getLogPath().trim() + "'");
                    int logPathId = 0;
                    if ( rs.next()) {
                        logPathId = rs.getInt(1);
                    }
                    rs.close();
                    stmt.close();
                    insertMetaDataEntryStmt.setInt(5, logPathId);
                    stmt = readConnection.createStatement();
                    rs = stmt.executeQuery("select id from component where component='" + 
                            entry.getComponent() + "' and logpath_id='" + logPathId + "'");
                    int componentId = 0;
                    if ( rs.next()) {
                        componentId = rs.getInt(1);
                    }
                    rs.close();
                    stmt.close();
                    readConnection.close();
                    insertMetaDataEntryStmt.setInt(1, entry.getPriority().getValue());
                    insertMetaDataEntryStmt.setInt(2, componentId);
                    insertMetaDataEntryStmt.setInt(3, entry.getLineNumber());
                    insertMetaDataEntryStmt.setString(4, entry.getText());
                    insertMetaDataEntryStmt.addBatch();
                    entryCacheSize ++;
                    if (entryCacheSize >= LOG_ENTRY_CACHE_LIMIT) {
                        log.debug("writing data to database");
                        writeLogDataToDB();
                        entryCacheSize = 0;
                    }
                }
            } catch (SQLException ex) {
                log.debug(" Exception while writing the record");
                throw ex;
            }
        }
    }
}