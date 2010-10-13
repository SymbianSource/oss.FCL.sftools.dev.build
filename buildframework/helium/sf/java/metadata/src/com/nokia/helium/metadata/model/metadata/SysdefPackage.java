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

import java.util.List;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.OneToMany;

/**
 * This class represent the PACKAGE table in the
 * database.
 * Each package name will be unique across the build
 * that is why it is not link to any specific logFile. 
 */
@SuppressWarnings("PMD.UnusedPrivateField")
@Entity
public class SysdefPackage {
    
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(name = "PACKAGE_ID")
    private int id;

    @Column(name = "ID", nullable = false, unique = true, length = 255)
    private String packageId;

    @Column(name = "NAME", length = 255)
    private String name;
    
    @OneToMany
    @JoinColumn(name = "PACKAGE_ID", referencedColumnName = "PACKAGE_ID")
    private List<SysdefCollection> sysdefCollections;

    /**
     * Set the id of the row.
     * @param id
     */
    public void setId(int id) {
        this.id = id;
    }

    /**
     * Get the id of the row.
     * @return the id
     */
    public int getId() {
        return id;
    }

    public void setPackageId(String packageId) {
        this.packageId = packageId;
    }

    public String getPackageId() {
        return packageId;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }
}
