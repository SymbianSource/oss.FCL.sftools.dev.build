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
package com.nokia.helium.logger.ant.types;

import org.apache.tools.ant.types.DataType;


/**
 * A <code>Stage</code> is a Data type which stores Stage information.
 * 
 * <p>
 * A Stage is defined by setting three attributes name, start and end targets, both should be a
 * valid target name in the project.
 * 
 * <p>
 * Usage:
 * 
 * <pre>
 *      &lt;hlm:stage id="preparation" starttarget="stagetest" endtarget="stagetest"/&gt;              
 * </pre>
 *  
 * @ant.task name="stage" category="Logging"
 * 
 */
public class Stage extends DataType {

    private String startTarget;
    private String endTarget;

    public Stage() {
        
    }
    /**
     * Get the starting point of this {@link Stage}.
     * 
     * @return the starting point of this {@link Stage}.
     */
    public String getStartTarget() {
        return this.startTarget;
    }

    /**
     * Set the starting target.
     * 
     * @param start
     *            is the starting point to set.
     * @ant.required
     */
    public void setStartTarget(String startTarget) {
        this.startTarget = startTarget;
    }

    /**
     * Get the end point of this {@link Stage}.
     * 
     * @return the end point of this {@link Stage}.
     * 
     */
    public String getEndTarget() {
        return this.endTarget;
    }

    /**
     * Set the end target.
     * 
     * @param end
     *            is the end point to set.
     * @ant.required
     */
    public void setEndTarget(String endTarget) {
        this.endTarget = endTarget;
    }
    
    /**
     * Check is the start target set to current target. 
     * @param target
     * @return
     */
    public boolean isStartTarget ( String target ) {
        return this.startTarget.equals( target );
    }
    
    /** Check is the end target set to current target.
     * 
     * @param target
     * @return
     */
    public boolean isEndTarget ( String target ) {
        return this.endTarget.equals( target );
    }
    
}
