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

import org.dom4j.Element;

import com.nokia.helium.antlint.AntFile;
import com.nokia.helium.antlint.ant.types.Checker;

/**
 * <code>Check</code> represents a basic antlint component responsible for
 * running the user configured checks.
 * 
 */
public interface Check {

    /**
     * Method runs the configured checks. Usually checks which have to be run
     * only time should be used here.
     */
    void run();

    /**
     * Method runs the configured checks against the given node.
     * 
     * @param node
     *            is the node of the xml to be checked.
     */
    void run(Element node);

    /**
     * Method runs the configured checks against the given ant file.
     * 
     * @param fileName
     *            is the name of the ant file.
     */
    void run(String fileName);

    /**
     * Set the {@link Checker} configured for this check.
     * 
     * @param checker
     *            is the {@link Checker} to set.
     */
    void setChecker(Checker checker);

    /**
     * Set the ant file to hold information about the checks conducted on the
     * file.
     * 
     * @param antFile
     *            is the {@link AntFile} to set.
     */
    void setAntFile(AntFile antFile);

    /**
     * Return whether this is check is enabled or not.
     * 
     * @return true if a checker is available for this check; otherwise false.
     */
    boolean isEnabled();

    /**
     * Log the given message.
     * 
     * @param message is the message to be logged.
     */
    void log(String message);

    /**
     * Return the {@link Checker} configured for this {@link Check}.
     * 
     * @return the {@link Checker}.
     */
    Checker getChecker();
}
