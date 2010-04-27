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


package com.nokia.ant.taskdefs;

import org.apache.tools.ant.Task;
import com.nokia.ant.HeliumLogger;

/**
 * This task will control the outputing of the Helium logger.
 * 
 * Example of usage, to stop logging to console:
 * <pre>
 * &lt;hlm:logtoconsole action="stop"/&gt;
 * </pre>
 *  
 * To resume logging to console:
 * <pre>
 * &lt;hlm:logtoconsole action="start"/&gt;
 * </pre> 
 * 
 * @ant.task name="logtoconsole" category="Logging"
 */ 
public class StopLogToConsole extends Task 
{   
    private boolean stopLogToConsole;
    
    /**
     * Action to perform, stop/start logging.
     * @ant.not-required Default value is start.
     */
    public void setAction(String msg)
    {
        if ( msg.equalsIgnoreCase("stop") )
        {
            stopLogToConsole = true;
        }
        else
        {
            stopLogToConsole = false;
        }       
    }

    @Override
    public void execute()
    {
        super.execute();
        if (HeliumLogger.getStopLogToConsole() != stopLogToConsole)
        {
            if (stopLogToConsole)
                log("Logging to console suspended.");             
            HeliumLogger.setStopLogToConsole(stopLogToConsole);   
            if (!stopLogToConsole)
                log("Logging to console resumed."); 
        }       
    }   
}
