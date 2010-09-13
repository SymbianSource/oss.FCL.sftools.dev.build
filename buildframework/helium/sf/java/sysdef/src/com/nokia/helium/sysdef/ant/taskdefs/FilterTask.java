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
import java.util.List;

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
 * <br>
 * This task relies on externals tools. Their location can be configured the following ways:
 *  <li>by configuring the sysdef.tools.home property, fails if the location is incorrect.
 *  <li>The parent folder of the joinsysdef tool from the PATH, fallback on SDK location.
 *  <li>Default SDK location.
 *
 * @ant.task name="filterSysdef" category="Sysdef"
 */
public class FilterTask extends AbstractSydefTask {
    private static final String XSLT = "filtering.xsl";
    private List<FilterSet> filterSets = new ArrayList<FilterSet>();
    
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
                try {
                    filterSet = (FilterSet)filterSet.getRefid().getReferencedObject();
                } catch (ClassCastException ex) {
                    throw new BuildException("Object referenced by '" + filterSet.getRefid().getRefId() + "' is not a sysdefFilterSet.", ex);
                }
            }
            List<File> toDelete = new ArrayList<File>();
            try {
                File src = this.getSrcFile();
                File dst = null;
                for (Filter filter : filterSet.getFilters()) {
                    
                    // validating parameter first.
                    filter.validate();
                    
                    // Then filter the file
                    dst = File.createTempFile("sysdef", ".xml", this.getEpocroot());
                    toDelete.add(dst);
                    filter.filter(this, src, dst);
                    
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
    protected File getXsl() {
        return new File(SysdefUtils.getSysdefHome(getProject(), this.getEpocroot()), XSLT);
    }
}