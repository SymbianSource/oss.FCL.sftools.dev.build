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
package com.nokia.helium.sysdef.ant.taskdefs;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.util.FileUtils;

import com.nokia.helium.sysdef.ant.types.Filter;
import com.nokia.helium.sysdef.ant.types.FilterSet;

/**
 * <p>This task allows to do the filtering operation on system definition file v3.0.</p>
 * 
 * <p>The following example shows how you can join the X:\layer.sysdef.xml under
 * X:\filtered_layer.sysdef.xml.</p>
 * 
 * E.g:
 * <pre>
 *   &lt;hlm:filterSysdef epocroot=&quot;X:\&quot; srcfile=&quot;X:\layer.sysdef.xml&quot; 
 *                      destfile=&quot;X:\filtered_layer.sysdef.xml&quot;&gt;
 *       &lt;filterset&gt; 
 *           &lt;filter filter=&quot;test&quot; type=&quot;has&quot; /&gt; 
 *       &lt;/filterset&gt; 
 *   &lt;/hlm:filterSysdef&gt;
 * </pre>
 *
 * For more information about system definition file v3.0 please check 
 * <a href="http://developer.symbian.org/wiki/index.php/System_Definition">http://developer.symbian.org/wiki/index.php/System_Definition</a>.
 *
 * @ant.task name="filterSysdef" category="Sysdef"
 */
public class FilterTask extends AbstractSydefTask {
    private static final String XSLT = "sf/os/buildtools/bldsystemtools/sysdeftools/filtering.xsl";
    private List<FilterSet> filterSets = new ArrayList<FilterSet>();
    
    /**
     * Running the filtering operation on src file and put the result in dest file.
     * @param src the source file
     * @param dest the destination file
     * @param filter the filter to use
     * @param filterType the filter type to use (e.g has, only, with)
     */
    protected void filter(File src, File dest, String filter, String filterType) {
        Map<String, String> params = new Hashtable<String, String>();
        params.put("filter-type", filterType);
        params.put("filter", filter);
        transform(params);
    }

    /**
     * Create a FilterSet object to store filters.
     * @return a new FilterSet object
     */
    public FilterSet createFilterSet() {
        FilterSet filterset = new FilterSet();
        filterSets.add(filterset);
        return filterset;
    }

    /**
     * Add a FilterSet object.
     */
    public void add(FilterSet filterset) {
        filterSets.add(filterset);
    }
    
    /**
     * {@inheritDoc}
     */
    public void execute() {
        check();
        if (filterSets.isEmpty()) {
            throw new BuildException("You must define at least one nested filterset element.");
        }
        log("Filtering " + this.getSrcFile());
        for (FilterSet filterSet : filterSets) {
            if (filterSet.isReference()) {
                filterSet = (FilterSet)filterSet.getRefid().getReferencedObject();
            }
            List<File> toDelete = new ArrayList<File>();
            try {
                File src = this.getSrcFile();
                File dst = null;
                for (Filter filter : filterSet.getFilters()) {
                    if (filter.getFilter() == null) {
                        throw new BuildException("'filter' attribute is not defined.");
                    }
                    dst = File.createTempFile("sysdef", ".xml", this.getEpocroot());
                    toDelete.add(dst);
                    filter(src, dst, filter.getFilter(), filter.getType());
                    // Dest is the input for next loop.
                    src = dst;
                }
                if (dst != null) {
                    log("Creating " + this.getDestFile());
                    FileUtils.getFileUtils().copyFile(dst, getDestFile());
                } else {
                    // If nothing to do it is just identity, 
                    // so copying the source file
                    log("Creating " + this.getDestFile());
                    FileUtils.getFileUtils().copyFile(getSrcFile(), getDestFile());
                }
            } catch (IOException e) {
                throw new BuildException(e.getMessage(), e);
            } finally {
                for (File file : toDelete) {
                    file.delete();
                }
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    @Override
    File getXsl() {
        return new File(this.getEpocroot(), XSLT);
    }
}