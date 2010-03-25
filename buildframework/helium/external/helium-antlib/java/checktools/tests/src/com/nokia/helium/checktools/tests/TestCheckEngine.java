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

package com.nokia.helium.checktools.tests;

import java.util.Properties;

import junit.framework.TestCase;

import com.nokia.helium.checktools.CheckEngine;
import com.nokia.helium.checktools.CheckToolException;
import com.nokia.helium.checktools.OSResolver;
import com.nokia.helium.checktools.ToolChecker;

/**
 * Test class for CheckEngine.
 * 
 */
public class TestCheckEngine extends TestCase {

    /**
     * Method tests the java version with invalid version set.
     */
    public void testVerifyJavaVersionInValid() {
        CheckToolException cte = null;
        Properties props = new Properties();
        props.setProperty("java.version", "0.0");

        try {
            new CheckEngine(props).verifyJavaVersion();
        } catch (CheckToolException ex) {
            cte = ex;
        }
        assertNotNull(cte);
        String expected = "Java 0.0 not found. Kindly install and run again.";
        assertEquals(expected, cte.getMessage());
    }

    /**
     * Method tests the java version with valid version set.
     */
    public void testVerifyJavaVersionValid() {
        CheckToolException cte = null;
        Properties props = new Properties();
        String str = new ToolChecker().getInstalledToolVersion(OSResolver
                .getCommand("java -version"));
        String ver = str.split(" ")[2].split(System
                .getProperty("line.separator"))[0];
        props.setProperty("java.version", ver.replaceAll("\"", ""));

        try {
            new CheckEngine(props).verifyJavaVersion();
        } catch (CheckToolException ex) {
            cte = ex;
            ex.printStackTrace();
        }
        assertNull(cte);
    }

    /**
     * Method tests the ant version with invalid version set.
     */
    public void testVerifyAntVersionInValid() {
        CheckToolException cte = null;
        Properties props = new Properties();
        props.setProperty("ant.version", "0.0.0");

        try {
            new CheckEngine(props).verifyAntVersion();
        } catch (CheckToolException ex) {
            cte = ex;
        }
        assertNotNull(cte);
        String expected = "Ant 0.0.0 not found. Kindly install and run again.";
        assertEquals(expected, cte.getMessage());
    }

    /**
     * Method tests the ant version with valid version set.
     */
    public void testVerifyAntVersionValid() {
        CheckToolException cte = null;
        Properties props = new Properties();
        String str = new ToolChecker().getInstalledToolVersion(OSResolver
                .getCommand("ant -version"));
        String ver = str.split(" ")[3];
        props.setProperty("ant.version", ver);

        try {
            new CheckEngine(props).verifyAntVersion();
        } catch (CheckToolException ex) {
            cte = ex;
            ex.printStackTrace();
        }
        assertNull(cte);
    }

    /**
     * Method tests the python version with invalid version set.
     */
    public void testVerifyPythonVersionInValid() {
        CheckToolException cte = null;
        Properties props = new Properties();
        props.setProperty("python.version", "0.0.0.0");

        try {
            new CheckEngine(props).verifyPythonVersion();
        } catch (CheckToolException ex) {
            cte = ex;
        }
        assertNotNull(cte);
        String expected = "Python 0.0.0.0 not found. Kindly install and run again.";
        assertEquals(expected, cte.getMessage());
    }

    /**
     * Method tests the python version with valid version set.
     */
    public void testVerifyPythonVersionValid() {
        CheckToolException cte = null;
        Properties props = new Properties();
        String str = new ToolChecker().getInstalledToolVersion(OSResolver
                .getCommand("python -V"));
        String ver = str.split(" ")[1];
        props.setProperty("python.version", ver);

        try {
            new CheckEngine(props).verifyPythonVersion();
        } catch (CheckToolException ex) {
            cte = ex;
            ex.printStackTrace();
        }
        assertNull(cte);
    }
}
