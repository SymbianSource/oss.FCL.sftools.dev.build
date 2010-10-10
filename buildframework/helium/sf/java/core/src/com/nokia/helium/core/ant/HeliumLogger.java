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

package com.nokia.helium.core.ant;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.DefaultLogger;
import org.apache.tools.ant.Project;

/**
 * Logger class that can connect to Ant and log information regarding to skipped
 * targets.
 * 
 */
public class HeliumLogger extends DefaultLogger {

    private static final String INTERNALPROPERTY = "internal.";
    private Project project;

    /**
     * Triggered when a target starts.
     */
    public void targetStarted(BuildEvent event) {
        project = event.getProject();

        /** The "if" condition to test on execution. */
        String ifCondition = event.getTarget().getIf();
        /** The "unless" condition to test on execution. */
        String unlessCondition = event.getTarget().getUnless();

        super.targetStarted(event);

        /**
         * if the target is not going to execute (due to 'if' or 'unless'
         * conditions) print a message telling the user why it is not going to
         * execute
         **/
        if (ifCondition != null && !isPropertyAvailable(ifCondition)) {
            if (ifCondition.startsWith(INTERNALPROPERTY)) {
                String enableProperty = ifCondition.substring(INTERNALPROPERTY
                        .length());
                project.log("Skipped because property '" + enableProperty
                        + "' not set to 'true'.", Project.MSG_INFO);
            } else {
                project.log("Skipped because property '"
                        + project.replaceProperties(ifCondition)
                        + "' is not set.", Project.MSG_INFO);
            }

        } else if (unlessCondition != null
                && isPropertyAvailable(unlessCondition)) {
            if (unlessCondition.startsWith(INTERNALPROPERTY)) {
                String enableProperty = unlessCondition
                        .substring(INTERNALPROPERTY.length());
                project.log("Skipped because property '" + enableProperty
                        + "' is set.", Project.MSG_INFO);
            } else {
                project.log(
                        "Skipped because property '"
                                + project.replaceProperties(unlessCondition)
                                + "' set.", Project.MSG_INFO);
            }
        }
    }

    /**
     * Method to verify whether the given property is available in the project
     * or not.
     * 
     * @param propertyName
     *            the name of the property to verify.
     * @return true, if the property available and is set; otherwise false.
     */
    private boolean isPropertyAvailable(String propertyName) {
        return project.getProperty(project.replaceProperties(propertyName)) != null;
    }
}
