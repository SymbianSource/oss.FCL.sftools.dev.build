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

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * ToolChecker is a generic class used to verify tool versions.
 * 
 */
public class ToolChecker {

    private int errorCount;

    /**
     * Method verifies whether the expected version is set or not.
     * 
     * @param expVersion
     *            is the version string to verify.
     * @param errorMsg
     *            is the message to be displayed on failure.
     */
    public void verifyIsExpectedToolVersionConfigured(String expVersion,
            String errorMsg) {
        if (expVersion == null
                || (expVersion != null && expVersion.trim().isEmpty())) {
            raiseError(errorMsg);
        }
    }

    /**
     * Method verifies the tool version.
     * 
     * @param command
     *            is the command string to verify tool version.
     * @param expVersion
     *            is the expected tool version.
     * @param versionString2match
     *            is the version string to match
     * @param errorMsg
     *            is the message to be displayed on failure.
     */
    public void verifyToolVersion(String command, String expVersion,
            String versionString2match, String errorMsg) {
        String[] versions = expVersion.split(",");
        String installedVersion = getInstalledToolVersion(command);
        boolean valid = false;
        for (int i = 0; i < versions.length; i++) {
            if (!valid)
                valid = installedVersion.contains(versionString2match
                        + versions[i]);
        }
        if (!valid) {
            System.out.println("Installed Version : " + installedVersion);
            raiseError(errorMsg);
        } else
            System.out.println("Done");
    }

    /**
     * Method throws a CheckToolException with the given message.
     * 
     * @param message
     *            is the failure message.
     */
    public void raiseError(String message) {
        incrementErrorCount();
        throw new CheckToolException(message);
    }

    /**
     * Method returns the actual version of the tool installed.
     * 
     * @param cmd
     *            is the command string to execute.
     * @return the actual tool version.
     */
    public String getInstalledToolVersion(String cmd) {
        String input = null;
        String error = null;
        try {
            Process toolProcess = Runtime.getRuntime().exec(cmd);
            input = toString(toolProcess.getInputStream());
            error = toString(toolProcess.getErrorStream());
        } catch (Throwable th) {
            throw new CheckToolException(th);
        }
        return (input.isEmpty()) ? error : input;
    }

    /**
     * Method returns a string read from the given input stream.
     * 
     * @param is
     *            is the input stream to read from.
     * @return the contents read from the input stream.
     * @throws Exception
     */
    private String toString(InputStream is) throws Exception {
        OutputStream os = null;
        String versionString = null;
        try {

            byte[] buffer = new byte[4096];
            os = new ByteArrayOutputStream();

            while (true) {
                int read = is.read(buffer);
                if (read == -1) {
                    break;
                }
                os.write(buffer, 0, read);
            }
            versionString = os.toString();
        } finally {
            try {
                os.close();
                is.close();
            } catch (Exception e) {
                e = null; // ignore the exception
            }
        }
        return versionString;
    }

    /**
     * Method increases error count by one.
     */
    private void incrementErrorCount() {
        errorCount++;
    }

    /**
     * Return the error count.
     * 
     * @return the error count.
     */
    public int getErrorCount() {
        return errorCount;
    }

}
