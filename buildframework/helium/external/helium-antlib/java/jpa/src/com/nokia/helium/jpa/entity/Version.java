
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
package com.nokia.helium.jpa.entity;

import javax.persistence.Entity;


import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Column;
import javax.persistence.Basic;


/**
 *  Entity Version to store the db version.
 */
@Entity
public class Version {

    public static final transient int DB_VERSION = 2;

    
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(name = "VERSION_ID")
    private int id;

    //DB_VERSION to set as default if version changes
    @Basic
    @Column(unique = true, nullable = false)
    private int version = DB_VERSION;

    /**
     *  Helper function to set the identifier for the log file.
     *  @param identifier for the log file.
     */
    public void setId(int identifier) {
        id = identifier;
    }

    /**
     *  Helper function to get the identifier for the db schema version.
     *  @return identifier for this log file.
     */
    public int getId() {
        return id;
    }

    /**
     *  Helper function to set the db schema version.
     *  @param location of the log file.
     */
    public void setVersion(int ver) {
        version = ver;
    }

    /**
     *  Helper function to return the current db schema version.
     *  @return path of the log file..
     */
    public int getVersion() {
        return version;
    }
}