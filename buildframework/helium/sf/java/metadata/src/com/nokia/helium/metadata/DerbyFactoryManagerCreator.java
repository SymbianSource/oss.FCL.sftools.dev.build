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
package com.nokia.helium.metadata;

import java.io.File;
import java.io.OutputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Hashtable;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.persistence.Persistence;

import org.apache.commons.io.FileUtils;
import org.eclipse.persistence.config.PersistenceUnitProperties;

import com.nokia.helium.metadata.ant.types.SeverityEnum;
import com.nokia.helium.metadata.model.Version;
import com.nokia.helium.metadata.model.metadata.Severity;

/**
 * Class implementing a EntityManagerFactoryCreator for the derby database.
 * This will be used to create new EntityManagerFactory for each database. It also
 * handles the driver management, and basic factory settings. 
 *
 */
public class DerbyFactoryManagerCreator implements EntityManagerFactoryCreator {

    public static final OutputStream DEV_NULL = new OutputStream() {         
        public void write(int b) { }     
    };

    public synchronized EntityManagerFactory create(File database) throws MetadataException {
        EntityManagerFactory factory;
        String name = "metadata";
        Hashtable<String, String> persistProperties = new Hashtable<String, String>();
        persistProperties.put("javax.persistence.jdbc.driver", "org.apache.derby.jdbc.EmbeddedDriver");
        // This swallow all the output log from derby.
        System.setProperty("derby.stream.error.field", "com.nokia.helium.metadata.DerbyFactoryManagerCreator.DEV_NULL");
        persistProperties.put("javax.persistence.jdbc.url",
               "jdbc:derby:" + database.getAbsolutePath());
        persistProperties.put(
                PersistenceUnitProperties.PERSISTENCE_CONTEXT_CLOSE_ON_COMMIT,
                "false");
        persistProperties.put(
                PersistenceUnitProperties.PERSISTENCE_CONTEXT_REFERENCE_MODE,
                "WEAK");
        persistProperties.put(PersistenceUnitProperties.BATCH_WRITING,
                "JDBC");
        persistProperties.put("eclipselink.read-only", "true");
        persistProperties.put(PersistenceUnitProperties.LOGGING_LEVEL, "warning");
        if (database.exists()) {
            if (!checkDatabaseIntegrity(database)) {
                try {
                    FileUtils.forceDelete(database);
                } catch (java.io.IOException iex) {
                    throw new MetadataException("Failed deleting corrupted db: " + iex, iex);
                }
            } else {
                return
                    Persistence.createEntityManagerFactory(
                        name,
                        persistProperties);
            }
        }
        persistProperties.put("javax.persistence.jdbc.url",
               "jdbc:derby:" + database + ";create=true");
        persistProperties.put(PersistenceUnitProperties.DDL_GENERATION,
                "create-tables");
        persistProperties.put(
                PersistenceUnitProperties.DDL_GENERATION_MODE,
                "database");
        persistProperties.put(
                PersistenceUnitProperties.PERSISTENCE_CONTEXT_CLOSE_ON_COMMIT,
                "false");
        persistProperties.put(
                PersistenceUnitProperties.PERSISTENCE_CONTEXT_REFERENCE_MODE,
                "WEAK");
        persistProperties.put(PersistenceUnitProperties.BATCH_WRITING,
                "JDBC");
        persistProperties.put("eclipselink.read-only", "true");
        factory = Persistence.createEntityManagerFactory(
                name,
                persistProperties);
        EntityManager entityManager = factory.createEntityManager();
        // Pushing default data into the current schema
        try {
            entityManager.getTransaction().begin();
            // Version of the schema is pushed.
            entityManager.persist(new Version());
            // Default set of severity is pushed.
            for (SeverityEnum.Severity severity : SeverityEnum.Severity.values()) {
                Severity pData = new Severity();
                pData.setSeverity(severity.toString());
                entityManager.persist(pData);
            }
            entityManager.getTransaction().commit();
        } finally {
            if (entityManager.getTransaction().isActive()) {
                entityManager.getTransaction().rollback();
                entityManager.clear();
            }
            entityManager.close();
        }
        return factory;
    }
    
    /**
     * Checks the database integrity.
     * @param urlPath - database path to be connected to.
     * @return boolean - true if db is valid false otherwise.
     */
    private static boolean checkDatabaseIntegrity(File database) throws MetadataException {
        boolean result = false;
        Connection connection = null;
        try {
            connection = DriverManager.getConnection("jdbc:derby:" + database);
            if (connection != null) {
                Statement stmt = connection.createStatement();
                ResultSet rs = stmt.executeQuery("select version from version");
                int version = -1;
                if ( rs.next()) {
                    version = rs.getInt(1);
                }
                rs.close();
                stmt.close();
                connection.close();
                connection = null;
                result = version == Version.DB_VERSION; 
            }
        } catch (SQLException ex) {
            try {
                DriverManager.getConnection("jdbc:derby:;shutdown=true");
            } catch (java.sql.SQLException sex) {
                // normal exception during database shutdown
                connection = null;
            }
            return false;
        } finally {
            try {            
                if (connection != null) {
                    connection.close();
                }
            } catch (java.sql.SQLException sex) {
                // normal exception during database shutdown
                connection = null;
            }
            connection = null;
            if (!result) {
                try {
                    DriverManager.getConnection("jdbc:derby:;shutdown=true");
                } catch (java.sql.SQLException sex) {
                    // normal exception during database shutdown
                    connection = null;
                }
            }
        }
        //shutdown unloads the driver, driver need to be loaded again.
        return result;
    }
    
    public synchronized void unload(File database) {
        try {
            DriverManager.getConnection("jdbc:derby:" + database + ";shutdown=true");
        } catch (SQLException e) {
            // normal exception during database shutdown
            e = null;
        }        
    }
    
    public synchronized void initialize() throws MetadataException {
        try {
            Class.forName("org.apache.derby.jdbc.EmbeddedDriver");
        } catch (java.lang.ClassNotFoundException e) {
            throw new MetadataException("JDBC Driver could not be found", e);
        }
    }
    
}
