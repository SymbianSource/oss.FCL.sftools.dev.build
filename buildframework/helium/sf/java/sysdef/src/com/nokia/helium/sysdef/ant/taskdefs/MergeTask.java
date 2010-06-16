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
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.Resource;
import org.apache.tools.ant.types.ResourceCollection;
import org.apache.tools.ant.util.FileUtils;

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
    private static final String XSLT = "sf/os/buildtools/bldsystemtools/sysdeftools/mergesysdef.xsl"; 
    private File downstreamFile;
    private List<ResourceCollection> resourceCollections = new ArrayList<ResourceCollection>();

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
     * 
     */
    public void add(ResourceCollection resourceCollection) {
        resourceCollections.add(resourceCollection);
    }
    
    /**
     * {@inheritDoc}
     */
    @SuppressWarnings("unchecked")
    public void execute() {
        if (!resourceCollections.isEmpty()) {
            File xslt = getXsl();
            if (!xslt.exists()) {
                throw new BuildException("Could not find " + xslt);
            }        
            log("Creating " + this.getDestFile());
            boolean first = true;
            File tempFile = null;
            try {
                tempFile = File.createTempFile("sysdef", ".xml");
                this.setSrcFile(tempFile);              
                for (ResourceCollection rc : resourceCollections) {
                    Iterator<Resource> ri =  (Iterator<Resource>)rc.iterator();
                    while (ri.hasNext()) {
                        Resource resource = ri.next();
                        File rFile = new File(resource.toString());
                        if (first) {
                            log("Merging " + rFile);
                            tempFile.delete();
                            FileUtils.getFileUtils().copyFile(rFile, tempFile);
                            FileUtils.getFileUtils().copyFile(rFile, getDestFile());
                            first = false;
                        } else {
                            log("Downstream " + rFile);
                            Map<String, String> data = new Hashtable<String, String>();
                            data.put("Downstream", rFile.getAbsolutePath());
                            this.transform(data);
                            FileUtils.getFileUtils().copyFile(getDestFile(), tempFile);
                        }
                    }
                }
            } catch (IOException e) {
                log("Error while doing the merge: " + e.getMessage(), Project.MSG_ERR);
                if (this.isFailOnError()) {
                    throw new BuildException("Error while doing the merge: " + e.getMessage());
                }
            } finally {
                if (tempFile != null) {
                    tempFile.delete();
                }
            }
            if (first) {
                log("Error: nothing to merge.", Project.MSG_ERR);
                if (this.isFailOnError()) {
                    throw new BuildException("Error: nothing to merge.");
                }
            }
        } else {
            check();
            if (getDownstreamFile() == null) {
                throw new BuildException("'downstreamfile' attribute is not defined");
            }
            if (!getDownstreamFile().exists()) {
                throw new BuildException("Could not find downstream file " + downstreamFile);
            }
            log("Merging " + this.getSrcFile());
            log("Downstream " + getDownstreamFile());
            log("Creating " + this.getDestFile());
            Map<String, String> data = new Hashtable<String, String>();
            data.put("Downstream", getDownstreamFile().toString());
            transform(data);
        }
    }

    /**
     * {@inheritDoc}
     */
    @Override
    protected File getXsl() {
        return new File(this.getEpocroot(), XSLT);
    }
}
