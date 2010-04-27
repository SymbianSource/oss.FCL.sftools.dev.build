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
 * Recorder Filter will be used to filter the ant logging output.
 * 
 *  To get the lines which matches the regular expression.
 *  
 * <pre>
 *      &lt;hlm:recordfilter category="info" regexp="ERROR"/&gt;
 *      &lt;hlm:recordfilter category="warn" regexp="^WARN"/&gt;
 * </pre>
 * 
 * @ant.task name="Recordfilter" category="Logging".
 *
 */

public class RecordFilter extends DataType {
    
    private String category;
    private String regExp;
    
    
    /**
     * Set category.
     * @param category
     * @ant.not-required
     */
    public void setCategory(String category) {
        this.category = category;
    }
    
    /**
     * Return the category.
     * @return
     */
    public String  getCategory() {
        return this.category;
    }
    
    /**
     * Sets the regExp.
     * @param regExp
     * @ant.required
     */
    public void setRegExp(String regExp) {
        this.regExp = regExp;
    }
    
    
    /**
     * get the regExp.
     * @return
     */
    public String  getRegExp() {
        return this.regExp;
    }

}
