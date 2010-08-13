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
 * System definition unit.
 *
 */
@SuppressWarnings("PMD.UnusedPrivateField")
@Entity
public class SysdefUnit {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(name = "UNIT_ID")
    private int id;

    @Column(name = "LOCATION", nullable = false, length = 4096)
    private String location;

    @Column(name = "COMPONENT_ID", insertable = false, updatable = false, nullable = false)
    private int componentId;

    @ManyToOne(cascade = CascadeType.REMOVE)
    @JoinColumn(name = "COMPONENT_ID", referencedColumnName = "COMPONENT_ID")
    private SysdefComponent sysdefComponent;

    @OneToMany
    @JoinColumn(name = "UNIT_ID", referencedColumnName = "UNIT_ID")
    private List<Component> components;
    
    
    public void setId(int id) {
        this.id = id;
    }

    public int getId() {
        return id;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getLocation() {
        return location;
    }

    public void setComponentId(int componentId) {
        this.componentId = componentId;
    }

    public int getComponentId() {
        return componentId;
    }

    public void setSysdefComponent(SysdefComponent sysdefComponent) {
        this.sysdefComponent = sysdefComponent;
    }

    public SysdefComponent getSysdefComponent() {
        return sysdefComponent;
    }
}
