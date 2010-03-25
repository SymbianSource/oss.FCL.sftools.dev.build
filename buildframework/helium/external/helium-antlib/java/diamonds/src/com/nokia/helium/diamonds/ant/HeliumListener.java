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
import java.util.Hashtable;
import java.util.List;
import java.util.ArrayList;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.BuildException;
import com.nokia.helium.diamonds.*;
import com.nokia.helium.core.PropertiesSource;
import com.nokia.helium.core.TemplateProcessor;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.Project;
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
public class HeliumListener implements BuildListener {

    private Logger log = Logger.getLogger(HeliumListener.class);

    private List<DiamondsListener> diamondsListeners;

    private Project project;

    private boolean isInitialized;

    private boolean skipDiamonds;
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
        String targetName = event.getTarget().getName();
        project = event.getProject();

        String skip = project.getProperty("skip.diamonds");
        if (skip != null && skip.equals("true")) {
            skipDiamonds = true;
        }
        try {
            if (!skipDiamonds) {
                if (!isInitialized) {
                    String configFile = project
                            .getProperty("diamonds.listener.configuration.file");
                    parseConfig(configFile, project.getProperties());
                    isInitialized = true;
                }
                DiamondsProperties diamondProperties = DiamondsConfig
                        .getDiamondsProperties();

                /**
                 * Initialize Diamonds if and only if initializer-target-name has been called
                 */
                if (targetName.equals(DiamondsConfig.getInitialiserTargetName())) {                                        
                    String categoryName = diamondProperties.getProperty("category-property");
                    String category = project.getProperty(categoryName);
                    log.debug("category:" + category);
                    if (category != null && diamondsListeners.isEmpty()) {
                        addListeners(event);
                        log.info("Diamonds enabled");
                    }
                }
            } else {
                if (!skipDiamondsSet && skipDiamonds)
                {
                    log.info("skip.diamonds set, to use diamonds don't set skip.diamonds.");
                    skipDiamondsSet = true;
                }
            }
        } catch (Exception ex) {
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
                } catch (Exception e) {
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

    @SuppressWarnings("unchecked") 
    private void parseConfig(String configFile, Hashtable<String, String> antProperties) {
        TemplateProcessor templateProcessor = new TemplateProcessor();
        File outputFile = null;
        try {
            outputFile = File.createTempFile("diamonds", "-config.xml");
            outputFile.deleteOnExit();
            log
                    .debug("Preprocessing the diamonds configuration: "
                            + configFile);
            List sourceList = new ArrayList();
            sourceList.add(new PropertiesSource("ant", antProperties));
            templateProcessor.convertTemplate(configFile,
                    outputFile.toString(), sourceList);
        } catch (Exception e) {
            throw new BuildException(
                    "Diamonds configuration pre-parsing error: "
                            + e.getMessage());
        }
        try {
            DiamondsConfig.parseConfiguration(outputFile.toString());
        } catch (Exception e) {
            throw new BuildException("Diamonds configuration parsing error: "
                    + e.getMessage());
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
    }

    /**
     * Triggered when a target finishes.
     */
    public void targetFinished(BuildEvent event) {
        if (diamondsListeners != null) {
            for (DiamondsListener diamondsListener : diamondsListeners) {
                try {
                    diamondsListener.targetEnd(event);
                } catch (Exception e) {
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
                } catch (Exception e) {
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
            File f = new File(loggingoutputfile);
            if (f.exists())
                f.delete();
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