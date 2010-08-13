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

import javax.persistence.Basic;
import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.OneToMany;
import javax.persistence.OneToOne;


/**
 * Entity class to store the component information.
 */
@SuppressWarnings("PMD.UnusedPrivateField")
@Entity
public class Component {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(name = "COMPONENT_ID")
    private int id;

    @Basic
    @Column(nullable = false, length = 500)
    private String component;

    @Basic
    @Column(name = "LOGFILE_ID", insertable = false, updatable = false)
    private int logFileId;

    @Basic
    @Column(name = "UNIT_ID", insertable = false, updatable = false)
    private int unitId;

    @ManyToOne(cascade = CascadeType.REMOVE)
    @JoinColumn(name = "LOGFILE_ID", referencedColumnName = "LOGFILE_ID")
    private LogFile logFile;

    @OneToMany(cascade = CascadeType.REMOVE)
    @JoinColumn(name = "COMPONENT_ID", referencedColumnName = "COMPONENT_ID")
    private List<WhatLogEntry> whatLogEntries;

    @OneToMany(cascade = CascadeType.REMOVE)
    @JoinColumn(name = "COMPONENT_ID", referencedColumnName = "COMPONENT_ID")    
    private List<ComponentTime> componentTimes;

    @OneToMany(cascade = CascadeType.REMOVE)
    @JoinColumn(name = "COMPONENT_ID", referencedColumnName = "COMPONENT_ID")
    private List<MetadataEntry> metadataEntries;

    @OneToOne
    @JoinColumn(name = "UNIT_ID", referencedColumnName = "UNIT_ID")
    private SysdefUnit sysdefUnit;
    
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
    public void setComponent(String cmp) {
        component = cmp;
    }

    /**
     * Helper function to set log file associated
     * with this component.
     * @param file associated file to this component.
     */
    public void setLogFile(LogFile file) {
        logFile = file;
    }

    /**
     * Helper function to return component string.
     * @return component name of this component.
     */
    public String getComponent() {
        return component;
    }

    /**
     * Helper function to return log file associated with this component.
     * @return component name of this component.
     */
    public LogFile getLogFile() {
        return logFile;
    }

    /**
     * Helper function to return logpath id.
     * @return log path id associated with this component.
     */
    public int getLogFileId() {
        return logFileId;
    }

    /**
     * Set the related Package. 
     * @param modelPackage the related package entity
     */    
    public void setSysdefUnit(SysdefUnit sysdefUnit) {
        this.sysdefUnit = sysdefUnit;
    }

    /**
     * Get the related Package. 
     * @return Returns the related package entity, null if the component
     *         is not link to any Package.
     */
    
    public SysdefUnit getSysdefUnit() {
        return sysdefUnit;
    }

    public void setUnitId(int unitId) {
        this.unitId = unitId;
    }

    public int getUnitId() {
        return unitId;
    }
}