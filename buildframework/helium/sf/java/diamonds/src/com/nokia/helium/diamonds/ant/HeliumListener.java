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


package com.nokia.helium.diamonds.ant;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Logger;
import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.Project;

import com.nokia.helium.diamonds.AllTargetDiamondsListener;
import com.nokia.helium.diamonds.DiamondsConfig;
import com.nokia.helium.diamonds.DiamondsException;
import com.nokia.helium.diamonds.DiamondsListener;
import com.nokia.helium.diamonds.DiamondsListenerImpl;
import com.nokia.helium.diamonds.StageDiamondsListener;
import com.nokia.helium.diamonds.TargetDiamondsListener;

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
public class HeliumListener implements BuildListener {

    private Logger log = Logger.getLogger(HeliumListener.class);

    private List<DiamondsListener> diamondsListeners;

    private Project project;

    private boolean isInitialized;

    private boolean skipDiamonds ;
    private boolean skipDiamondsSet;

    /**
     * Default constructor.
     */
    public HeliumListener() {
        diamondsListeners = new ArrayList<DiamondsListener>();
    }

    /**
     * Ant call this function when build start.
     */
    public void buildStarted(BuildEvent event) {
        project = event.getProject();
    }

    /**
     * Triggered when a target starts.
     */
    @SuppressWarnings("unchecked") 
    public void targetStarted(BuildEvent event) {
        Project prj = event.getProject();
        String targetName = event.getTarget().getName();

        String diamondsEnabled = prj.getProperty("diamonds.enabled");
        String skip = prj.getProperty("skip.diamonds");
        log.debug("diamondsenabled: " + diamondsEnabled);
        log.debug("skip: " + skip);
        if (!isInitialized) {
            if (diamondsEnabled != null && !Project.toBoolean(diamondsEnabled)) {
                log.info("'diamonds.enabled' is not true, to use diamonds set 'diamonds.enabled' to 'true'.");
                skipDiamonds = true;
                isInitialized = true;
            } else if (skip != null && Project.toBoolean(skip)) {
                log.info("'skip.diamonds' is deprecated. Please consider using 'diamonds.enabled'.");
                skipDiamonds = true;
                isInitialized = true;
            }
        }
        
        try {
            if (!skipDiamonds) {
                if (!isInitialized) {
                    /**
                     * Initialize Diamonds if and only if initializer-target-name has been called
                     */
                    String buildID = prj.getProperty(DiamondsConfig.getBuildIdProperty());
                    log.debug("targetStarted:buildid:" + buildID);
                    String initializerTargetName = prj.getProperty(DiamondsConfig.getInitializerTargetProperty());
                    log.debug("initializerTargetName:" + initializerTargetName);
                    log.debug("targetName:" + targetName);
                    if ( buildID != null || (initializerTargetName != null && targetName.equals(initializerTargetName))) {
                        isInitialized = true;
                        project = prj;
                        log.debug("trying to initialize diamonds config");
                        DiamondsConfig.initialize(project);
                        DiamondsListenerImpl.initialize(project);
                        String category = DiamondsConfig.getCategory();
                        log.debug("category:" + category);
                        if (category != null && diamondsListeners.isEmpty()) {
                            addListeners(event);
                            log.info("Diamonds enabled");
                        }
                    }
                }
            } else {
                if (!skipDiamondsSet && skipDiamonds)
                {
                    skipDiamondsSet = true;
                }
            }
        } catch (DiamondsException ex) {
            log.debug("Diamonds error: ", ex);
            String errorMessage = ex.getMessage();
            if (errorMessage == null) {
                errorMessage = "";
            }
            log.error("Diamonds Error, might not be logged properly, see debug log. "
                            + errorMessage);
        }
        if (diamondsListeners != null) {
            for (DiamondsListener diamondsListener : diamondsListeners) {
                try {
                    diamondsListener.targetBegin(event);
                } catch (DiamondsException e) {
                    e.printStackTrace();
                    log.debug("Error:", e);
                    String errorMessage = e.getMessage();
                    if (errorMessage == null) {
                        errorMessage = "";
                    }
                    log.error("Diamonds Error, might not be logged properly, see debug log. "
                                    + errorMessage);
                }
            }
        }
    }

    private void addListeners(BuildEvent event) throws DiamondsException {
        if (DiamondsConfig.isStagesInConfig()) {
            StageDiamondsListener stageListener = new StageDiamondsListener();
            diamondsListeners.add(stageListener);
            stageListener.buildBegin(event);
        }
        if (DiamondsConfig.isTargetsInConfig()) {
            TargetDiamondsListener targetListener = new TargetDiamondsListener();
            diamondsListeners.add(targetListener);
            targetListener.buildBegin(event);
        }
        
        AllTargetDiamondsListener allTargetListener = new AllTargetDiamondsListener();
        diamondsListeners.add(allTargetListener);
        allTargetListener.buildBegin(event);
    }

    /**
     * Triggered when a target finishes.
     */
    public void targetFinished(BuildEvent event) {
        if (diamondsListeners != null) {
            for (DiamondsListener diamondsListener : diamondsListeners) {
                try {
                    diamondsListener.targetEnd(event);
                } catch (DiamondsException e) {
                    log.debug("Error:", e);
                    String errorMessage = e.getMessage();
                    if (errorMessage == null) {
                        errorMessage = "";
                    }
                    log.error("Diamonds Error, might not be logged properly, see debug log. "
                                    + errorMessage);
                }

            }
        }
    }

    /**
     * Triggered when the build finishes.
     */
    public void buildFinished(BuildEvent event) {
        if (diamondsListeners != null) {
            for (DiamondsListener diamondsListener : diamondsListeners) {
                try {
                    diamondsListener.buildEnd(event);
                } catch (DiamondsException e) {
                    log.error("Failed to log in diamonds: " + e);
                }

            }
        }
        project = event.getProject();
        cleanup();
    }

    /**
     * See if build needs a final cleanup target to be called.
     */
    private void cleanup() {
        String loggingoutputfile = project.getProperty("logging.output.file");
        if (loggingoutputfile != null) {
            File file = new File(loggingoutputfile);
            if (file.exists()) {
                file.delete();
            }
        }
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