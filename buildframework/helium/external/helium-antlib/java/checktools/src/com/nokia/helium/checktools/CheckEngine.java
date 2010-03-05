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

import java.util.Properties;

/**
 * CheckEngine is used to verify the versions of tools required by the Helium.
 * 
 * Currently it verifies the following tools:
 * <p>
 * <ul>
 * <li>Java</li>
 * <li>Ant</li>
 * <li>Python</li>
 * </ul>
 * 
 */
public class CheckEngine extends ToolChecker {

    private Properties configuration;

    /**
     * Create an instance of CheckEngine.
     * 
     * @param configuration
     *            is the configuration details of tools
     */
    public CheckEngine(Properties configuration) {
        this.configuration = configuration;
    }

    /**
     * Method verifies Java version.
     * 
     */
    public void verifyJavaVersion() {
        System.out.println("Checking for Java...");

        String expVersion = configuration.getProperty("java.version");
        String errorMsg = "Supported Java version is not defined in 'helium.basic.tools.config'.";
        verifyIsExpectedToolVersionConfigured(expVersion, errorMsg);
        errorMsg = "Java " + expVersion
                + " not found. Kindly install and run again.";
        verifyToolVersion(OSResolver.getCommand("java -version"), expVersion,
                "java version \"", errorMsg);
    }

    /**
     * Method verifies Ant version.
     */
    public void verifyAntVersion() {
        System.out.println("Checking for Ant...");

        String expVersion = configuration.getProperty("ant.version");
        String errorMsg = "Supported Ant version is not defined in 'helium.basic.tools.config'.";
        verifyIsExpectedToolVersionConfigured(expVersion, errorMsg);
        errorMsg = "Ant " + expVersion
                + " not found. Kindly install and run again.";
        verifyToolVersion(OSResolver.getCommand("ant -version"), expVersion,
                "Apache Ant version ", errorMsg);
    }

    /**
     * Method verifies Python version.
     */
    public void verifyPythonVersion() {
        System.out.println("Checking for Python...");

        String expVersion = configuration.getProperty("python.version");
        String errorMsg = "Supported Python version is not defined in 'helium.basic.tools.config'.";
        verifyIsExpectedToolVersionConfigured(expVersion, errorMsg);

        errorMsg = "Python " + expVersion
                + " not found. Kindly install and run again.";
        verifyToolVersion(OSResolver.getCommand("python -V"), expVersion,
                "Python ", errorMsg);
    }
}
