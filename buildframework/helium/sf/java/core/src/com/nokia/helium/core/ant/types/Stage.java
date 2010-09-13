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

 
package com.nokia.helium.core.ant.types;

import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.BuildException;
import org.apache.log4j.Logger;
    
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
 * @ant.type name="stage" category="Core"
 * 
 */
public class Stage extends DataType {

    //Default id is used as the stage name so overriding is possible.
    private Logger log = Logger.getLogger(Stage.class);
    private String stageName;
    
    private String startTarget;
    
    private String endTarget;

    public void setStageName(String name) {
        log.debug("stage-name:" + name);
        if (stageName != null) {
            throw new BuildException("no supported attribute stageName externally");
        }
        stageName = name;
    }
    
    public String getStageName() {
        return stageName;
    }
    /**
     * Returns the stage start target. 
     * @return stage start target name. 
     */
    public String getStartTarget() {
        return startTarget;
    }

    /**
     * Returns the stage end target.
     * @return end target name
     */
    public String getEndTarget() {
        return endTarget;
    }

    /**
     * Set the starting target.
     * 
     * @param start is the starting point to set.
     * @ant.required
     */
    public void setStartTarget(String name) {
        startTarget = name;
    }

    /**
     * Set the end target.
     * 
     * @param end is the end point to set.
     * @ant.required
     */
    public void setEndTarget(String name) {
        endTarget = name;
    }
    
    /** Check is the end target set to current target.
     * 
     * @param target
     * @return
     */
    public boolean isEndTarget( String target ) {
        return this.endTarget.equals( target );
    }    
}