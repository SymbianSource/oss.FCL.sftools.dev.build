
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
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;




/**
 * Entity Class stores the severity.
 */
@Entity
public class Severity {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(name = "SEVERITY_ID")
    private int id;

    @Basic
    @Column(name = "SEVERITY")
    private String severity;


    /**
     * Helper function to set the severity string.
     * @param prty - severity string to be stored for this
     * severity object.
     */
    public void setSeverity(String severity) {
        this.severity = severity.toUpperCase();
    }

    /**
     * Helper function to get the severity of the severity object
     * @return severity string of this severity object.
     */
    public String getSeverity() {
        return severity.toUpperCase();
    }

    /**
     * Set the identifier of this severity object in the database.
     * @param id for this severity in the database
     */
    public void setId(int identifier) {
        id = identifier;
    }

    /**
     * Gets the identifier of the severity object.
     * @return id of this severity object.
     */
    public int getId() {
        return id;
    }

}