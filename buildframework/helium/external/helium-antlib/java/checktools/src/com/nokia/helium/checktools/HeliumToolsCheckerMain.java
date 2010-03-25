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
package com.nokia.helium.checktools;

import java.io.FileInputStream;
import java.util.Properties;

/**
 * HeliumToolsCheckerMain is the main class which is used to trigger the
 * checking of basic tools required by the Helium.
 * 
 * Note: HeliumToolsCheckerMain requires a '-config' parameter to be passed as
 * the argument. The config parameter should be followed by a valid location of
 * the configuration file.
 * 
 */
public final class HeliumToolsCheckerMain {

    private Properties configuration;
    private CheckEngine checkEngine;

    
    /**
     * Create an instance of HeliumToolsCheckerMain.
     * 
     * @param configFile
     *            is the config file to read.
     */
    private HeliumToolsCheckerMain(String configFile) {
        loadConfiguration(configFile);
        checkEngine = new CheckEngine(configuration);
    }

    /**
     * Check java version.
     * 
     */
    private void checkJava() {
        try {
            checkEngine.verifyJavaVersion();
        } catch (CheckToolException e) {
            System.out.println("***Error: " + e.getMessage());
        }
    }

    /**
     * Check ant version.
     * 
     */
    private void checkAnt() {
        try {
            checkEngine.verifyAntVersion();
        } catch (CheckToolException e) {
            System.out.println("***Error: " + e.getMessage());
        }
    }

    /**
     * Check python version.
     */
    private void checkPython() {
        try {
            checkEngine.verifyPythonVersion();
        } catch (CheckToolException e) {
            System.out.println("***Error: " + e.getMessage());
        }
    }

    /**
     * Method to check whether the tool check failed or not.
     * 
     * @return true, if the tool check failed with errors; otherwise false.
     */
    private boolean checkFailed() {
        return checkEngine.getErrorCount() > 0;
    }

    /**
     * Method loads the configuration details from the given file.
     * 
     * @param configFile
     *            is the configuration file to be loaded.
     */
    private void loadConfiguration(String configFile) {
        try {
            configuration = new Properties();
            configuration.load(new FileInputStream(configFile));
        } catch (Throwable th) {
            System.out.println("Error occured while loading config file: "
                    + configFile);
            System.exit(-1);
        }
    }

    /**
     * Main method to trigger tool check.
     * 
     * @param args
     *            contains command line arguments passed.
     * @throws Exception
     */
    public static void main(String[] args) throws Exception {

        String configFile = null;

        // check for configuration file
        if (args.length == 2 && args[0].equalsIgnoreCase("-config")) {
            if (args[1] == null
                    || (args[1] != null && args[1].trim().isEmpty())) {
                System.out.println("***Error: Parameter '-config' not set");
                System.exit(-1);
            }
            configFile = args[1];
        }

        if (configFile != null) {
            HeliumToolsCheckerMain checkerMain = new HeliumToolsCheckerMain(
                    configFile);
            checkerMain.checkJava();
            checkerMain.checkAnt();
            checkerMain.checkPython();
            if (checkerMain.checkFailed()) {
                System.exit(-1);
            }
        } else {
            System.out.println("***Error: Missing '-config' argument");
            System.out
                    .println("Usage: java [main-class-name] -config [location of configuration file]");
            System.out
                    .println("Example: java com.nokia.helium.checktools.HeliumToolsCheckerMain -config \"config/helium.basic.tools.config\"");
            System.exit(-1);
        }
    }
}
