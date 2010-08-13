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

import java.util.ArrayList;
import java.util.Collection;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.DataType;


/**
 * This class provides filter input to the metadata task.
 * <pre>
 * &lt;metadatafilter severity=&quot;error&quot; regex=&quot;&quot; description=&quot;&quot; /&gt;
 * </pre>
 * @ant.task name="metadatafilter" category="Metadata"
 */
public class MetaDataFilter extends DataType implements MetaDataFilterCollection {

    private SeverityEnum.Severity severity;
    private String regex;
    private String description;
    private Pattern pattern;
    

    /**
     * Defines what is the severity level for this pattern
     * @param severity type of severity for this input.
     */
    @Deprecated
    public void setPriority(SeverityEnum severity) {
        setSeverity(severity);
    }

    /**
     * Defines what is the severity level for this pattern
     * @param severity type of severity for this input.
     */
    public void setSeverity(SeverityEnum severity) {
        this.severity = severity.getSeverity();
    }

    /**
     * Helper function to return the severity type
     * @return severity type
     * @ant.required
     */
    public SeverityEnum.Severity getSeverity() {
        return severity;
    }

    /**
     * Helper function called by ant to set the regex
     * @param regx regular expression of the filter
     * @ant.required
     */
    public void setRegex(String regex) {
        if (regex == null || regex.trim().length() == 0) {
            throw new BuildException("Invalid Regular expression: the regex attribute cannot be an empty string.");
        }
        this.regex = regex;
        try {
            pattern = Pattern.compile(this.regex);
        } catch (PatternSyntaxException ex) {
            throw new BuildException("Invalid regular expression: " + ex.getMessage(), ex);
        }
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
     * @ant.required
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
     * Helper function to return the pattern
     * @return the pattern of this filter.
     */
    public Pattern getPattern() {
        return pattern;
    }

    /**
     * {@inheritDoc}
     */
    public Collection<MetaDataFilter> getAllFilters() {
        Collection<MetaDataFilter> result = new ArrayList<MetaDataFilter>();
        if (this.isReference()) {
            result.add((MetaDataFilter)this.getRefid().getReferencedObject());  
        } else {
            result.add(this);
        }
        return result;
    }
}


