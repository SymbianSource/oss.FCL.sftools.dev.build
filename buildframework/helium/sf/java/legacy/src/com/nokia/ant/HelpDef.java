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
 
package com.nokia.ant;

import java.util.Iterator;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.Project;
import com.nokia.helium.core.ant.types.*;

import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.BuildLogger;

/**
 * 
 */
public class HelpDef extends HlmPostDefImpl
{

    /**
     * 
     * @param project
     *            Object of the project
     * @param targetNames
     *            Array of target names to execute
     * 
     */
    public void execute(Project project, String module, String[] targetNames)
    {
        String firstTarget;

        // take target
        if (targetNames != null && targetNames.length > 0)
        {
            firstTarget = targetNames[0];
        }
        else
        // no target, so set the default one
        {
            firstTarget = "help";
        }

        // If 'help' target is called, just run that and set other
        // target names as a property
        if (firstTarget.equals("help"))
        {
            displayHelp(project, targetNames, firstTarget);
        }
        
        project.addBuildListener(new UnsubstListener());
    }

    class UnsubstListener implements BuildListener {
        public void buildFinished(BuildEvent event) {
            Project project = event.getProject();
            String drivenotdef = project.getProperty("build.drive.notdefined");
            if (System.getProperty("os.name").toLowerCase().startsWith("win") && drivenotdef != null && drivenotdef.equals("true"))
            {
                String drive = project.getProperty("build.drive");
                try {
                    if (drive != null) {
                        Runtime.getRuntime().exec("subst /d " + drive);
                    }
                } catch (java.io.IOException e) {
                    e = null; // ignoring the error
                }
            }
        }
        
        public void buildStarted(BuildEvent event) { }
        public void targetStarted(BuildEvent event) { }
        public void targetFinished(BuildEvent event) { }
        public void taskStarted(BuildEvent event) { }
        public void taskFinished(BuildEvent event) { }
        public void messageLogged(BuildEvent event) { }
    }

    private void displayHelp(Project project, String[] targetNames, String firstTarget)
    {
        if (targetNames.length > 1)
        {
            project.setProperty("help.target", targetNames[1]);
        }
        
        // Set Emacs mode to true for all listeners, so that help text does
        // not have [echo] at the start of each line
        Iterator iter = project.getBuildListeners().iterator();
        while (iter.hasNext())
        {
            BuildListener listener = (BuildListener) iter.next();
            if (listener instanceof BuildLogger)
            {
                BuildLogger logger = (BuildLogger) listener;
                logger.setEmacsMode(true);
            }
        }

        // Run the 'help' target
        project.executeTarget(firstTarget);
    }

}
