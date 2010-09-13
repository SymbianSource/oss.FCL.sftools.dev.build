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

import java.io.File;
import java.util.List;

import javax.persistence.NoResultException;
import javax.persistence.TypedQuery;

import com.nokia.helium.metadata.JpaDAO;

/**
 * Implements DAO for the Unit.
 * Contains all helpers related to Unit manipulation.
 *
 */
public class SysdefUnitDAO extends JpaDAO<SysdefUnit> {
    
    /**
     * Get a map of units rows based on the unit name.
     * @return a map of (unitName, unit).
     */
    public List<SysdefUnit> getUnits() {
        return this.getEntityManager().createQuery("SELECT c from SysdefUnit c", SysdefUnit.class).getResultList();
    }

    /**
     * Get a unit based on its model Id.
     * @param id
     * @return the entity representing the unit of null if not found.
     */
    public SysdefUnit getUnitByLocation(File epocroot, File location) {
        return getUnitByLocation(epocroot.toURI().relativize(location.toURI()).getPath());
    }

    public SysdefUnit getUnitByLocation(String location) {
        TypedQuery<SysdefUnit> query = this.getEntityManager().createQuery("SELECT u from SysdefUnit u where u.location=?1", SysdefUnit.class);
        query.setParameter(1, location);
        try {
            return query.getSingleResult();
        } catch (NoResultException ex) {
            return null;
        }
    }
    
}
