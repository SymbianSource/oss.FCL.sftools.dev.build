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

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.util.Collection;
import java.util.Vector;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;

import fmpp.models.CsvSequence;
import fmpp.util.StringUtil.ParseException;
import freemarker.template.TemplateModelException;
import freemarker.template.TemplateSequenceModel;


/**
 * This type contains set of filters to be used by the metadatarecord. Two options:
 * <pre>
 * Example 1:
 * &lt;metadatafilterset id=&quot;common&quot; filterfile=&quot;filters.csv&quot; /&gt;
 * 
 * Example 2:
 * &lt;metadatafilterset id=&quot;common&quot;/&gt;
 *   &lt;metadatafilter severity=&quot;error&quot; regex=&quot;^make(?:\[\d+\])?:\s+.*\s+not\s+remade&quot; description=&quot;make error&quot; />
 *   &lt;metadatafilter severity=&quot;error&quot;regex=&quot;&quot; description=&quot;&quot; /&gt; 
 * &lt;metadatafilterset/&gt;
 *
 * Example 3:
 * &lt;metadatafilterset refid=&quot;common&quot; /&gt;
 * </pre>
 * @ant.task name="metadatafilterset" category="Metadata"
 */
public class MetaDataFilterSet extends DataType implements MetaDataFilterCollection {
    private Vector<MetaDataFilterCollection> filterCollections = new Vector<MetaDataFilterCollection>();
    private File filterFile;
    private boolean initialized;
    
    /**
     * Helper function called by ant to set the FilterFile
     * @param FilterFile the csv file used by the filterset
     */
    public void setFilterFile(File file) throws Exception {
        filterFile = file;
    }

    /**
     * Helper function called to get FilterFile.
     * @return filterfile used by this filterset
     */
    public File getFilterFile() {
        return filterFile;
    }

    /**
     * Helper function called to get filterlist.
     * FilterSet can contain nested filterset, individual filter.
     * Individual filter is created as nestedFilterSet and appended so that
     * the precedence is maintained.
     * @return All filters
     */
    public Collection<MetaDataFilter> getAllFilters() {
        // Shall we treat current object as a reference?
        if (this.isReference()) {
            if (filterFile != null) {
                throw new BuildException("You cannot use the 'filterFile' in reference object.");
            }
            if (!filterCollections.isEmpty()) {
                throw new BuildException("You cannot have nested filters when using a reference object.");
            }
            Object filterSetObject = this.getRefid().getReferencedObject();
            if (filterSetObject != null && filterSetObject instanceof MetaDataFilterCollection) {
                Collection<MetaDataFilter> allFilters = ((MetaDataFilterCollection)filterSetObject).getAllFilters();
                checkInvalidFilters(allFilters);
                return allFilters;                
            } else {
                throw new BuildException("Filterset object is not instance of MetaDataFilterCollection");
            }
        } else {
            if (!initialized) {
                if (filterFile != null) {
                    addDataFromCSVFile();
                }
                initialized = true;
            }
            Collection<MetaDataFilter> allFilters = new Vector<MetaDataFilter>();
            // Add any nested filterCollection
            for (MetaDataFilterCollection filterCollection : filterCollections) {
                allFilters.addAll(filterCollection.getAllFilters());
            }
            checkInvalidFilters(allFilters);
            return allFilters;
        }
    }

    /**
     * Helper function called to remove any invalid filters
     * @return only the valid filters
     */
    private void checkInvalidFilters(Collection<MetaDataFilter> filterList) {
        int count = 0;
        for (MetaDataFilter filter : filterList) {
            SeverityEnum.Severity severity = filter.getSeverity();
            String regEx = filter.getRegex();
            if (severity == null || regEx == null) {                
                log("Invalid filter found at " + filter.getLocation().toString(), Project.MSG_ERR);
                count++;
            }
        }
        if (count > 0) {
            throw new BuildException("Invalid filter have been found. Please check your configuration.");
        }
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
    public void add(MetaDataFilterCollection filterCollection) {
        if (filterCollection != null) {
            filterCollections.add(filterCollection);
        }
    }

    /**
     * Helper function to add the filters from the csv files
     * @param csv file path from which the filters needs to be added.
     */
    private void addDataFromCSVFile() {
        CsvSequence csvs = new CsvSequence();
        csvs.setSeparator(',');
        try {
            csvs.load(new FileReader(filterFile));
            int size = 0;
            size = csvs.size();
            for (int i = 0; i < size; i++) {
                TemplateSequenceModel model = (TemplateSequenceModel)csvs.get(i);
                int modelSize = model.size();
                if (modelSize != 3 ) {
                    throw new BuildException("Metadata CSV file filter file format is invalid. It model must have 3 column, it currently has " + size);
                }
                MetaDataFilter filter = new MetaDataFilter();
                SeverityEnum severity = new SeverityEnum();
                severity.setValue(model.get(0).toString());
                filter.setSeverity(severity);
                filter.setRegex(model.get(1).toString());
                filter.setDescription(model.get(2).toString());
                filterCollections.add(filter);
            }
        } catch (FileNotFoundException fex) {
            throw new BuildException(fex.getMessage(), fex);
        } catch (ParseException pex) {
            throw new BuildException(pex.getMessage(), pex);
        } catch (java.io.IOException iex) {
            throw new BuildException(iex.getMessage(), iex);
        } catch (TemplateModelException e) {
            throw new BuildException(e.getMessage(), e);
        }
    }
}


