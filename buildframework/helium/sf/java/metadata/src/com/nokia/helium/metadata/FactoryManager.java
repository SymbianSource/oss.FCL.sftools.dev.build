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
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.persistence.Cache;
import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.persistence.PersistenceUnitUtil;
import javax.persistence.criteria.CriteriaBuilder;
import javax.persistence.metamodel.Metamodel;

/**
 * This singleton class is the main entry point to the Metadata framework.
 * Developer must use it to get access to the EntityManagerFactory from the
 * JPA framework. 
 *
 */
public final class FactoryManager {
    private static FactoryManager self = new FactoryManager();
    private List<EntityManagerFactoryWrapper> wrappers = new ArrayList<EntityManagerFactoryWrapper>();
    private EntityManagerFactoryCreator factoryManagerCreator = new DerbyFactoryManagerCreator();
    
    /**
     * This class must not be instantiated from outside.
     */
    private FactoryManager() {
    }
    
    /**
     * Get the FactoryManager instance.
     * @return the FactoryManager instance.
     */
    public static FactoryManager getFactoryManager() {
        return self;
    }
    
    /**
     * Get the EntityManagerFactory for the database. 
     * @param database the File object representing the database.
     * @return an EntityManagerFactory instance.
     * @throws MetadataException is thrown in case of error.
     */
    public synchronized EntityManagerFactory getEntityManagerFactory(File database) throws MetadataException {
        EntityManagerFactoryWrapper wrapper = null;
        for (EntityManagerFactoryWrapper wrp : wrappers) {
            // Found what we wanted so leaving the loop.
            if (wrp.getDatabase().equals(database)) {
                wrapper = wrp;
                break;
            }
        }
        if (wrapper != null) {
            wrapper.reference();
            return wrapper;
        } else {
            // creating a new one.
            wrapper = 
                new EntityManagerFactoryWrapper(factoryManagerCreator.create(database), this, database);
            wrappers.add(wrapper);
            return wrapper;
        }
    }
    
    /**
     * Removing the wrapper object from the available database, so no one can 
     * use it anymore. This method is intended to be used by the EntityManagerFactoryWrapper.
     * @param wrapper
     */
    private synchronized void remove(EntityManagerFactoryWrapper wrapper) {
        wrappers.remove(wrapper);
    }

    /**
     * Unload the database when not used anymore.
     * This method is intended to be used by the EntityManagerFactoryWrapper.
     * @param database the database to unload.
     */
    private void unload(File database) {
        try {
            factoryManagerCreator.unload(database);
        } catch (MetadataException e) {
            // do nothing in the meantime
            database = null;
        }        
    }
    
    /**
     * Internal Factory wrapper object which implements a custom 
     * factory lifecycle management. 
     *
     */
    class EntityManagerFactoryWrapper implements EntityManagerFactory {
        private EntityManagerFactory factory;
        private FactoryManager factoryManager;
        private int counter = 1;
        private File database;
        
        /**
         * Default constructor.
         * @param factory the factory to delegate to calls to.
         * @param factoryManager the factory manager used for the lifecycle management.
         * @param database the database this object is connected to.
         */
        public EntityManagerFactoryWrapper(EntityManagerFactory factory,
                FactoryManager factoryManager, File database) {
            this.factory = factory;
            this.factoryManager = factoryManager;
            this.database = database;
        }

        /**
         * Method used by the factoryManager to reference the usage of the 
         * EntityFactoryManager.
         */
        public synchronized void reference() {
            counter++;
        }

        /**
         * {@inheritDoc}
         * This method overrides the default close implementation, and will
         * only close the EntityManagerFactory, if all application have stopped
         * using the EntityManagerFactory.
         * It interacts with the factoryManager.
         */
        public synchronized void close() {
            counter--;
            if (counter == 0) {
                factoryManager.remove(this);
                factory.close();
                factoryManager.unload(database);
            }
        }

        /**
         * {@inheritDoc}
         */
        public EntityManager createEntityManager() {
            return factory.createEntityManager();
        }

        /**
         * {@inheritDoc}
         */
        @SuppressWarnings("unchecked")
        public EntityManager createEntityManager(Map properties) {
            return factory.createEntityManager(properties);
        }

        /**
         * {@inheritDoc}
         */
        public Cache getCache() {
            return factory.getCache();
        }

        /**
         * {@inheritDoc}
         */
        public CriteriaBuilder getCriteriaBuilder() {
            return factory.getCriteriaBuilder();
        }

        /**
         * {@inheritDoc}
         */
        public Metamodel getMetamodel() {
            return factory.getMetamodel();
        }

        /**
         * {@inheritDoc}
         */
        public PersistenceUnitUtil getPersistenceUnitUtil() {
            return factory.getPersistenceUnitUtil();
        }

        /**
         * {@inheritDoc}
         */
        public Map<String, Object> getProperties() {
            return factory.getProperties();
        }

        /**
         * {@inheritDoc}
         */
        public boolean isOpen() {
            return factory.isOpen();
        }
        
        /**
         * {@inheritDoc}
         */
        public File getDatabase() {
            return database;
        }
    }

}
