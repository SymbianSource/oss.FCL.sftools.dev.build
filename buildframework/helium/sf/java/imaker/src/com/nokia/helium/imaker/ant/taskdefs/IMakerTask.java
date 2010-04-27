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
package com.nokia.helium.imaker.ant.taskdefs;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.plexus.AntStreamConsumer;
import com.nokia.helium.imaker.IMaker;
import com.nokia.helium.imaker.IMakerException;
import com.nokia.helium.imaker.ant.Command;
import com.nokia.helium.imaker.ant.Engine;
import com.nokia.helium.imaker.ant.IMakerCommandSet;
import com.nokia.helium.imaker.ant.engines.JavaEngine;

/**
 * The imaker task will allow you to efficiently use iMaker to 
 * build rom images in parallel.
 * 
 * The task is actually base on two concepts:
 * <ul>
 *   <li> content configuration: what needs to be built.
 *   <li> acceleration engine: how to build roms in an efficient way.
 * </ul>
 * 
 * In the following example the task is configured to use the emake engine
 * to accelerate the rom image creation and an <code>imakerconfiguration</code> configuration
 * element to configure the content of the building:
 *
 * <pre>
 *       &lt;hlm:emakeEngine id="imaker.ec" /&gt;
 *       &lt;hlm:imaker epocroot="${epocroot}" 
 *                      output="${epocroot}/imaker.log"
 *                      engineRefid="imaker.ec"
 *                      verbose="true"&gt;
             &lt;hlm:imakerconfiguration&gt;
 *                   &lt;makefileset&gt;
 *                       &lt;include name="*&#42;/product/*ui.mk" /&gt;
 *                   &lt;/makefileset&gt;
 *                   &lt;targetset&gt;
 *                       &lt;include name="core" /&gt;
 *                       &lt;include name="langpack_01" /&gt;
 *                   &lt;/targetset&gt;
             &lt;/hlm:imakerconfiguration&gt;
 *       &lt;/hlm:imaker&gt;
 * </pre> 
 * @ant.task name=imaker category=imaker
 */
public class IMakerTask extends Task {

    private File epocroot;
    private boolean verbose;
    private boolean failOnError = true;
    private List<IMakerCommandSet> commandSets = new ArrayList<IMakerCommandSet>();
    private String engineRefId;
    private AntStreamConsumer stdout = new AntStreamConsumer(this);
    private AntStreamConsumer stderr = new AntStreamConsumer(this, Project.MSG_ERR);
    private File output;
    
    /**
     * Add iMaker Task compatible configuration. The task will 
     * accept any Ant type implementing the IMakerCommandSet 
     * interface like the <code>imakerconfiguration</code> type.
     * 
     * @param cmdSet an iMaker configuration which will defines
     *               what needs to be built.
     * 
     * @ant.required
     */
    public void add(IMakerCommandSet cmdSet) {
        commandSets.add(cmdSet);
    }

    /**
     * Defines the reference id of the engine to use.
     * @ant.not-required Default Java implementation will be used.
     */
    public void setEngineRefId(String engineRefId) {
        this.engineRefId = engineRefId;
    }

    /**
     * Retrieve the engine to be used. If the engineRefId
     * attribute is not defined then the JavaEngine is used 
     * as the default one.
     * @return An instance of engine.
     * @throws a BuildException if the engineRefId attribute doesn't define an Engine
     * object.
     */
    protected Engine getEngine() {
        if (engineRefId == null) {
            log("Using default engine (Java threading)");
            JavaEngine engine = new JavaEngine();
            engine.setProject(getProject());
            engine.setTask(this);
            return engine;
        } else {
            try {
                Engine engine = (Engine)this.getProject().getReference(engineRefId);
                engine.setTask(this);
                return engine;
            } catch (ClassCastException e) {
                throw new BuildException("Reference '" + engineRefId + "' is not referencing an Engine configuration.");
            }
        }
    }
    
