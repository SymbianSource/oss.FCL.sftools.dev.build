package com.nokia.fmpp;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import freemarker.core.StringArraySequence;
import freemarker.template.SimpleList;

import fmpp.Engine;
import fmpp.tdd.DataLoader;

import org.apache.log4j.Logger;



/**
 * 
 */
public class SqlDataLoader implements DataLoader {
    
    private Logger log = Logger.getLogger(SqlDataLoader.class);

    private Engine engine;

    private List args;

    private String driverClassName = "org.sqlite.JDBC";

    private String url = "jdbc:sqlite:e:\\Build_E\\eclipse_fasym013\\helium-trunk\\helium\\build\\test.db";

    private String database = "log_output_text";
    
    private int offset;

    /**
     * @see fmpp.tdd.DataLoader#load(fmpp.Engine, java.util.List)
     */
    public Object load(Engine engine, List args) throws Exception {

        this.engine = engine;
        this.args = args;
        this.offset = Integer.parseInt((String)args.get(0));


        // establish a JDBC connection
        Class.forName(this.driverClassName);
        System.setProperty("jdbc.drivers", this.driverClassName);
        Connection connection = DriverManager.getConnection(this.url);

        try {
            return load(connection);
        }
        finally {
            connection.close();
        }
    }

    protected Object load(Connection connection) throws Exception {
        HashMap database = new HashMap();

        // recuperation des tables
        ResultSet rs = connection.getMetaData().getTables(this.database, null,
                null, null);
        while (rs.next()) {
            log.info(rs.getString(3));
            database.put(rs.getString(3), new ArrayList());
        }
        rs.close();

        // recuperation des donnees
        Iterator it = database.keySet().iterator();
        while (it.hasNext()) {
            String tableName = (String) it.next();
            List table = (List) database.get(tableName);

            // recuperation de la structure de la table
            rs = connection.getMetaData().getColumns(this.database, null,
                    tableName, null);
            List tableStructure = new ArrayList();
            while (rs.next()) {
                tableStructure.add(rs.getString(4));
            }
            String[] fieldNames = (String[]) tableStructure
                    .toArray(new String[] { });
            ArrayList list = new ArrayList();
            ArrayList rowList = new ArrayList();
            log.info("offset" + offset);
            // recuperation des donnees
            String sql = "SELECT COUNT(*) AS COUNT FROM " + tableName + " where priority='WARNING';";
            Statement stmt = connection.createStatement();
            rs = stmt.executeQuery(sql);
            log.info("record size of warning:" + rs.getInt("COUNT"));
            stmt.close();
            sql = "SELECT * FROM " + tableName + " limit 5 offset " + offset + ";";
            stmt = connection.createStatement();
            rs = stmt.executeQuery(sql);
            if (rs.isBeforeFirst()) {
                while (rs.next()) {
                    HashMap row = new HashMap();
                    for (int i = 0; i < fieldNames.length; i++) {
                        String fieldName = fieldNames[i];
                        list.add(rs.getObject(i + 1));
                        //row.put(fieldName, rs.getObject(i + 1));
                    }
                    String[] str = new String [list.size()];
                    rowList.add(new StringArraySequence((String [])list.toArray(str)));
                    //table.add(row);
                }
            }
            
            database.put("content",new SimpleList(rowList));
            stmt.close();
        }
        return database;
    }
}