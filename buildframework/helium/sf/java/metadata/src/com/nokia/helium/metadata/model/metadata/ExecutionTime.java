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
import javax.persistence.OneToOne;


/**
 * Entity to store execution of some step/log.
 *
 */
@Entity
public class ExecutionTime {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(name = "EXECUTIONTIME_ID")
    private int id;
    
    @Basic
    private int time;

    @Basic
    @Column(name = "LOGFILE_ID", insertable = false, updatable = false, unique = true)
    private int logFileId;
    
    @OneToOne(cascade = CascadeType.REMOVE)
    @JoinColumn(name = "LOGFILE_ID", referencedColumnName = "LOGFILE_ID")
    private LogFile logFile;

    /**
     * Set record id.
     * @param id
     */
    public void setId(int id) {
        this.id = id;
    }
    
    /**
     * Get The record id.
     * @return
     */
    public int getId() {
        return id;
    }

    /**
     * Set the execution time in seconds.
     * @param time
     */
    public void setTime(int time) {
        this.time = time;
    }

    /**
     * Get the execution time in seconds.
     * @return
     */
    public int getTime() {
        return time;
    }

    /**
     * Set the logPathId.
     * @param logPathID
     */
    public void setLogFileId(int logFileId) {
        this.logFileId = logFileId;
    }

    /**
     * Get the logPathId.
     * @return
     */
    public int getLogFileId() {
        return logFileId;
    }

    /**
     * Set the logFile.
     * @param logFile
     */
    public void setLogFile(LogFile logFile) {
        this.logFile = logFile;
    }

    /**
     * Get the logFile.
     * @return
     */
    public LogFile getLogFile() {
        return logFile;
    }

}
