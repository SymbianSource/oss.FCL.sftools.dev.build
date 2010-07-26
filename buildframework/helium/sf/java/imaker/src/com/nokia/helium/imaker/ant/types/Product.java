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
package com.nokia.helium.imaker.ant.types;

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;

/**
 * The product type will allow you to select iMaker makefile configuration based on
 * the product name. The search will be done using the following template:
 * image_conf_[product_name][_ui].mk
 * 
 * <pre>
 * &lt;hlm:product list="product1,product2" ui="true" failonerror="false" /&gt;
 * </pre>
 * @ant.type name="hlm:product" category="imaker"
 */
public class Product extends DataType implements MakefileSelector {
    private String list;
    private boolean ui;
    private boolean failOnError = true;

    /**
     * Defines a comma separated list of product names.
     * @param name
     */
    public void setList(String list) {
        this.list = list;
    }
    
    /**
     * Get the list of products
     * @return an array of products
     */
    public String[] getNames() {
        Vector<String> names = new Vector<String>();
        for (String name : this.list.split(",")) {
            name = name.trim();
            if (name.length() > 0) {
                names.add(name);
            }
        }
        return names.toArray(new String[names.size()]);
    }

    public void setUi(boolean ui) {
        this.ui = ui;
    }

    /**
     * Define if we are looking for a ui configuration (will add _ui to the
     * makefile name)
     * @return
     * @ant.not-required Default false
     */
    public boolean isUi() {
        return ui;
    }

    /**
     * Shall we fail the build in case of missing config?
     * @param failOnError
     * @ant.not-required Default true
     */
    public void setFailOnError(boolean failOnError) {
        this.failOnError = failOnError;
    }

    /**
     * Shall we fail the build in case of missing config. 
     * @return a boolean
     */
    public boolean isFailOnError() {
        return failOnError;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public List<String> selectMakefile(List<String> configurations) {
        List<String> result = new ArrayList<String>();
        for (String product : getNames()) {
            String endOfString = "image_conf_" + product + (ui ? "_ui" : "") + ".mk";
            boolean foundConfig = false;
            for (String config : configurations) {
                if (config.endsWith(endOfString)) {
                    foundConfig = true;
                    result.add(config);
                    break;
                }
            }
            if (!foundConfig) {
                if (isFailOnError()) {
                    throw new BuildException("Could not find a valid configuration for " + product);
                } else {
                    log("Could not find a valid configuration for " + product, Project.MSG_ERR);
                }
            }
        }
        return result;
    }

}