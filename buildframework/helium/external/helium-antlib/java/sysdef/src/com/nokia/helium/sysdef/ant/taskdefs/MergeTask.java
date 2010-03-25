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
import java.util.Hashtable;
import java.util.Map;

import org.apache.tools.ant.BuildException;

/**
 * <p>This task allows to do the merge operation on system definition file v3.0.
 * Merge operation consist in combining a the data of two models into one stand-alone
 * system definition file (Also called canonical system definition file).</p>
 * 
 * <p>The following example shows how you can merge the X:\layer.sysdef.xml and X:\vendor.sysdef.xml
 * as X:\joined_layer.sysdef.xml.</p>
 * 
 * E.g:
 * <pre>
 *   &lt;hlm:mergeSysdef epocroot=&quot;X:\&quot;
 *                      srcfile=&quot;X:\layer.sysdef.xml&quot; 
 *                      downstreamfile=&quot;X:\vendor.sysdef.xml&quot; 
 *                      destfile=&quot;X:\joined_layer.sysdef.xml&quot; /&gt;
 * </pre>
 *   
 *   
 *   For more information about system definition file v3.0 please check 
 *   <a href="http://developer.symbian.org/wiki/index.php/System_Definition">http://developer.symbian.org/wiki/index.php/System_Definition</a>.
 *   
 *   @ant.task name="mergeSysdef" category="Sysdef"
 */

public class MergeTask extends AbstractSydefTask {
    private static final String XSLT = "sf/os/buildtools/bldsystemtools/buildsystemtools/mergesysdef.xsl"; 
    private File downstreamFile;

    /**
     * Get the downstream file for the merge.
     * @return
     */
    public File getDownstreamFile() {
        return downstreamFile;
    }

    /**
     * Defines the location of the downstream file.
     * @param downstreamfile
     * @ant.required
     */
    public void setDownstreamfile(File downstreamFile) {
        this.downstreamFile = downstreamFile;
    }

    
    /**
     * {@inheritDoc}
     */
    public void execute() {
        check();
        if (downstreamFile == null) {
            throw new BuildException("'downstreamfile' attribute is not defined");
        }
        if (!downstreamFile.exists()) {
            throw new BuildException("Could not find downstream file " + downstreamFile);
        }        
        
        log("Merging " + this.getSrcFile());
        log("Downstream " + downstreamFile);
        log("Creating " + this.getDestFile());
        Map<String, String> data = new Hashtable<String, String>();
        data.put("Downstream", downstreamFile.toString());
        transform(data);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    protected File getXsl() {
        return new File(this.getEpocroot(), XSLT);
    }
}
