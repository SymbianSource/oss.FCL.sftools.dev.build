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
package com.nokia.helium.logger.ant.listener;

import static com.nokia.helium.logger.ant.listener.StageSummaryHandler.FAILED;
import static com.nokia.helium.logger.ant.listener.StageSummaryHandler.PASSED;

/**
 * <code>BuildStatusReport</code> is a simple java bean used to hold information pertaining
 * to various build stages.
 * 
 */
public class BuildStatusReport {

    private String phaseName;
    private String startTime;
    private String duration;
    private String reason;
    private String status;

    /**
     * Create an instance of {@link BuildStatusReport}.
     * 
     * @param phaseName is the name of the Phase
     * @param startTime is the start time of the Phase
     * @param duration is the duration of the Phase
     * @param reason is the cause of build failure, if any
     */
    public BuildStatusReport(String phaseName, String startTime,
            String duration, String reason) {
        this.phaseName = phaseName;
        this.startTime = startTime;
        this.duration = duration;
        this.reason = (reason != null && !reason.isEmpty()) ? reason : "N/A";
        this.status = (reason != null && !reason.isEmpty()) ? FAILED : PASSED; 
    }

    /**
     * Get the Build Phase name.
     * 
     * @return the Build Phase name.
     */
    public String getPhaseName() {
        return phaseName;
    }

    /**
     * Set the Build Phase name.
     * 
     * @param phaseName is the phase name to set.
     */
    public void setPhaseName(String phaseName) {
        this.phaseName = phaseName;
    }

    /**
     * Get the start time of this Phase.
     * 
     * @return the start time of this Phase.
     */
    public String getStartTime() {
        return startTime;
    }

    /**
     * Set the start time of this Phase.
     * 
     * @param startTime is the start time to set.
     */
    public void setStartTime(String startTime) {
        this.startTime = startTime;
    }

    /**
     * Get the duration of this Phase.
     * 
     * @return the duration of this Phase.
     */
    public String getDuration() {
        return duration;
    }

    /**
     * Set the duration of this Phase.
     * 
     * @param duration the duration to set.
     */
    public void setDuration(String duration) {
        this.duration = duration;
    }

    /**
     * Get the reason for build failure.
     * 
     * @return the reason for build failure.
     */
    public String getReason() {
        return reason;
    }

    /**
     * Set the reason for build failure.
     * 
     * @param reason is the reason for build failure.
     */
    public void setReason(String reason) {
        this.reason = reason;
    }

    /**
     * Get the build status.
     * 
     * @return the build status.
     */
    public String getStatus() {
        return status;
    }

    /**
     * Set the build status.
     * 
     * @param status is the build status to set.
     */
    public void setStatus(String status) {
        this.status = status;
    }
    
}
