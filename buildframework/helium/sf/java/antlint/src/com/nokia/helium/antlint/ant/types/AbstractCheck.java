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

import java.util.List;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.DataType;
import org.dom4j.Element;
import org.dom4j.Node;
import com.nokia.helium.antlint.ant.Reporter;
import com.nokia.helium.antlint.ant.Severity;

/**
 * <code>AbstractCheck</code> is an abstract implementation of {@link Check}.
 * 
 */
public abstract class AbstractCheck extends DataType implements Check {

    private boolean enabled;
    private Severity severity;
    private Reporter reporter;

    /**
     * @param enabled
     *            the enabled to set
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
     * 
     * @see
     * com.nokia.helium.antlint.ant.types.Check#setReporter(com.nokia.helium
     * .antlint.ant.Reporter)
     */
    public void setReporter(Reporter reporter) {
        this.reporter = reporter;
    }

    /*
     * (non-Javadoc)
     * 
     * @see com.nokia.helium.antlint.ant.types.Check#getReporter()
     */
    public Reporter getReporter() {
        return this.reporter;
    }

    /*
     * (non-Javadoc)
     * 
     * @see
     * com.nokia.helium.antlint.ant.types.Check#setSeverity(com.nokia.helium
     * .antlint.ant.Severity)
     */
    public void setSeverity(Severity severity) {
        this.severity = severity;

    }

    /*
     * (non-Javadoc)
     * 
     * @see com.nokia.helium.antlint.ant.types.Check#getSeverity()
     */
    public Severity getSeverity() {
        return severity;
    }

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        // ignore
    }

    /**
     * Return the nodes matching search element.
     * 
     * @param element
     * @param elementName
     * @param returnNodes
     */
    public void elementTreeWalk(Element element, String elementName,
            List<Element> returnNodes) {
        for (int i = 0, size = element.nodeCount(); i < size; i++) {
            Node node = element.node(i);
            if (node instanceof Element) {
                if (node.getName().equals(elementName)) {
                    returnNodes.add((Element) node);
                }
                elementTreeWalk((Element) node, elementName, returnNodes);
            }
        }
    }

    /**
     * To validate checker attributes.
     * 
     * @return
     */
    public void validateAttributes() {
        if (severity == null) {
            throw new BuildException(
                    "'severity' attribute should be specified for checker '"
                            + this.toString() + "'");
        }
    }

}
