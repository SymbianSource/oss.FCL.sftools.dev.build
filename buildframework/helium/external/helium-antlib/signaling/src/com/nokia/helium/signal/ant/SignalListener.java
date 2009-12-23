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


package com.nokia.helium.signal.ant;

import org.apache.tools.ant.BuildListener;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.BuildException;
import org.apache.log4j.Logger;

/**
 * Listener class that can connect to Ant and log information regarding to build
 * times, number of errors and such. Data is sent to Diamonds server, where it
 * is processed further.
 * 
 * This class is listening all build related events. It catches the build
 * start-finish, target start-finish events of Ant and gather build start-end
 * time, errors/warnings and store in BuildData class. Stored data will be
 * exported to XML and uploaded to Diamonds server after each specific target.
 * For example after target "create-bom" this class will upload all BOM data to
 * Diamonds.
 * 
 * 
 */
public class SignalListener implements BuildListener {

    public static final String MODULE_NAME = "signaling";
    
    private boolean initialized;

    private SignalList signalList;

    private Project project;

    private Logger log = Logger.getLogger(this.getClass());

    /**
     * Ant call this function when build start.
     */
    public void buildStarted(BuildEvent event) {
        project = event.getProject();
    }

    /**
     * Triggered when a target starts.
     */
    public void targetStarted(BuildEvent event) {
        if (project == null) {
            project = event.getProject();
        }
    }

    private void initialize() {
        signalList = new SignalList(project);
        //signalList1 = new SignalList(project);
    }

    /**
     * Triggered when a target finishes.
     */
    public void targetFinished(BuildEvent event) {
        if (!initialized) {
            log.debug("Signaling: Initializing Signaling");
            initialize();
            initialized = true;
        }
        log.debug("Signaling:targetFinished:sendsignal: " + event.getTarget());
        try {
            //boolean status = signalList1.checkAndNotifyFailure(event.getTarget(),event.getProject());
            //if (!status) {
            signalList.checkAndNotifyFailure(event.getTarget(),event.getProject());
            //}
        } catch (Exception e) {
            throw new BuildException(e.getMessage(), e);
        }
    }

    /**
     * Triggered when the build finishes.
     */
    public void buildFinished(BuildEvent event) {
    }

    /**
     * Triggered when a task starts.
     */
    public void taskStarted(BuildEvent event) {
    }

    /**
     * Triggered when a task finishes.
     */
    public void taskFinished(BuildEvent event) {
    }

    /**
     * Triggered when a build message is logged.
     */
    public void messageLogged(BuildEvent event) {
    }
}