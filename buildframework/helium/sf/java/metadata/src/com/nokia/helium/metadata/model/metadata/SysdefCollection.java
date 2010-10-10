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

import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.OneToMany;

/**
 * System definition collection. 
 *
 */
@SuppressWarnings("PMD.UnusedPrivateField")
@Entity
public class SysdefCollection {
    
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(name = "COLLECTION_ID")
    private int id;
    
    @Column(name = "ID", nullable = false, unique = true, length = 255)
    private String collectionId;

    @Column(name = "NAME", length = 255)
    private String name;

    @Column(name = "PACKAGE_ID", insertable = false, updatable = false, nullable = false)
    private int packageId;

    @ManyToOne(cascade = CascadeType.REMOVE)
    @JoinColumn(name = "PACKAGE_ID", referencedColumnName = "PACKAGE_ID")
    private SysdefPackage sysdefPackage;

    @OneToMany
    @JoinColumn(name = "COLLECTION_ID", referencedColumnName = "COLLECTION_ID")
    private List<SysdefComponent> sysdefComponents;
    
    
    public void setSysdefPackage(SysdefPackage sysdefPackage) {
        this.sysdefPackage = sysdefPackage;
    }

    public SysdefPackage getSysdefPackage() {
        return sysdefPackage;
    }

    public void setCollectionId(String collectionId) {
        this.collectionId = collectionId;
    }

    public String getCollectionId() {
        return collectionId;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getId() {
        return id;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public void setPackageId(int packageId) {
        this.packageId = packageId;
    }

    public int getPackageId() {
        return packageId;
    }
}
