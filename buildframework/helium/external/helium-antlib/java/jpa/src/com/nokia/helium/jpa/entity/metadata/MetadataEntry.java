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


import javax.persistence.CascadeType;
import javax.persistence.ManyToOne;
import javax.persistence.Column;
import javax.persistence.Basic;
import javax.persistence.JoinColumn;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;

/**
 * Entity class which stores the the mapping of all the other tables
 * along with actual error information.
 */
@Entity
public class MetadataEntry {

    /// Maximum size of the text we store in the metadata
    public static final int TEXT_LENGTH = 500;

    @Id
    @Column(name = "ENTRY_ID")
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    private int id;

    @Basic
    private int lineNumber;

    @Basic
    @Column(length = TEXT_LENGTH)
    private String text;

    @Basic
    @Column(name = "COMPONENT_ID", insertable = false, updatable = false)
    private int componentId;

    @Basic
    @Column(name = "PRIORITY_ID", insertable = false, updatable = false)
    private int priorityId;

    @ManyToOne(cascade = CascadeType.REMOVE, optional = false)
    @JoinColumn(name = "COMPONENT_ID", referencedColumnName = "COMPONENT_ID")
    private Component component;

    @ManyToOne(cascade = CascadeType.REMOVE, optional = false)
    @JoinColumn(name = "PRIORITY_ID", referencedColumnName = "PRIORITY_ID")
    private Priority priority;

    @Column(name = "LOGPATH_ID", insertable = false, updatable = false)
    private int logPathId;
    
    @ManyToOne(cascade = CascadeType.REMOVE, optional = false)
    @JoinColumn(name = "LOGPATH_ID", referencedColumnName = "LOGPATH_ID")
    private LogFile  logFile;
    
    /**
     * Helper function to get the identifier of the metadata record
     * which is being stored in the database.
     *  @return id - identifier for the log record.
     */
    public int getId() {
        return id;
    }

    /**
     * Helper function to set the logfile associated to the metadata entry.
     *  @param LogFile object associated to this entry.
     */
    public void setLogFile(LogFile file) {
        logFile = file;
    }

    /**
     * Helper function to set the priority object associated to this entry.
     *  @param priority object associated to this entry.
     */
    public void setPriority(Priority prty) {
        priority = prty;
    }

    /**
     * Helper function to set the component object associated to this entry.
     *  @param component object associated to this entry.
     */
    public void setComponent(Component cmpt) {
        component = cmpt;
    }

    /**
     * Helper function to set the identifier for this entry.
     *  @param id identifier to be set for this entry.
     */
    public void setId(int id) {
        this.id = id;
    }

    /**
     * Helper function to set the log text associated to this entry.
     *  @param txt - text representing this log entry.
     */
    public void setText(String txt) {
        // Let's trunk ourselves the text we are passing to the 
        // storage.
        if (txt.length() > TEXT_LENGTH) {
            txt = txt.substring(0, TEXT_LENGTH);
        }
        text = txt;
    }

    /**
     * Helper function to set the line number for this entry.
     *  @param line number associated to this entry.
     */
    public void setLineNumber(int number) {
        lineNumber = number;
    }

    /**
     * Helper function to get the text message associated to this entry.
     *  @return text message of this entry.
     */
    public String getText() {
        return text;
    }

    /**
     * Helper function to get line number of the error message associated
     * with this object.
     *  @return line number associated to this entry.
     */
    public int getLineNumber() {
        return lineNumber;
    }

    /**
     * Helper function to get the log path id of this entry.
     *  @return log path id associated to this entry.
     */
    public int getLogPathId() {
        return logPathId;
    }

    /**
     * Helper function to set the logpath id associated to this entry.
     *  @param id logpath id of this entry.
     */
    public void setLogPathId(int id) {
        logPathId = id;
    }

}