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

 
package com.nokia.helium.signal.ant.types;

import org.apache.tools.ant.types.DataType;
import java.util.Vector;
import org.apache.tools.ant.taskdefs.condition.Condition;

/**
 * TargetCondition class which is a type to store the condition for generating
 * Signals..
 * &lt;targetCondition&gt;
 *    &lt;hasSeverity severity="error" file="${build.cache.log.dir}/signals/prep_work_status.xml" /&gt;
 * &lt;/targetCondition&gt;
 */
public class TargetCondition extends DataType {

    private String name;
    
    private String errMsg;
    
    private Vector<Condition> conditionList = new Vector<Condition>();
    
    /**
     * Constructor
     */
    public TargetCondition() {
    }

    /**
     * Helper function to store the Name of the target for which
     * the signal to be processed. 
     * @param targetName to be stored.
     */    
    public void setName(String targetName) {
        name = targetName;
    }

    /**
     * Helper function to store the error message of
     * @param errorMessage to be displayed after failure.
     */        
    public void setMessage(String errorMessage) {
        errMsg = errorMessage;
    }
    
    /**
     * Add a given variable to the list 
     * @param condition variable to add
     */
    public void add(Condition condition) {
        conditionList.add(condition);
    }

    /**
     * Gets the list of conditions to be checked for the signal config. 
     * @return conditions variable for this configuration.
     */
    public Vector<Condition> getConditions() {
        return conditionList;
    }    
    /**
     * Helper function to return the Name of the target for which
     * the signal to be processed. 
     * @return name of the target of this targetcondition.
     * @deprecated
     */        
    public String getName() {
        return name;
    }

    /**
     * Helper function to return the error message of this target condition.
     * @return error message of this target condition.
     * @deprecated
     */        
    public String getMessage() {
        return errMsg;
    }
}