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

 
package com.nokia.helium.metadata.ant.types;

import org.apache.tools.ant.types.DataType;
import org.apache.log4j.Logger;
import java.util.regex.Pattern;


/**
 * This class provides filter input to the metadata task.
 * <pre>
 * &lt;metadatafilter priority=&quot;error&quot; regex=&quot;&quot; description=&quot;&quot; /&gt;
 * </pre>
 * @ant.task name="metadatafilter" category="Metadata"
 */
public class MetaDataFilter extends DataType
{

    private Logger log = Logger.getLogger(MetaDataFilter.class);

    private String priority;
    private String regex;
    private String description;
    private Pattern pattern;
    

    /**
     * Helper function called by ant to set the priority type
     * @param priority type of priority for this input.
     */
    public void setPriority(String prty) throws Exception {
        if (prty == null || prty.trim().length() == 0) {
            throw new Exception(" Invalid Priority");
        }
        priority = prty;
    }

    /**
     * Helper function to return the priority type
     * @return priority type
     */
    public String getPriority() {
        return priority;
    }

    /**
     * Helper function called by ant to set the regex
     * @param regx regular expression of the filter
     */
    public void setRegex(String regx) throws Exception {
        if (regx == null || regx.trim().length() == 0) {
            throw new Exception(" Invalid Regular expression");
        }
        regex = regx;
        createPattern(regx);
    }

    /**
     * Helper function to return the regex type
     * @return regular expression of this filter
     */
    public String getRegex() {
        return regex;
    }    

    /**
     * Helper function called by ant to set the description type
     * @param desc description associated with filter.
     */
    public void setDescription(String desc) {
        description = desc;
    }

    /**
     * Helper function to return the description associated with regular expression
     * @return description associated with regex.
     */
    public String getDescription() {
        return description;
    }
    
    /**
     * Internal function to create the pattern
     * @regex for which the pattern is created.
     */
    private void createPattern(String regex) {
        pattern = Pattern.compile(regex);
    }
    
    /**
     * Helper function to return the pattern
     * @return the pattern of this filter.
     */
    public Pattern getPattern() {
        return pattern;
    }
}


