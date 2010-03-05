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

import java.util.Locale;

/**
 * OSResolver is a utility class containing useful methods related to OS.
 * 
 */
public final class OSResolver {

    public static final String FAMILY_WINDOWS = "windows";
    public static final String FAMILY_9X = "win9x";
    public static final String FAMILY_NT = "winnt";
    public static final String FAMILY_MAC = "mac";
    public static final String FAMILY_UNIX = "unix";

    private static final String OS_NAME = System.getProperty("os.name")
            .toLowerCase(Locale.US);
    private static final String PATH_SEP = System.getProperty("path.separator");


    /**
     * Must not be instantiated.
     */
    private OSResolver() {
    }
    
    /**
     * Returns a formatted command string specific to the underlying OS.
     * 
     * @param cmd
     *            is the command to be formatted.
     * @return the formatted OS specific command string.
     */
    public static String getCommand(String cmd) {
        StringBuffer buffer = new StringBuffer();
        if (isOs("windows")) {
            if (!isOs("win9x")) {
                // Windows XP/2000/NT
                buffer.append("cmd /c ");
            } else {
                // Windows 98/95
                buffer.append("command /c ");
            }
        }
        // generic
        buffer.append(cmd);
        return buffer.toString();
    }

    /**
     * Method verifies whether the underlying OS belongs to the given OS family.
     * 
     * @param family
     *            The OS family
     * @return true if the OS matches; otherwise false.
     */
    public static boolean isOs(String family) {
        boolean retValue = false;
        if (family != null) {
            // windows probing logic relies on the word 'windows' in
            // the OS
            boolean isWindows = OS_NAME.indexOf(FAMILY_WINDOWS) > -1;
            boolean is9x = false;
            boolean isNT = false;
            if (isWindows) {
                // there are only four 9x platforms that we look for
                is9x = OS_NAME.indexOf("95") >= 0
                        || OS_NAME.indexOf("98") >= 0
                        || OS_NAME.indexOf("me") >= 0 || OS_NAME.indexOf("ce") >= 0;
                isNT = !is9x;
            }
            if (family.equals(FAMILY_WINDOWS)) {
                retValue = isWindows;
            } else if (family.equals(FAMILY_9X)) {
                retValue = isWindows && is9x;
            } else if (family.equals(FAMILY_NT)) {
                retValue = isWindows && isNT;
            } else if (family.equals(FAMILY_MAC)) {
                retValue = OS_NAME.indexOf(FAMILY_MAC) > -1;
            } else if (family.equals(FAMILY_UNIX)) {
                retValue = PATH_SEP.equals(":")
                        && (!isOs(FAMILY_MAC) || OS_NAME.endsWith("x"));
            } else {
                throw new CheckToolException(
                        "Don\'t know how to detect os family \"" + family
                                + "\"");
            }
        }
        return retValue;
    }

}
