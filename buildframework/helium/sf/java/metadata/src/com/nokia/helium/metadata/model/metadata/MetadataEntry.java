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
 * Entity class which stores the the mapping of all the other tables
 * along with actual error information.
 */
@SuppressWarnings("PMD.UnusedPrivateField")
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
    @Column(name = "SEVERITY_ID", insertable = false, updatable = false)
    private int severityId;

    @ManyToOne(cascade = CascadeType.REMOVE, optional = false)
    @JoinColumn(name = "COMPONENT_ID", referencedColumnName = "COMPONENT_ID")
    private Component component;

    @ManyToOne(cascade = CascadeType.REFRESH, optional = false)
    @JoinColumn(name = "SEVERITY_ID", referencedColumnName = "SEVERITY_ID")
    private Severity severity;

    @Column(name = "LOGFILE_ID", insertable = false, updatable = false)
    private int logFileId;
    
    @ManyToOne(cascade = CascadeType.REMOVE, optional = false)
    @JoinColumn(name = "LOGFILE_ID", referencedColumnName = "LOGFILE_ID")
    private LogFile logFile;
    
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
     * Helper function to set the severity object associated to this entry.
     *  @param severity object associated to this entry.
     */
    public void setSeverity(Severity severity) {
        this.severity = severity;
    }

    /**
     * Helper function to set the component object associated to this entry.
     *  @param component object associated to this entry.
     */
    public void setComponent(Component component) {
        this.component = component;
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
    public void setText(String text) {
        // Let's trunk ourselves the text we are passing to the 
        // storage.
        if (text.length() > TEXT_LENGTH) {
            text = text.substring(0, TEXT_LENGTH);
        }
        this.text = text;
    }

    /**
     * Helper function to set the line number for this entry.
     *  @param line number associated to this entry.
     */
    public void setLineNumber(int lineNumber) {
        this.lineNumber = lineNumber;
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
    public int getLogFileId() {
        return logFileId;
    }

    /**
     * Helper function to set the logpath id associated to this entry.
     *  @param id logpath id of this entry.
     */
    public void setLogFileId(int id) {
        logFileId = id;
    }

    /**
     * Helper function to set the severity id associated to this entry.
     *  @param severityId severity id of this entry.
     */
    public void setSeverityId(int severityId) {
        this.severityId = severityId;
    }

    /**
     * Helper function to set the component id associated to this entry.
     *  @param componentId component id of this entry.
     */
    public void setComponentId(int componentId) {
        this.componentId = componentId;
    }
}