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
package com.nokia.helium.blocks.ant.taskdefs;

import java.io.File;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;

import com.nokia.helium.blocks.Bundle;
import com.nokia.helium.blocks.BundleException;
import com.nokia.helium.core.plexus.AntStreamConsumer;

/**
 * This task will help you to create a debian repository index.
 * To generate the index you need to set the dest attribute to point
 * to a directory containing .deb packages. The outcome of the process 
 * will be a Package file under the mentioned directory.
 * 
 * <pre>
 * &lt;hlm:blocksCreateRepositoryIndex dest="E:\some\path\to\a\repo" 
 *           verbose="true" sign="false" /&gt;
 * </pre>
 * @ant.task name="blocksCreateRepositoryIndex" category="Blocks"
 */
public class CreateRepositoryIndexTask extends Task {

    private File dest;
    private boolean sign;
    private boolean failOnError = true;
    private boolean verbose;
    
    /**
     * Location where to create the repository index.
     * @param dest
     * @ant.required
     */
    public void setDest(File dest) {
        this.dest = dest;
    }
   
    /**
     * Get the location where to create the repository index.
     * @return the dest folder.
     */
    public File getDest() {
        return dest;
    }
    
    /**
     * Defines if the repository index creation should be signed. 
     * @param sign If true the repository will be signed
     * @ant.not-required Default is false
     */
    public void setSign(boolean sign) {
        this.sign = sign;
    }
    
    /**
     * Shall we sign the repository?
     * @return true is the repository should be signed.
     */
    public boolean isSign() {
        return sign;
    }

    /**
     * If defined as true it will fail the build in case of error, 
     * else it will keepgoing.
     * @param failOnError
     * @ant.not-required Default is true.
     */
    public void setFailOnError(boolean failOnError) {
        this.failOnError = failOnError;
    }

    /**
     * Shall we fail on error?
     * @return return true if should fails on error.
     */
    public boolean isFailOnError() {
        return failOnError;
    }

    /**
     * Set true to show the output from blocks command execution.
     * @param verbose
     * @ant.not-required Default to false.
     */
    public void setVerbose(boolean verbose) {
        this.verbose = verbose;
    }

    /**
     * Are we execution the task in verbose mode.
     * @return
     */
    public boolean isVerbose() {
        return verbose;
    }

    /**
     * {@inheritDoc}
     */
    public void execute() {
        if (getDest() == null) {
            throw new BuildException("'dest' attribute must be defined.");
        }
        try {
            getBundle().createRepositoryIndex(getDest(), isSign());
        } catch (BundleException e) {
            if (isFailOnError()) {
                throw new BuildException(e.getMessage(), e);
            } else {
                log(e.getMessage(), Project.MSG_ERR);
            }
        }
    }
    
    /**
     * Get a pre-configured Bundle application wrapper instance.
     * @return a new bundle object.
     */
    protected Bundle getBundle() {
        Bundle bundle = new Bundle();
        if (isVerbose()) {
            bundle.addOutputLineHandler(new AntStreamConsumer(this, Project.MSG_INFO));
        } else {
            bundle.addOutputLineHandler(new AntStreamConsumer(this, Project.MSG_DEBUG));
        }
        bundle.addErrorLineHandler(new AntStreamConsumer(this, Project.MSG_ERR));
        return bundle;
    }
}
