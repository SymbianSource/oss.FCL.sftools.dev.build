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

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.ant.data.AntFile;
import com.nokia.helium.antlint.ant.Reporter;
import com.nokia.helium.antlint.ant.Severity;

/**
 * <code>AbstractCheck</code> is an abstract implementation of {@link Check}.
 * 
 */
public abstract class AbstractCheck extends DataType implements Check {

    private boolean enabled = true;
    private Severity severity;
    private Reporter reporter;
    private AntFile antFile;

    /**
     * Return the ant file.
     * 
     * @return the ant file.
     */
    protected AntFile getAntFile() {
        return antFile;
    }

    /**
     * {@inheritDoc}
     */
    public void setAntFile(AntFile antFile) {
        this.antFile = antFile;
    }

    /**
     * {@inheritDoc}
     */
    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    /**
     * {@inheritDoc}
     */
    public boolean isEnabled() {
        return enabled;
    }

    /*
     * (non-Javadoc)
     * @see
     * com.nokia.helium.antlint.ant.types.Check#setReporter(com.nokia.helium
     * .antlint.ant.Reporter)
     */
    public void setReporter(Reporter reporter) {
        this.reporter = reporter;
    }

    /*
     * (non-Javadoc)
     * @see com.nokia.helium.antlint.ant.types.Check#getReporter()
     */
    public Reporter getReporter() {
        return this.reporter;
    }

    /*
     * (non-Javadoc)
     * @see
     * com.nokia.helium.antlint.ant.types.Check#setSeverity(com.nokia.helium
     * .antlint.ant.Severity)
     */
    public void setSeverity(Severity severity) {
        this.severity = severity;

    }

    /*
     * (non-Javadoc)
     * @see com.nokia.helium.antlint.ant.types.Check#getSeverity()
     */
    public Severity getSeverity() {
        return severity;
    }

    /**
     * Method to validate checker attributes.
     * 
     */
    public void validateAttributes() {
        if (severity == null) {
            throw new BuildException("'severity' attribute should be specified for checker '"
                    + this.toString() + "'");
        }
    }

    /**
     * Sends the given message to the configured reporter.
     * 
     * @param message is the message to be sent.
     */
    protected void report(String message) {
        report(message, 0);
    }

    /**
     * Sends the given message with exact line number to the configured
     * reporter.
     * 
     * @param message is the message to be sent.
     * @param lineNum is the line number.
     */
    protected void report(String message, int lineNum) {
        getReporter().report(getSeverity(), message, getAntFile().getFile(), lineNum);
    }

    /**
     * Method validates the given input string against the input regex pattern.
     * 
     * @param input is the string to be validated.
     * @param regex is the regex pattern
     * @return true, if matches; otherwise false.
     */
    protected boolean matches(String input, String regex) {
        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(input);
        return matcher.matches();
    }

    protected boolean matchFound(String input, String regex) {
        boolean found = false;
        Pattern p1 = Pattern.compile(regex);
        Matcher m1 = p1.matcher(input);
        while (m1.find()) {
            found = true;
        }
        return found;
    }
    
    
    /* (non-Javadoc)
     * @see org.apache.tools.ant.types.DataType#toString()
     */
    public String toString() {
        return getClass().getSimpleName();
    }
}
