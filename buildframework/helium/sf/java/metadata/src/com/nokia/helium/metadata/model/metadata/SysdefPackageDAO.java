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
 * Implements DAO for the Package.
 * Contains all helpers related to Package manipulation.
 *
 */
public class SysdefPackageDAO extends JpaDAO<SysdefPackage> {

    /**
     * Get a map of packages rows based on the package name.
     * @return a map of (pkgname, Package).
     */
    public Map<String, SysdefPackage> getPackages() {
        Map<String, SysdefPackage> result = new Hashtable<String, SysdefPackage>();
        for (SysdefPackage pkg : this.getEntityManager().createQuery("SELECT p from SysdefPackage p", SysdefPackage.class).getResultList()) {
            result.put(pkg.getPackageId(), pkg);
        }
        return result;
    }

    /**
     * Get an package based on its model Id.
     * @param id
     * @return the entity representing the package of null if not found.
     */
    public SysdefPackage getPackageById(String id) {
        TypedQuery<SysdefPackage> query = this.getEntityManager().createQuery("SELECT p from SysdefPackage p where p.packageId=?1", SysdefPackage.class);
        query.setParameter(1, id);
        try {
            return query.getSingleResult();
        } catch (NoResultException ex) {
            return null;
        }
    }
}
