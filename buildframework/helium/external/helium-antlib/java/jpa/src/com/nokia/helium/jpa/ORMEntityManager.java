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
import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import java.util.Hashtable;
import javax.persistence.Persistence;
import org.eclipse.persistence.config.PersistenceUnitProperties;
import java.io.File;
import org.apache.commons.io.FileUtils;
import com.nokia.helium.jpa.entity.Version;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.sql.ResultSet;
import org.apache.tools.ant.BuildException;

/**
 * This class handles the generic ORM entity management.
 */
public class ORMEntityManager {

    private static Logger log = Logger.getLogger(ORMEntityManager.class);

    private EntityManager entityManager;

    private ORMCommitCount commitCountObject;

    /**  
     * Constructor.
     * @param urlPath path for which entity manager to be
     * created.
     */
    @SuppressWarnings("unchecked")
    public ORMEntityManager(String urlPath) throws Exception {
        String name = "metadata";
        Hashtable persistProperties = new Hashtable();
        persistProperties.put("javax.persistence.jdbc.driver",
                "org.apache.derby.jdbc.EmbeddedDriver");
        persistProperties.put("javax.persistence.jdbc.url",
               "jdbc:derby:" + urlPath);
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
        File dbFile = new File(urlPath);
        commitCountObject = new ORMCommitCount();
        if (dbFile.exists()) {
            try {
                log.debug("checking db integrity for :" + urlPath);
                if (!checkDatabaseIntegrity(urlPath)) {
                    log.debug("db integrity failed cleaning up old db");
                    try {
                        log.debug("deleting the url path" + urlPath);
                        FileUtils.forceDelete(dbFile);
                        log.debug("successfully removed the urlpath" + urlPath);
                    } catch (java.io.IOException iex) {
                        log.debug("deleting the db directory failed", iex);
                        throw new BuildException("failed deleting corrupted db", iex);
                    }
                } else {
                    log.debug("db exists and trying to create entity manager");
                    EntityManagerFactory factory =
                        Persistence.createEntityManagerFactory(
                            name,
                            persistProperties);
                    entityManager = factory.createEntityManager();
                    entityManager.getTransaction().begin();
                    return;
                }
            } catch (Exception ex) {
                log.debug("Failed to open the database, might be corrupted, creating new db", ex);
                try {
                    FileUtils.deleteDirectory(dbFile);
                } catch (java.io.IOException iex) {
                    log.debug("deleting the db directory failed");
                    throw iex;
                }
            }
        }
        log.debug("url path not exists" + urlPath + "creating it");
        persistProperties.put("javax.persistence.jdbc.url",
               "jdbc:derby:" + urlPath + ";create=true");
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
        EntityManagerFactory factory =
            Persistence.createEntityManagerFactory(
                name,
                persistProperties);
        entityManager = factory.createEntityManager();
        entityManager.getTransaction().begin();
        entityManager.persist(new Version());
        entityManager.getTransaction().commit();
        entityManager.clear();
        entityManager.getTransaction().begin();
    }

    /**
     * Helper function to get the entity manager.
     * @return entity manager
     */
    public EntityManager getEntityManager() {
        log.debug("ORMEntityManager: getEntityManager: " + entityManager);
        return entityManager;
    }

    /**
     * Helper function to get commit count object
     * @return commit count object used for cached persisting.
     */
    public ORMCommitCount getCommitCountObject() {
        return commitCountObject;
    }

    /**
     * If Any data to be commited, then this function
     * commits the data to the database.
     */
    public void commitToDB() {
        log.debug("commitToDB");
        if (entityManager.getTransaction().isActive()) {
            if (commitCountObject.isDatatoCommit()) {
                entityManager.getTransaction().commit();
                commitCountObject.reset();
                entityManager.clear();
                entityManager.getTransaction().begin();
            }
        }
    }

    /**
     * Finalizes the entity manager.
     */
    public void finalizeEntityManager() {
        log.debug("finalizeEntitymanager:" + entityManager);
        if (entityManager != null) {
            log.debug("finalizeEntitymanager: isactive1");
            if (entityManager.getTransaction().isActive()) {
                log.debug("finalizeEntitymanager: isactive2");
                try {
                    entityManager.getTransaction().commit();
                } catch (Exception ex) {
                    log.debug("exception during commit", ex);
                } finally {
                    log.debug("cleaning up entity manager instance" + entityManager);
                    if (commitCountObject != null) {
                        commitCountObject.reset();
                    }
                    if (entityManager != null) {
                        entityManager.clear();
                        entityManager.close();
                        entityManager = null;
                    }
                }
            }
        }
    }

    /**
     * Checks the database integrity.
     * @param urlPath - database path to be connected to.
     * @return boolean - true if db is valid false otherwise.
     */
    private boolean checkDatabaseIntegrity(String urlPath) {
        boolean result = false;
        loadDriver();
        Connection connection = null;
        try {
            connection = DriverManager.getConnection("jdbc:derby:" + urlPath);
            if (connection != null) {
                Statement stmt = connection.createStatement();
                ResultSet rs = stmt.executeQuery("select version from version");
                int version = -1;
                log.debug("result set executed");
                if ( rs.next()) {
                    version = rs.getInt(1);
                }
                log.debug("result set executed : " + version);
                rs.close();
                stmt.close();
                if (version == Version.DB_VERSION) {
                    result = true;
                } else {
                    DriverManager.getConnection("jdbc:derby:;shutdown= true");
                }
            }
        } catch (Exception ex) {
            log.debug("exception while checking database integrity: ", ex);
            log.debug("shutting down embedded db");
            try {
                DriverManager.getConnection("jdbc:derby:;shutdown= true");
            } catch (java.sql.SQLException sex) {
                log.debug("normal exception during db shutdown");
            }
        } finally {
            try {
                log.debug("closing the connection");
                if (connection != null) {
                    connection.close();
                }
            } catch (java.sql.SQLException sex) {
                log.debug("normal exception during db shutdown");
            }
            connection = null;
        }
        //shutdown unloads the driver, driver need to be loaded again.
        return result;
    }
    private void loadDriver() {
        try
        {
            Class.forName("org.apache.derby.jdbc.EmbeddedDriver");
        }
        catch (java.lang.ClassNotFoundException e)
        {
            throw new BuildException("JDBC Driver could not be found");
        }
    }

}