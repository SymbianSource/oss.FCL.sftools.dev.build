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
package com.nokia.helium.antlint.ant.types;

import com.nokia.helium.ant.data.AntFile;
import com.nokia.helium.antlint.ant.AntlintException;
import com.nokia.helium.antlint.ant.Reporter;
import com.nokia.helium.antlint.ant.Severity;

/**
 * <code>Check</code> represents a basic antlint validation component
 * responsible for running the user configured checks.
 * 
 */
public interface Check {

    /**
     * Method runs the configured check against a ant file.
     * 
     * @throws AntlintException if check fails
     */
    void run() throws AntlintException;

    /**
     * Return whether this is check is enabled or not.
     * 
     * @return true if a checker is available for this check; otherwise false.
     */
    boolean isEnabled();

    /**
     * To set the checker enabled.
     * 
     * @param enabled
     */
    void setEnabled(boolean enabled);

    /**
     * To set checker Severity.
     * 
     * @param severity
     */
    void setSeverity(Severity severity);

    /**
     * To return current severity.
     * 
     * @return
     */
    Severity getSeverity();

    /**
     * To validate the attributes passed.
     */
    void validateAttributes();

    /**
     * To set the reporter.
     * 
     * @param reporter
     */
    void setReporter(Reporter reporter);

    /**
     * To get the current reporter.
     * 
     * @return
     */
    Reporter getReporter();

    /**
     * To return current checker name.
     * 
     * @return
     */
    String toString();

    /**
     * Set the ant file.
     * 
     * @param antFile the ant file to set.
     */
    void setAntFile(AntFile antFile);
}
