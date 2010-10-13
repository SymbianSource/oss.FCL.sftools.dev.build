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

package com.nokia.helium.core.ant.types;

import java.util.Iterator;

import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.BuildLogger;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.ant.PostBuildAction;

/**
 * 
 */
public class HelpDef extends DataType implements PostBuildAction {

    /**
     * 
     * @param project Object of the project
     * @param targetNames Array of target names to execute
     * 
     */
    public void executeOnPostBuild(Project project, String[] targetNames) {
        String firstTarget;
        // take target
        if (targetNames != null && targetNames.length > 0) {
            firstTarget = targetNames[0];
        }
        // no target, so set the default one
        else {
            firstTarget = "help";
        }

        // If 'help' target is called, just run that and set other
        // target names as a property
        if (firstTarget.equals("help")) {
            displayHelp(project, targetNames, firstTarget);
        }
    }

    @SuppressWarnings("unchecked")
    private void displayHelp(Project project, String[] targetNames, String firstTarget) {
        if (targetNames.length > 1) {
            project.setProperty("help.item", targetNames[1]);
        }

        // Set Emacs mode to true for all listeners, so that help text does
        // not have [echo] at the start of each line
        Iterator iter = project.getBuildListeners().iterator();
        while (iter.hasNext()) {
            BuildListener listener = (BuildListener) iter.next();
            if (listener instanceof BuildLogger) {
                BuildLogger logger = (BuildLogger) listener;
                logger.setEmacsMode(true);
            }
        }

        // Run the 'help' target
        project.executeTarget(firstTarget);
    }
}
