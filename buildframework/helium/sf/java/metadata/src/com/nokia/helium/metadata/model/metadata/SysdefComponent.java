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
 * System definition component. 
 *
 */
@SuppressWarnings("PMD.UnusedPrivateField")
@Entity
public class SysdefComponent {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(name = "COMPONENT_ID")
    private int id;
        
    @Column(name = "ID", nullable = false, unique = true, length = 255)
    private String componentId;

    @Column(name = "NAME", nullable = false, length = 255)
    private String name;
    
    @Column(name = "COLLECTION_ID", insertable = false, updatable = false, nullable = false)
    private int collectionId;

    @ManyToOne(cascade = CascadeType.REMOVE)
    @JoinColumn(name = "COLLECTION_ID", referencedColumnName = "COLLECTION_ID")
    private SysdefCollection sysdefCollection;
    
    @OneToMany
    @JoinColumn(name = "COMPONENT_ID", referencedColumnName = "COMPONENT_ID")
    private List<SysdefUnit> sysdefUnits;

    public void setCollectionId(int collectionId) {
        this.collectionId = collectionId;
    }

    public int getCollectionId() {
        return collectionId;
    }

    public void setComponentId(String componentId) {
        this.componentId = componentId;
    }

    public String getComponentId() {
        return componentId;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getId() {
        return id;
    }

    public void setSysdefCollection(SysdefCollection sysdefCollection) {
        this.sysdefCollection = sysdefCollection;
    }

    public SysdefCollection getSysdefCollection() {
        return sysdefCollection;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }
}
