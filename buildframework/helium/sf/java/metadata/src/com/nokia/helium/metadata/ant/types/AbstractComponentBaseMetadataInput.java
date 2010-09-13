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

package com.nokia.helium.metadata.ant.types;

import java.util.Hashtable;
import java.util.Map;

import javax.persistence.EntityManager;

import com.nokia.helium.metadata.model.metadata.Component;
import com.nokia.helium.metadata.model.metadata.LogFile;

/**
 * LogMetaDataInput which implements some abstract component handling. 
 *
 */
public abstract class AbstractComponentBaseMetadataInput extends LogMetaDataInput {
    protected static final String DEFAULT_COMPONENT = "Default";
    private Map<String, Component> components = new Hashtable<String, Component>();
    private Component defaultComponent;
    
    /**
     * Provides an entity manager to manipulate the data.
     * @return
     */
    protected abstract EntityManager getEntityManager();
    
    /**
     * Defines the name of the default component.
     * @return a String with the name of the default component.
     */
    protected String getDefaultComponentName() {
        return DEFAULT_COMPONENT;
    }
    
    /**
     * Get the default component instance from the database.
     * Or create it if needed.
     * @param logFile logFile to associate the component to.
     * @return the Component instance. 
     */
    protected Component getDefaultComponent(LogFile logFile) {
        if (defaultComponent == null) {
            defaultComponent = getComponent(getDefaultComponentName(), logFile);
        }
        return defaultComponent;
    }

    /**
     * Get the database instance for the name component.
     * @param name the name of the component
     * @param logFile logFile to associate the component to.
     * @return the Component instance.
     */
    protected Component getComponent(String name, LogFile logFile) {
        if (!components.containsKey(name)) {
            Component component = createComponent(name, logFile);
            components.put(name, component);
            return component;
        }
        return components.get(name);
    }
    
    /**
     * Creates a new component. This method is called by the 
     * getComponent method if the component entity is not found
     * in the cache.
     * @param name the name of the component
     * @param logFile logFile to associate the component to.
     * @return the Component instance.
     */
    protected Component createComponent(String name, LogFile logFile) {
        Component component = new Component();
        component.setComponent(name);
        component.setLogFile(logFile);
        getEntityManager().getTransaction().begin();
        getEntityManager().persist(component);
        getEntityManager().getTransaction().commit();
        return component;
    }

    /**
     * Clear the components cache.
     */
    protected void clear() {
        components = new Hashtable<String, Component>();
        defaultComponent = null;
    }
}
