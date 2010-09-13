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

package com.nokia.helium.metadata.ant.conditions;


import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.taskdefs.condition.Condition;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.metadata.ant.types.MetaDataFilter;
import com.nokia.helium.metadata.ant.types.MetaDataFilterSet;
import com.nokia.helium.metadata.ant.types.SeverityEnum;

/**
 * This class implements a Ant Condition which report true if it finds the given 
 * input string is matched against the given filter of given severity
 * 
 * Example:
 * <pre> 
 *    &lt;target name=&quot;test-metadata-regex&quot;&gt;
 *      &lt;au:assertTrue&gt;
 *          &lt;hlm:metadataRegexTest severity=&quot;ERROR&quot; string=&quot;Error:&quot;&gt;
 *              &lt;metadatafilterset refid=&quot;filterset.sbs&quot;/&gt;
 *          &lt;/hlm:metadataRegexTest&gt;
 *       &lt;/au:assertTrue&gt;
 *   &lt;/target&gt;
 * </pre>
 * 
 * The condition will eval as true if the string is matched with any of the pattern in the given severity
 * 
 * @ant.type name="metadataRegexTest" category="Metadata"
 */
public class MetaDataRegexTestCondition extends DataType implements Condition {

    private SeverityEnum severity;
    private String string;  
    
    private List<MetaDataFilterSet> filterSets = new ArrayList<MetaDataFilterSet>();
    
    /**
     * Sets which severity to be searched.
     * 
     * @param severity
     * @ant.required
     */
    public void setSeverity(SeverityEnum severity) {
        this.severity = severity;
    }
    /**
     * Sets which string to be matched against regular expression.
     * 
     * @param string
     * @ant.required
     */
    public void setString(String string) {
        this.string = string;
    }

    /**
     * Helper function to add the created filter
     * @param filter to be added to the filterset
     */
    public void add(MetaDataFilterSet filterSet) {
        if (filterSet != null) {
            filterSets.add(filterSet);
        }
    }

    
    
    /**
     * This method iterates through the regular expression patterns and match the input string against them.
     * @return true if the string is matched with any of the pattern in the given severity, false otherwise.
     */
    public boolean eval() {
        if (this.severity == null) {
            throw new BuildException("'severity' attribute is not defined");
        }
        if (this.string == null || (this.string != null && this.string.isEmpty())) {
            throw new BuildException("'string' attribute is not defined");
        }
        for (MetaDataFilterSet set : filterSets) {
            for (MetaDataFilter filter : set.getAllFilters()) {
                Pattern pattern = filter.getPattern();
                Matcher matcher = pattern.matcher(this.string);
                if (matcher.matches()) {
                    return severity.getSeverity().equals(filter.getSeverity());
                }
            }
        }
        return false;
    }
}