    /**
     * Get current epocroot location (build environment).
     * @return a File object.
     */
    public File getEpocroot() {
        File epocroot = this.epocroot;
        if (epocroot == null) {
            epocroot = new File(System.getenv("EPOCROOT"));
            if (epocroot == null) {
                throw new BuildException("'epocroot' attribute has not been defined.");                
            } else {
                log("Using EPOCROOT: " + epocroot.getAbsolutePath());
            }
        }

        if (!epocroot.exists() || !epocroot.isDirectory()) {
            throw new BuildException("Invalid epocroot directory: " + epocroot);
        }
        return epocroot;
    }

    /**
     * Defines the EPOCROOT location.
     * @param epocroot
     * @ant.not-required Will use EPOCROOT environment variable if not defined.
     */
    public void setEpocroot(File epocroot) {
        this.epocroot = epocroot;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void execute() {
        try {
            // Simple way to verify if iMaker is installed under
            // then environment.
            IMaker imaker = getIMaker();
            log("Using iMaker: " + imaker.getVersion());

            // build the content.
            build();
        } catch (IMakerException e) {
            if (shouldFailOnError()) {
                throw new BuildException(e.getMessage(), e);
            } else {
                log(e.getMessage(),  Project.MSG_ERR);
            }
        }
    }
    
    /**
     * Should the task be verbose.
     * @return  Returns true if the task should display all iMaker outputs.
     */
    public boolean isVerbose() {
        return verbose;
    }

    /**
     * Defines if the task should log all the output through Ant.
     * by default only error/warnings are printed.
     * @param verbose set the verbosity status.
     * @ant.not-required Default is false.
     */
    public void setVerbose(boolean verbose) {
        this.verbose = verbose;
    }

    /**
     * Get the output filename.
     * @return the output filename.
     */
    public File getOutput() {
        return output;
    }

    /**
     * Defined the output log filename.
     * @param output
     * @ant.not-required
     */
    public void setOutput(File output) {
        this.output = output;
    }

    /**
     * Concatenate all the configuration content and
     * delegate the building to the engine.
     * @throws IMakerException
     */
    protected void build() throws IMakerException {
        List<List<Command>> cmds = new ArrayList<List<Command>>();
        for (IMakerCommandSet cmdSet : commandSets) {
            if (cmdSet instanceof DataType) {
                DataType dataType = (DataType)cmdSet;
                if (dataType.isReference()) {
                    cmdSet = (IMakerCommandSet)dataType.getRefid().getReferencedObject();
                }
            }
            cmds.addAll(cmdSet.getCommands(getIMaker()));
        }
        if (cmds.size() > 0) {
            getEngine().build(cmds);
        } else {
            log("Nothing to build.");
        }
    }
    
    /**
     * Get a configured IMaker instance. The created object
     * is configured with output stream redirected to
     * the task logging. Stderr is always redirected,
     * stdout is only redirected if the task is configured
     * to be verbose.
     * 
     * @return an IMaker instance.
     */
    public IMaker getIMaker() {
        return getIMaker(verbose, true);
    }

    /**
     * Get a configured IMaker instance. The created object
     * is configured with output stream redirected to
     * the task logging. Stderr is always redirected,
     * the stdout will be configured by the verbose parameter.
     * @param verbose enable stdout redirection to the task logging.
     * @return an IMaker instance.
     */
    public IMaker getIMaker(boolean verbose, boolean verboseError) {
        IMaker imaker = new IMaker(getEpocroot());
        if (verbose) {
            imaker.addOutputLineHandler(stdout);
        }
        if (verboseError) {
            imaker.addErrorLineHandler(stderr);
        }
        return imaker;
    }
    
    /**
     * Defines if the task should fail in case of error.
     * @ant.not-required Default is true
     */
    public void setFailOnError(boolean failOnError) {
        this.failOnError = failOnError;
    }
    
    /**
     * Should the task should fail in case of error?
     * @return true if the task should fail on error.
     */
    public boolean shouldFailOnError() {
        return this.failOnError;
    }
        
}
