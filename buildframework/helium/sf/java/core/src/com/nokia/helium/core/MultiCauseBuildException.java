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
package com.nokia.helium.core;

import java.io.PrintStream;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Vector;

import org.apache.tools.ant.BuildException;

/**
 * A MultiCauseBuildException class used by the HeliumExecutor plugin to store
 * the failures caused in the course of a build.
 * 
 */
public class MultiCauseBuildException extends BuildException {

    private static final long serialVersionUID = -4843675216704377447L;

    private Vector<Throwable> causes = new Vector<Throwable>();

    /**
     * Construct a new multicause build exception with no detail message and no
     * cause.
     */
    public MultiCauseBuildException() {
        super();
    }

    /**
     * Construct a new multi-cause build exception with the given detail message
     * and no cause.
     * 
     * @param msg
     *            Detail message.
     */
    public MultiCauseBuildException(String msg) {
        super(msg);
    }

    /**
     * Construct a new multi-cause build exception with no detail message and
     * the given cause.
     * 
     * @param cause
     *            the cause of failure.
     */
    public MultiCauseBuildException(Throwable cause) {
        super();
        causes.add(cause);
    }

    /**
     * Construct a new multi-cause exception with the given detail message and
     * the given cause.
     * 
     * @param msg
     *            Detail message.
     * @param cause
     *            the cause of failure
     * 
     */
    public MultiCauseBuildException(String msg, Throwable cause) {
        super(msg);
        causes.add(cause);
    }

    /**
     * Method adds the given throwable instance.
     * 
     * @param th
     *            the throwbale instance to be added.
     */
    public void add(Throwable th) {
        causes.add(th);
    }

    /**
     * {@inheritDoc}
     */
    public StackTraceElement[] getStackTrace() {
        List<StackTraceElement> stackTraceElements = new ArrayList<StackTraceElement>();
        for (Throwable th : causes) {
            stackTraceElements.addAll(Arrays.asList(th.getStackTrace()));
        }
        return stackTraceElements
                .toArray(new StackTraceElement[stackTraceElements.size()]);
    }

    /**
     * {@inheritDoc}
     */
    public void printStackTrace(PrintStream ps) {
        synchronized (ps) {
            super.printStackTrace(ps);
            int i = 1;
            for (Throwable cause : causes) {
                ps.printf("MultiCauseBuildException caused by [%d]: ", i++);
                cause.printStackTrace(ps);
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    public void printStackTrace(PrintWriter pw) {
        synchronized (pw) {
            super.printStackTrace(pw);
            int i = 1;
            for (Throwable cause : causes) {
                pw.printf("MultiCauseBuildException caused by [%d]: ", i++);
                cause.printStackTrace(pw);
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    public String getMessage() {
        String message = super.getMessage();
        for (Throwable th : causes) {
            if (message == null) {
                message = th.getMessage();
            } else {            
                message += "\n" + th.getMessage();
            }
        }
        return message;
    }

    /**
     * Returns the location of the error and the error message.
     * 
     * @return the location of the error and the error message
     */
    public String toString() {
        StringBuffer buffer = new StringBuffer();
        for (Throwable th : causes) {
            buffer.append(th);
            buffer.append("\n");
        }
        return buffer.toString();
    }

}
