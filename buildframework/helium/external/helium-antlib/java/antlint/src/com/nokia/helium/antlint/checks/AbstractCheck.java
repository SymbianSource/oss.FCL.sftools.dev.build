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

//import java.io.File;
//import java.util.List;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import org.dom4j.Document;
import org.dom4j.Element;
//import org.dom4j.Node;
import org.dom4j.io.SAXReader;

import com.nokia.helium.antlint.AntFile;
import com.nokia.helium.antlint.ant.types.Checker;

/**
 * <code>AbstractCheck</code> is an abstract implementation of {@link Check}.
 * 
 */
public abstract class AbstractCheck implements Check {

    private Checker checker;
    private AntFile antFile;
    private boolean enabled;

    /**
     * {@inheritDoc}
     */
    public void setChecker(Checker checker) {
        this.checker = checker;
        this.enabled = true;
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
    public boolean isEnabled() {
        return enabled;
    }

    /**
     * {@inheritDoc}
     */
    public Checker getChecker() {
        return this.checker;
    }

    /**
     * Return the {@link AntFile} set.
     * 
     * @return the {@link AntFile}
     */
    protected AntFile getAntFile() {
        return antFile;
    }

    /**
     * {@inheritDoc}
     */
    public void log(String message) {
        if (checker.getSeverity() != null
                && checker.getSeverity().equalsIgnoreCase("error")) {
            logError(message);
            antFile.incrementErrorCount();
        } else {
            logWarning(message);
            antFile.incrementWarningCount();
        }
    }

    /**
     * Get the {@link Pattern} associated with current {@link Check}.
     * 
     * @return the Pattern.
     */
    protected String getPattern() {
        return checker.getPattern();
    }

    /**
     * Get the {@link Project}.
     * 
     * @return the {@link Project}
     */
    protected Project getProject() {
        return checker.getProject();
    }

    /**
     * Check the availability dependent targets of the given target.
     * 
     * @param targetName
     *            is the target for which dependent targets to be loked up.
     * @return true, if the dependant targets are available; otherwise false
     */
    protected boolean checkTargetDependency(String targetName) {
        boolean dependencyCheck = false;
        try {
            Target targetDependency = (Target) getProject().getTargets().get(
                    targetName);
            dependencyCheck = targetDependency != null
                    && targetDependency.getDependencies().hasMoreElements();
        } catch (Exception e) {
            throw new BuildException("Not able to get Target Dependency for "
                    + targetName);
        }
        return dependencyCheck;
    }

    /**
     * Check the whether the given property is defined in the data model.
     * 
     * @param customerProp
     *            is the property to check for.
     */
    @SuppressWarnings("unchecked")
    protected void checkPropertyInModel(String customerProp) {
        SAXReader xmlReader = new SAXReader();
        Document antDoc = null;
        
        // TODO

//        try {
//            File model = new File(getProject().getProperty("data.model.parsed"));
//            antDoc = xmlReader.read(model);
//      } catch (Exception e) {
//            throw new BuildException("Not able to read data model file "
//                    + getProject().getProperty("data.model.parsed"));
//        }
//
//        List<Node> statements = antDoc.selectNodes("//property");
//
//        for (Node statement : statements) {
//            if (customerProp.equals(statement.valueOf("name"))) {
//                return;
//            }
//        }
//        log(customerProp + " not in data model");
    }

    /**
     * Log the given message as an error.
     * 
     * @param message
     *            is the message to log.
     */
    private void logError(String message) {
        getProject().log("E: " + message);
    }

    /**
     * Log the given message as an warning.
     * 
     * @param message
     *            is the message to log.
     */
    private void logWarning(String message) {
        getProject().log("W: " + message);
    }

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        // ignore
    }

    /**
     * {@inheritDoc}
     */
    public void run(String text) {
        // ignore
    }

    /**
     * {@inheritDoc}
     */
    public void run() {
        // ignore
    }
}
