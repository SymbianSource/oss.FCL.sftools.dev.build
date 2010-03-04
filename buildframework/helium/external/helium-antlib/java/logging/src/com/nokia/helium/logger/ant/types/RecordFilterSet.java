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

import java.util.Vector;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.types.Reference;

/**
 * Recorder Filter set will be used to group the recorder filters to filter ant logging output.
 * 
 *  To get the lines which matches the regular expression.
 *  
 * <pre>
 *      &lt;hlm:recordfilterset id="recordfilter.config"&gt;
 *          &lt;hlm:recordfilter category="error" regexp="Hello" /&gt;
 *          &lt;hlm:recordfilter category="warning" regexp="echo" /&gt;
 *          &lt;hlm:recordfilter category="info" regexp="ERROR" /&gt;
 *      &lt;/hlm:recordfilterset>
 *      
 * </pre>
 * 
 * @ant.task name="Recordfilterset" category="Logging".
 *
 */

public class RecordFilterSet extends DataType {
    
    private Vector<RecordFilter> recordFilters = new Vector<RecordFilter>();
    
    public RecordFilterSet() {
    }
    
    /**
     * Add the recordefilter type into recordfilterset.
     * @param logFilter
     */
    public void addRecordFilter(RecordFilter logFilter) {
        if (!recordFilters.contains(logFilter)) {
            recordFilters.add(logFilter);
        }
    }
    
    
    /**
     * return all the recorderfilters associated with current recorderfilterset.
     * @return
     */
    public Vector<RecordFilter> getAllFilters() {
        Vector<RecordFilter> allFilters = new Vector<RecordFilter>();
        if (recordFilters.size() > 0) {
            allFilters.addAll(recordFilters);
            return allFilters;
        }
        Reference refId = getRefid();
        Object filterSetObject = null;
        if (refId != null) {
            try {
                filterSetObject = refId.getReferencedObject();
            } catch ( Exception ex) {
                throw new BuildException("Reference id of the record filter is not valid. " + ex.getMessage(), ex);
            }
            if (filterSetObject != null && filterSetObject instanceof RecordFilterSet) {
                allFilters.addAll(((RecordFilterSet)filterSetObject).getAllFilters());
                return allFilters;
            }
        }
        return allFilters;
    }

}
