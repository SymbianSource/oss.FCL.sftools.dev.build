
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
//import org.apache.tools.ant.BuildException;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.ManyToOne;
import javax.persistence.Column;
import javax.persistence.Basic;

/**
 * Entity Class stores the priority.
 */
@Entity
public class Priority {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(name = "PRIORITY_ID")
    private int id;

    @Basic
    @Column(name = "PRIORITY")
    private String priority;

    @ManyToOne
    private Metadata metadata;

    /**
     * Default constructor.
     */
    public Priority() {

    }

    /**
     * Helper function to set the priority string.
     * @param prty - priority string to be stored for this
     * priority object.
     */
    public void setPriority(String prty) {
        priority = prty;
    }

    /*
     * Helper function to get the priority of the priority object
     * @return priority string of this priority object.
     */
    public String getPriority() {
        return priority;
    }

    /*
     * Set the identifier of this priority object in the db.
     * @param id for this priority in the db
     */
    public void setId(int identifier) {
        id = identifier;
    }

    /*
     * Gets the identifier of the priority object.
     * @return id of this priority object.
     */
    public int getId() {
        return id;
    }
}