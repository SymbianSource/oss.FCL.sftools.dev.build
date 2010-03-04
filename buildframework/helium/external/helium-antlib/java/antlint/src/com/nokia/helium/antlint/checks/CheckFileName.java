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
package com.nokia.helium.antlint.checks;

import java.io.File;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.tools.ant.BuildException;

/**
 * <code>CheckFileName</code> is used to check the naming convention of the ant files.
 *
 */
public class CheckFileName extends AbstractCheck {

    /**
     * {@inheritDoc}
     */
    public void run(String arg) {
        if (arg != null) {
            try {
                boolean found = false;
                Pattern p1 = Pattern.compile(getPattern());
                Matcher m1 = p1.matcher(new File(arg).getName());
                while (m1.find()) {
                    found = true;
                }
                if (!found) {
                    log("INVALID File Name: " + arg);
                }
            } catch (Exception e) {
                throw new BuildException("W: INVALID File Name: " + arg
                        + e.getMessage());
            }
        }
    }

}
