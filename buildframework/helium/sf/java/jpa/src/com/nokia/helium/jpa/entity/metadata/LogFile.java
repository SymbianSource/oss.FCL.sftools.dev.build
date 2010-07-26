
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
package com.nokia.helium.jpa.entity.metadata;

import javax.persistence.Entity;


import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.ManyToOne;
import javax.persistence.Column;
import javax.persistence.Basic;


/**
 *  Entity LogFile to store the information about the log for
 *  which the data to be written to database.
 */
@Entity
public class LogFile {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(name = "LOGPATH_ID")
    private int id;

    @Basic
    @Column(unique = true, nullable = false, length = 500)
    private String path;

    @ManyToOne
    private Metadata metadata;

    /**
     *  Helper function to set the identifier for the log file.
     *  @param identifier for the log file.
     */
    public void setId(int identifier) {
        id = identifier;
    }

    /**
     *  Helper function to get the identifier for the log file.
     *  @return identifier for this log file.
     */
    public int getId() {
        return id;
    }

    /**
     *  Helper function to set the path of the log file.
     *  @param location of the log file.
     */
    public void setPath(String location) {
        path = location;
    }

    /**
     *  Helper function to get the path.
     *  @return path of the log file..
     */
    public String getPath() {
        return path;
    }
}