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
package com.nokia.helium.imaker;

import java.io.File;
import java.io.IOException;
import java.util.List;


import com.nokia.helium.core.plexus.CommandBase;
import com.nokia.helium.core.plexus.StreamRecorder;

import org.apache.log4j.Logger;

/**
 * This class implements a wrapper around iMaker.
 * It helps to introspect:
 *   <li> variables
 *   <li> targets
 *   <li> configurations
 *
 */
public class IMaker extends CommandBase<IMakerException> {
    private static final String TEMP_ROMBUILD_DIR = "epoc32/rombuild/temp";
    private final Logger log = Logger.getLogger(getClass());
    private File epocroot;

    /**
     * Create an iMaker wrapper class with a specific epocroot.
     * @param epocroot
     */
    public IMaker(File epocroot) {
        this.epocroot = epocroot;
        
    }
    
    /**
     * Creates a temp working dir for the rom image creation.
     * @return
     * @throws IOException
     */
    public File createWorkDir() throws IMakerException {
        try {
            File tempRootDir = new File(getEpocroot(), TEMP_ROMBUILD_DIR);
            tempRootDir.mkdirs();
            File tempDir = File.createTempFile("helium-imaker", "", tempRootDir);
            tempDir.delete();
            tempDir.mkdirs();
            return tempDir;
        } catch (IOException e) {
            throw new IMakerException(e.getMessage(), e);
        }
    }
    
    /**
     * Epocroot location.
     * @return the epocroot location
     */
    public File getEpocroot() {
        return epocroot;
    }

    /**
     * Get the iMaker version.
     * @return the current iMaker version.
     * @throws IMakerException is thrown in case of an iMaker execution error.
     */
    public String getVersion() throws IMakerException {
        log.debug("getVersion");
        String[] args = new String[1];
        args[0] = "version";
        StreamRecorder rec = new StreamRecorder();
        execute(args, rec);
        return rec.getBuffer().toString().trim();
    }

    /**
     * Get the value of a particular variable from iMaker configuration.
     * @param name the variable name
     * @return the value or null if the variable does not exist.
     * @throws IMakerException
     */
    public String getVariable(String name) throws IMakerException {
        log.debug("getVariable: " + name);
        String[] args = new String[1];
        args[0] = "print-" + name;
        PrintVarSteamConsumer consumer = new PrintVarSteamConsumer(name);
        execute(args, consumer);
        return consumer.getValue();
    }

    /**
     * Get the value of a particular variable from iMaker configuration for a particular
     * configuration.
     * @param name the variable name
     * @return the value or null if the variable does not exist.
     * @throws IMakerException
     */
    public String getVariable(String name, File configuration) throws IMakerException {
        log.debug("getVariable: " + name + " - " + configuration);
        String[] args = new String[3];
        args[0] = "-f";
        args[1] = configuration.getAbsolutePath();
        args[2] = "print-" + name;
        PrintVarSteamConsumer consumer = new PrintVarSteamConsumer(name);
        execute(args, consumer);
        return consumer.getValue();
    }

    /**
     * Get the list of available iMaker configurations.
     * @return a list of configurations
     * @throws IMakerException
     */
    public List<String> getConfigurations() throws IMakerException {
        log.debug("getConfigurations");
        String[] args = new String[1];
        args[0] = "help-config";
        HelpConfigStreamConsumer consumer = new HelpConfigStreamConsumer();
        execute(args, consumer);
        return consumer.getConfigurations();
    }
    
    /**
     * Get the a list of target supported by a specific configuration.  
     * @param configuration the configuration to use
     * @return the list of targets.
     * @throws IMakerException
     */
    public List<String> getTargets(String configuration) throws IMakerException {
        log.debug("getConfigurations");
        String[] args = new String[3];
        args[0] = "-f";
        args[1] = configuration;
        args[2] = "help-target-*-list";
        HelpTargetListStreamConsumer consumer = new HelpTargetListStreamConsumer();
        execute(args, consumer);
        return consumer.getTargets();
    }

    /**
     * Get the target list for the configuration.
     * @param configuration a File object representing the configuration location.
     * @return a list of targets.
     * @throws IMakerException
     */
    public List<String> getTargets(File configuration) throws IMakerException {
        return getTargets(configuration.getAbsolutePath());
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    protected String getExecutable() {
        return "imaker";
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public File getWorkingDir() {
        return getEpocroot();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    protected void throwException(String message, Throwable t)
            throws IMakerException {
        throw new IMakerException(message, t);        
    }
    
}
