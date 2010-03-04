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

 
package com.nokia.helium.signal.ant.types;
import net.sf.antcontrib.logic.RunTargetTask;
import org.apache.tools.ant.Project;
import com.nokia.helium.core.ant.HlmExceptionHandler;
import com.nokia.helium.signal.ant.taskdefs.*;
import com.nokia.helium.signal.ant.SignalListener;
import org.apache.log4j.Logger;


/**
 * Class to store the status of the signal of a particular target.
 */
public class SignalExceptionHandler implements HlmExceptionHandler
{
    private Logger log = Logger.getLogger(SignalListener.class);
    
    /**
     * This post action will fail the build if any pending failure exists. 
     * @throws BuildException
     */
    public void handleException(Project project, String module, Exception e) {
        String exceptionTarget = project.getProperty("exceptions.target");
        if (exceptionTarget != null) {
            RunTargetTask runTargetTask = new RunTargetTask();
            runTargetTask.setProject(project);
            runTargetTask.setTarget(exceptionTarget);
            runTargetTask.execute();
        }
   }
}