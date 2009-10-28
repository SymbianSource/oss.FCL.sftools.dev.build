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

import org.apache.tools.ant.Project;
import com.nokia.helium.core.ant.types.*;

import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.BuildLogger;

import org.apache.log4j.Logger;
/**
 * 
 */
public class HelpDef extends HlmPostDefImpl
{
    private Logger log;
    public HelpDef() {
        log = Logger.getLogger(HelpDef.class);
    }

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
