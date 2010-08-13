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
package com.nokia.helium.sysdef.ant.conditions;

import java.io.File;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.taskdefs.condition.Condition;
import org.apache.tools.ant.types.Resource;
import org.apache.tools.ant.types.resources.selectors.ResourceSelector;
import org.apache.tools.ant.types.selectors.BaseExtendSelector;

import com.nokia.helium.sysdef.PackageDefinition;
import com.nokia.helium.sysdef.PackageDefinitionParsingException;

/**
 * Ant condition to test if a package_definition.xml is
 * defining a vendor package. A package is considered as a vendor package
 * when its id-namespace attribute has a different from the default one (please check the
 * system definition documentation on the Symbian Foundation website for further detail).
 *
 * <pre>
 *     &lt;condition property="name" value="true"&gt;
 *         &lt;hlm:isVendorPackage file="${epocroot}/sf/app/package/package_definition.xml" /&gt;
 *     &lt;/condition&gt;
 * </pre>
 * 
 * This condition is also usable as a resource selector:
 *
 * <pre>
 *     &lt;restrict&gt;
 *         &lt;fileset dir=&quot;...&quot; includes=&quot;package_definition.xml&quot; /&gt;
 *         &lt;hlm:isVendorPackage /&gt;
 *     &lt;/restrict&gt;
 * </pre>
 * 
 */
public class IsVendorPackage extends BaseExtendSelector
    implements Condition, ResourceSelector {

    private File file;
    
    /**
     * Detect is the package_definition.xml is from a vendor package.
     * Vendor package have different id-namespace than the default
     * one (<code>PackageDefinition.DEFAULT_ID_NAMESPACE</code>).
     * 
     * @param file
     * @return true if it denotes a vendor package.
     */
    protected boolean isVendorPackage(File file) {
        if ("package_definition.xml".equals(file.getName())) {
            try {
                PackageDefinition pkgDef = new PackageDefinition(file);
                return !PackageDefinition.DEFAULT_ID_NAMESPACE.equals(pkgDef.getIdNamespace());
            } catch (PackageDefinitionParsingException e) {
                throw new BuildException("Error parsing " + file 
                        + ": " + e.getMessage(), e);
            }
        }
        return false;
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public boolean eval() {
        if (file == null) {
            throw new BuildException("'file' attribute is not defined.");
        }
        return isVendorPackage(file);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public boolean isSelected(File basedir, String filename, File file) {
        return isVendorPackage(file);
    }

    /**
     * The file to test when used as a condition.
     * @param file
     * @ant.required
     */
    public void setFile(File file) {
        this.file = file;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public boolean isSelected(Resource resource) {
        if (!resource.isFilesystemOnly()) {
            throw new BuildException(this.getDataTypeName() + " only supports filesystem resources.");
        }
        return isVendorPackage(new File(resource.toString()));
    }
}
