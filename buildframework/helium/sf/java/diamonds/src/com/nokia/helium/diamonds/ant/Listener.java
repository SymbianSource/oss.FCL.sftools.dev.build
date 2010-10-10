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

import java.net.MalformedURLException;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.Project;


import com.nokia.helium.core.ant.Message;
import com.nokia.helium.diamonds.DiamondsConfig;
import com.nokia.helium.diamonds.DiamondsException;
import com.nokia.helium.diamonds.DiamondsListener;
import com.nokia.helium.diamonds.DiamondsSession;
import com.nokia.helium.diamonds.DiamondsSessionSocket;

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
public class Listener implements BuildListener {

    private static final String INITIAL_MESSAGE = "initial.message";
    private static final String FINAL_MESSAGE = "final.message";
    private static final String BUILD_START_TIME_PROPERTY = "build.start.time";
    private static final String BUILD_END_TIME_PROPERTY = "build.end.time";
    private Project project;
    private DiamondsConfig config;
    private DiamondsSession session;
    private List<DiamondsListener> diamondsListeners = new ArrayList<DiamondsListener>();
    private Date startTime = new Date();

    public DiamondsConfig getConfiguration() {
        return config;
    }
    
    public DiamondsSession getSession() {
        return session;
    }

    public Project getProject() {
        return project;
    }
    
    /**
     * Ant call this function when build start.
     */
    public void buildStarted(BuildEvent event) {
    }

    private Message getMessage(String messageId) throws DiamondsException {
        Object obj = project.getReference(messageId);
        if (obj != null && obj instanceof Message) {
            return (Message)obj;
        }
        throw new DiamondsException("Could not find message '" + messageId + "'");
    }
    
    /**
     * Triggered when a target starts.
     */
    public void targetStarted(BuildEvent event) {
        if (project == null) {
            project = event.getProject(); 
            try {
                config = new DiamondsConfig(project);
                
                // Set initial start time property.
                SimpleDateFormat timeFormat = new SimpleDateFormat(config.getTimeFormat());
                project.setProperty(BUILD_START_TIME_PROPERTY, timeFormat.format(startTime));                
            } catch (DiamondsException e) {
                config = null;
                project.log("Diamonds reporting is disabled, because the listener is not configured properly: " + e.getMessage(), Project.MSG_ERR);
            }
            if (config == null || !config.isDiamondsEnabled()) {
                project.log("'diamonds.enabled' is not true, to use diamonds set 'diamonds.enabled' to 'true'.");
            } else {
                try {
                    for (Object object : project.getReferences().values()) {
                        if (object instanceof DiamondsListener) {
                            DiamondsListener diamondsListener = (DiamondsListener)object;
                            diamondsListener.configure(this);
                            project.log("Adding DiamondsListener: " + diamondsListener.getClass(), Project.MSG_DEBUG);
                            diamondsListeners.add(diamondsListener);
                        }
                    }
                } catch (DiamondsException e) {
                    throw new BuildException("Diamonds listener is not configured properly: " + e.getMessage(), e);
                }
            }
            for (DiamondsListener diamondsListener : diamondsListeners) {
                try {
                    diamondsListener.buildStarted(new BuildEvent(project));
                } catch (DiamondsException e) {
                    // Voluntarily ignoring errors happening.
                    project.log(e.getMessage(), Project.MSG_ERR);
                }
            }            
        }
        
        if (config != null && config.isDiamondsEnabled() && session == null) {
            String buildId = project.getProperty(config.getBuildIdProperty());
            try {
                if (session == null && buildId != null) {
                    project.log("Reusing diamonds session with the following build id: " + buildId);
                    // we have a pre-configured build id.
                    session = new DiamondsSessionSocket(new URL("http", config.getHost(),
                            Integer.parseInt(config.getPort()), config.getPath()),
                            config.getMailInfo(), config.getSMTPServer(), config.getLDAPServer(), buildId);
                } else if (session == null && event.getTarget().getName().equals(config.getInitializerTargetName())) {
                    session = new DiamondsSessionSocket(new URL("http", config.getHost(), 
                            Integer.parseInt(config.getPort()), config.getPath()),
                            config.getMailInfo(), config.getSMTPServer(), config.getLDAPServer());
                    session.open(getMessage(INITIAL_MESSAGE));
                    // defining build id on the both root project, and current target project. 
                    event.getTarget().getProject().setProperty(config.getBuildIdProperty(), session.getBuildId());
                    project.setProperty(config.getBuildIdProperty(), session.getBuildId());
                    project.log("Diamonds build id: " + project.getProperty(config.getBuildIdProperty()));
                }
            } catch (NumberFormatException e) {
                project.log(e.getMessage(), Project.MSG_ERR);
                project.log("Diamonds reporting will be disabled.", Project.MSG_ERR);
                session = null;
            } catch (MalformedURLException e) {
                project.log(e.getMessage(), Project.MSG_ERR);
                project.log("Diamonds reporting will be disabled.", Project.MSG_ERR);
                session = null;
            } catch (DiamondsException e) {
                project.log(e.getMessage(), Project.MSG_ERR);
                project.log("Diamonds reporting will be disabled.", Project.MSG_ERR);
                session = null;
            }
        } else if (session != null && session.isOpen()) {
            for (DiamondsListener diamondsListener : diamondsListeners) {
                try {
                    diamondsListener.targetStarted(event);
                } catch (DiamondsException e) {
                    // Voluntarily ignoring errors happening.
                    project.log(e.getMessage(), Project.MSG_ERR);
                }
            }
        }
    }


    /**
     * Triggered when a target finishes.
     */
    public void targetFinished(BuildEvent event) {
        if (config != null && config.isDiamondsEnabled() && session != null && session.isOpen()) {
            for (DiamondsListener diamondsListener : diamondsListeners) {
                try {
                    diamondsListener.targetFinished(event);
                } catch (DiamondsException e) {
                    // Voluntarily ignoring errors happening.
                    project.log(e.getMessage(), Project.MSG_ERR);
                }
            }            
        }
    }

    /**
     * Triggered when the build finishes.
     */
    public void buildFinished(BuildEvent event) {
        if (config != null && config.isDiamondsEnabled() && session != null && session.isOpen()) {            
            // Setting the final timestamp
            SimpleDateFormat timeFormat = new SimpleDateFormat(config.getTimeFormat());
            project.setProperty(BUILD_END_TIME_PROPERTY, timeFormat.format(new Date()));
            for (DiamondsListener diamondsListener : diamondsListeners) {
                try {
                    diamondsListener.buildFinished(event);
                } catch (DiamondsException e) {
                    // Voluntarily ignoring errors happening.
                    project.log(e.getMessage(), Project.MSG_ERR);
                }
            }            
            try {
                // Sending the message
                Message message = getMessage(FINAL_MESSAGE);
                session.close(message);
            } catch (DiamondsException e) {
                project.log(e.getMessage(), Project.MSG_ERR);
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
    
    
    public static Listener getDiamondsListener(Project project) {
        for (Object bl : project.getBuildListeners()) {
            if (bl instanceof Listener) {
                return (Listener)bl;
            }
        }
        return null;
    }
}