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
 
package com.nokia.ant.types;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;
import java.util.regex.Pattern;

/**
 * This object contains log filter information basically a regular expression to use to filter the properties based on type and category.
 * @Deprecated Start using hlm:recordfilter.
 * @ant.type name="logfilter"
 */
@Deprecated
public class LogFilter extends DataType
{
    private String type;
    private String regex;
    private String category;
    private java.util.regex.Pattern compileRegex;
    
    public LogFilter() {
        log("Deprecated Start using hlm:recordfilter", Project.MSG_WARN);
    }
    
    /**
     * Set the type.
     * @param type
     */
    public void setType(String type) {
//        assertValid("name", name);
        this.type = type;
    }

    /**
     * Set the regular expression to use to filter the properties.
     * @param regex a regular expression.
     */
    public void setRegex(String regex) {
//        assertValid("regex", regex);
        this.regex = regex;
        compileRegex = java.util.regex.Pattern.compile(regex);
    }

    /**
     * Set the catagory.
     * @param cat value of the catagory.
     */    
    public void setCategory(String cat) {
//      assertValid("regex", regex);
      this.category = cat;
    }
    
     /**
     * Get the compile regex.
     * @return compileRegex.
     */
    public Pattern getCompileRegex() {
        return compileRegex;
    }

     /**
     * Get the regex.
     * @return regex.
     */
    public String getRegex() {
        return regex;
    }
     /**
     * Get the category.
     * @return category.
     */
    public String getCategory() {
        return category;
    }
}
