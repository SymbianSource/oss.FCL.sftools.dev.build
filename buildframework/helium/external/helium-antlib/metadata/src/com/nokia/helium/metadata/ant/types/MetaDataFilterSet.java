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

import java.io.*;
import java.util.*;
import org.apache.tools.ant.types.Reference;
import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.log4j.Logger;
import fmpp.models.CsvSequence;
import freemarker.template.TemplateSequenceModel;


/**
 * This type contains set of filters to be used by the metadatarecord. Two options:
 * <pre>
 * Example 1:
 * &lt;metadatafilterset id=&quot;common&quot; filterfile=&quot;filters.csv&quot; /&gt;
 * 
 * Example 2:
 * &lt;metadatafilterset id=&quot;common&quot;/&gt;
 *   &lt;metadatafilter priority=&quot;error&quot; regex=&quot;^make(?:\[\d+\])?:\s+.*\s+not\s+remade&quot; description=&quot;make error&quot; />
 *   &lt;metadatafilter priority=&quot;error&quot;regex=&quot;&quot; description=&quot;&quot; /&gt; 
 * &lt;metadatafilterset/&gt;
 *
 * Example 3:
 * &lt;metadatafilterset refid=&quot;common&quot; /&gt;
 * </pre>
 * @ant.task name="metadatafilterset" category="Metadata"
 */
public class MetaDataFilterSet extends DataType
{
    private Vector<MetaDataFilter> filters = new Vector<MetaDataFilter>();
    
    private Vector<MetaDataFilterSet> filterSets = new Vector<MetaDataFilterSet>();
    
    private String filterFile;
    
    private Logger log = Logger.getLogger(MetaDataFilterSet.class);

    /**
     * Helper function called by ant to set the FilterFile
     * @param FilterFile the csv file used by the filterset
     */
    public void setFilterFile(String file) throws Exception {
        filterFile = file;
        addCSVFromFile(file);
    }

    /**
     * Helper function called to get FilterFile.
     * @return filterfile used by this filterset
     */
    public String getFilterFile() {
        return filterFile;
    }

    /**
     * Helper function called to get filterlist.
     * FilterSet can contain nested filterset, individual filter.
     * Individual filter is created as nestedFilterSet and appended so that
     * the precedence is maintained.
     * @return All filters
     */
    public Vector<MetaDataFilter> getAllFilters()throws Exception {
        Vector<MetaDataFilter> allFilters = new Vector<MetaDataFilter>();
        //First look for filters associated with this set.
        if (filters.size() > 0) {
            allFilters.addAll(filters);
            return allFilters;
        }
        // Then filters as reference in filterset
        Reference refId = getRefid();
        Object filterSetObject = null;
        if (refId != null) {
            try {
                filterSetObject = refId.getReferencedObject();
            } catch ( Exception ex) {
                log.debug("Reference id of the metadata filter is not valid.", ex); 
                throw new BuildException("Reference id of the metadata filter is not valid " + ex.getMessage(), ex);
            }
            if (filterSetObject != null && filterSetObject instanceof MetaDataFilterSet) {
                allFilters.addAll(((MetaDataFilterSet)filterSetObject).getAllFilters());
                return allFilters;
            }
            log.debug("Filterset object is not instance of MetaDataFilterSet");
            throw new Exception ("Filterset object is not instance of MetaDataFilterSet");
        }
        // Add any nested filtersets
        for (MetaDataFilterSet filterSet : filterSets) {
            allFilters.addAll(filterSet.getAllFilters());
        }
        
        return removeInvalidFilters(allFilters);
    }

    /**
     * Helper function called to remove any invalid filters
     * @return only the valid filters
     */
    private Vector<MetaDataFilter> removeInvalidFilters(Vector<MetaDataFilter> filterList) {
        ListIterator<MetaDataFilter> iter = filterList.listIterator();
        while (iter.hasNext()) {
            MetaDataFilter filter = iter.next();
            String priority = filter.getPriority();
            String regEx = filter.getRegex();
            if (priority == null || regEx == null) {
                log("Warning: some filter is invalid removing it", Project.MSG_WARN);
                iter.remove();
            }
        }
        return filterList;
        
    }
    
    /**
     * Helper function called by ant to create the new filter
     */
    public MetaDataFilter createMetaDataFilter() {
        MetaDataFilter filter =  new MetaDataFilter();
        add(filter);
        return filter;
    }

    /**
     * Helper function to add the created filter
     * @param filter to be added to the filterset
     */
    public void add(MetaDataFilter filter) {
        MetaDataFilterSet filterSet = createMetaDataFilterSet();
        filterSet.getFilterList().add(filter);
    }

     Vector<MetaDataFilter> getFilterList() {
         return filters;
     }

     /**
     * Helper function called by ant to create the new filter
     */
    public MetaDataFilterSet createMetaDataFilterSet() {
        MetaDataFilterSet filterSet =  new MetaDataFilterSet();
        add(filterSet);
        return filterSet;
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
     * Helper function to add the filters from the csv files
     * @param csv file path from which the filters needs to be added.
     */
    private void addCSVFromFile(String csvPath) throws Exception {
        CsvSequence csvs = new CsvSequence();
        csvs.setSeparator(',');
        log.debug("filter file: " + filterFile);
        try {
            csvs.load(new FileReader(new File(filterFile)));
        } catch (java.io.FileNotFoundException fex) {
            log.debug("Metadata CSV file not found:", fex);
            throw fex;
        } catch (fmpp.util.StringUtil.ParseException pex) {
            log.debug("FMPP not able parse the Metadata CSV file. ", pex);
            throw pex;
        } catch (java.io.IOException iex) {
            log.debug("Metadata I/O Exception. " + iex.getMessage(), iex);
            throw iex;
        }
        int size = 0;
        try {
                log.debug("filter CSV record size: " + csvs.size());
                size = csvs.size();
            } catch (Exception ex) {
                // We are Ignoring the errors as no need to fail the build.
                log.debug("Exception in processing csv file " + filterFile, ex);
            }
            for (int i = 0; i < size; i++) {
                try {
                    TemplateSequenceModel model = (TemplateSequenceModel) csvs
                    .get(i);
                    int modelSize = model.size();
                    if (modelSize != 3 ) {
                        log.debug("Metadata CSV file filter file format is invalid. It has row size " + size);
                        throw new Exception("Metadata CSV file filter file format is invalid. It has row size " + size);
                    }
                    MetaDataFilter filter = new MetaDataFilter();
                    filter.setPriority(model.get(0).toString());
                    filter.setRegex(model.get(1).toString());
                    filter.setDescription(model.get(2).toString());
                    filters.add(filter);
                } catch (Exception ex) {
                    // We are Ignoring the errors as no need to fail the build.
                    log.debug("Exception in processing Metadate csv file " + filterFile, ex);
                }
            }
    }
}


