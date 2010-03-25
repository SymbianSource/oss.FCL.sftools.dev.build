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

import java.util.Locale;

import junit.framework.TestCase;

import com.nokia.helium.checktools.CheckToolException;
import com.nokia.helium.checktools.OSResolver;

/**
 * Test class for OSResolver.
 * 
 */
public class TestOSResolver extends TestCase {

    /**
     * Method to test getCommand.
     */
    public void testGetCommand() {
        String result = OSResolver.getCommand("test");
        String osName = System.getProperty("os.name").toLowerCase(Locale.US);
        boolean isWindows = osName.indexOf("windows") > -1;
        boolean is9x = (osName.indexOf("95") >= 0 || osName.indexOf("98") >= 0
                || osName.indexOf("me") >= 0 || osName.indexOf("ce") >= 0);
        if (isWindows && is9x) {
            assertEquals("command /c test", result);
        } else if (isWindows && !is9x) {
            assertEquals("cmd /c test", result);
        } else {
            assertEquals("test", result);
        }
    }

    /**
     * Method to test whether the given os is of Windows family or not.
     */
    public void testIsOSWindowsFamily() {
        String osName = System.getProperty("os.name").toLowerCase(Locale.US);
        boolean isWindows = osName.indexOf("windows") > -1;
        boolean result = OSResolver.isOs("windows");
        if (isWindows) {
            assertEquals(true, result);
        } else {
            assertEquals(false, result);
        }
    }

    /**
     * Method to test whether the given os is of unix family or not.
     */
    public void testIsOSUnixFamily() {
        String osName = System.getProperty("os.name").toLowerCase(Locale.US);
        String pathSeparator = System.getProperty("path.separator");
        boolean isUnix = pathSeparator.equals(":")
                && (osName.indexOf("mac") == -1 || osName.endsWith("x"));
        boolean result = OSResolver.isOs("unix");
        if (isUnix) {
            assertEquals(true, result);
        } else {
            assertEquals(false, result);
        }
    }

    /**
     * Method to test whether the given os is invalid or not.
     */
    public void testIsOSInvalidFamily() {
        CheckToolException cte = null;
        try {
            OSResolver.isOs("invalid");
        } catch (CheckToolException ex) {
            cte = ex;
        }
        assertNotNull(cte);
        String expected = "Don\'t know how to detect os family \"invalid\"";
        assertEquals(expected, cte.getMessage());
    }

}
