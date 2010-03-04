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
package com.nokia.helium.antlint;

import java.util.ArrayList;

/**
 * <code>AntFile</code> is used to hold information about the antlint checkings
 * such as number of errors and warnings found for the given ant file.
 * 
 */
public class AntFile implements Comparable<AntFile> {
    private String name;
    private int warningCount;
    private int errorCount;

    private ArrayList<String> propertiesVisited = new ArrayList<String>();

    /**
     * Create an instance of {@link AntFile}.
     * 
     * @param name
     *            is the name of the Ant file.
     */
    public AntFile(String name) {
        this.name = name;
    }

    /**
     * Increment warnings count by one.
     */
    public void incrementWarningCount() {
        warningCount++;
    }

    /**
     * Return total number of warnings found.
     * 
     * @return the total number of warnings.
     */
    public int getWarningCount() {
        return warningCount;
    }

    /**
     * Increment error count by one.
     */
    public void incrementErrorCount() {
        errorCount++;
    }

    /**
     * Return total number of errors found.
     * 
     * @return the total number of errors.
     */
    public int getErrorCount() {
        return errorCount;
    }

    /**
     * Mark the given property as visited.
     * 
     * @param propertyName
     *            is the property to be marked.
     */
    public void markPropertyAsVisited(String propertyName) {
        propertiesVisited.add(propertyName);
    }

    /**
     * Check whether the given property is already visited or not.
     * 
     * @param propertyName
     *            is the property to lookup for.
     * @return true if the property is marked visited; otherwise false.
     */
    public boolean isPropertyVisited(String propertyName) {
        return propertiesVisited.contains(propertyName);
    }

    /**
     * Return a string representation of this object.
     * 
     * @return a string representation of this object.
     */
    public String toString() {
        return errorCount + " errors and " + warningCount + " warnings " + name;
    }

    /**
     * {@inheritDoc}
     */
    public int compareTo(AntFile otherAntFile) {
        return new Integer(otherAntFile.getWarningCount())
                .compareTo(new Integer(this.warningCount))
                * -1;
    }

}
