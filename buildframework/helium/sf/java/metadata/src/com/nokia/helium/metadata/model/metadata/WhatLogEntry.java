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

import javax.persistence.Basic;
import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;


/**
 * Entity class to store the component information.
 */
@Entity
public class WhatLogEntry {

    public static final int PATH_MAX = 4096;
    
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(name = "WHATLOG_ENTRY_ID")
    private int id;

    @Basic
    @Column(name = "COMPONENT_ID", insertable = false, updatable = false)
    private int componentId;

    @Basic
    @Column(name = "MEMBER", nullable = false, length = PATH_MAX)
    private String member;

    @Basic
    @Column(name = "MISSING")
    private boolean missing;

    @ManyToOne(cascade = CascadeType.ALL)
    @JoinColumn(name = "COMPONENT_ID", referencedColumnName = "COMPONENT_ID")
    private Component component;

    /**
     * Helper function to set the identifier.
     * @param identifier to set the identifier for the component.
     */
    public void setId(int identifier) {
        id = identifier;
    }

    /**
     * Helper function to set the identifier.
     * @return the identifier of the component.
     */
    public int getId() {
        return id;
    }

    /**
     * Helper function to set component name.
     * @param cmp string to be set to.
     */
    public void setComponent(Component cmp) {
        component = cmp;
    }

    /**
     * Helper function to set log file associated
     * with this component.
     * @param file associated file to this component.
     */
    public void setMember(String member) {
        // Truncate the string if it doesn't fit to the schema.
        if (member.length() > PATH_MAX) {
            member = member.substring(0, PATH_MAX);
        }
        this.member = member;
    }

    /**
     * Helper function to return component string.
     * @return component name of this component.
     */
    public Component getComponent() {
        return component;
    }

    /**
     * Helper function to return log file associated with this component.
     * @return component name of this component.
     */
    public String getMember() {
        return member;
    }

    public void setMissing(boolean nonexistance) {
        missing = nonexistance;
    }

    public boolean getMissing() {
        return missing;
    }

    public int getComponentID() {
        return componentId;
    }

    public void setComponentId(int componentId) {
        this.componentId = componentId;
    }
}