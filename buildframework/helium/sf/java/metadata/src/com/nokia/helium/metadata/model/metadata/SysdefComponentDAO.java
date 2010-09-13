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
package com.nokia.helium.metadata.model.metadata;

import java.util.Hashtable;
import java.util.Map;

import javax.persistence.NoResultException;
import javax.persistence.TypedQuery;

import com.nokia.helium.metadata.JpaDAO;

/**
 * Implements DAO for the Component.
 * Contains all helpers related to Component manipulation.
 *
 */
public class SysdefComponentDAO extends JpaDAO<SysdefComponent> {

    /**
     * Get a map of components rows based on the component name.
     * @return a map of (componentName, component).
     */
    public Map<String, SysdefComponent> getComponents() {
        Map<String, SysdefComponent> result = new Hashtable<String, SysdefComponent>();
        for (SysdefComponent component : this.getEntityManager().createQuery("SELECT c from SysdefComponent c", SysdefComponent.class).getResultList()) {
            result.put(component.getComponentId(), component);
        }
        return result;
    }

    /**
     * Get a component based on its model Id.
     * @param id
     * @return the entity representing the component of null if not found.
     */
    public SysdefComponent getComponentById(String id) {
        TypedQuery<SysdefComponent> query = this.getEntityManager().createQuery("SELECT c from SysdefComponent c where c.componentId=?1", SysdefComponent.class);
        query.setParameter(1, id);
        try {
            return query.getSingleResult();
        } catch (NoResultException ex) {
            return null;
        }
    }
}
