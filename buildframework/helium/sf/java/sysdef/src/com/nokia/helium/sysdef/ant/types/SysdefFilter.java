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
package com.nokia.helium.sysdef.ant.types;

import java.io.File;
import java.util.Hashtable;
import java.util.Map;

import org.apache.tools.ant.BuildException;

import com.nokia.helium.sysdef.ant.taskdefs.AbstractSydefTask;
import com.nokia.helium.sysdef.ant.taskdefs.FilterTask;
import com.nokia.helium.sysdef.ant.taskdefs.SysdefUtils;

/**
 * This type defines a system definition filter.
 *
 */
public class SysdefFilter implements Filter {
    private static final String INVALID_FILTER = "nothing";
    private static final String XSLT = "filtering.xsl";
    private String filter;
    private String type = "has";
    private String verbatim;

    /**
     * Define the verbatim to filter in, can be used in conjunction with filter.
     * @param verbatim a string representing a comma separated list of id to 
     *               filter in.
     * @ant.required
     */
    public void setVerbatim(String verbatim) {
        this.verbatim = verbatim;
    }

    /**
     * Define the filter, can be used in conjunction with verbatim attribute.
     * @param filter the filter string.
     * @ant.required
     */
    public void setFilter(String filter) {
        this.filter = filter;
    }

    /**
     * Define the filter type
     * @param type
     * @ant.not-required Default has.
     */
    public void setType(SydefFilterTypeEnum type) {
        this.type = type.getValue();
    }

    

    /**
     * {@inheritDoc}
     */
    @Override
    public void filter(FilterTask task, File src, File dest) {
        FilterImpl impl = new FilterImpl();
        impl.bindToOwner(task);
        impl.setEpocroot(task.getEpocroot());
        impl.setSrcFile(src);
        impl.setDestFile(dest);
        impl.filter(filter, type);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void validate() {
        if (filter == null && verbatim == null) {
            throw new BuildException("'filter' or/and 'idlist' attribute is not defined.");
        }
    }

    private class FilterImpl extends AbstractSydefTask {
        
        /**
         * Running the filtering operation on src file and put the result in dest file.
         * @param src the source file
         * @param dest the destination file
         * @param filter the filter to use
         * @param filterType the filter type to use (e.g has, only, with)
         */
        protected void filter(String filter, String filterType) {
            Map<String, String> params = new Hashtable<String, String>();
            params.put("filter-type", filterType);
            if (filter == null && verbatim != null) {
                params.put("filter", INVALID_FILTER);
            } else if (filter != null) {
                params.put("filter", filter);
            }
            if (verbatim != null) {
                params.put("verbatim", verbatim);
            }
            transform(params);
        }
        
        
        /**
         * {@inheritDoc}
         */
        @Override
        protected File getXsl() {
            return new File(SysdefUtils.getSysdefHome(getProject(), this.getEpocroot()), XSLT);
        }
    }

}