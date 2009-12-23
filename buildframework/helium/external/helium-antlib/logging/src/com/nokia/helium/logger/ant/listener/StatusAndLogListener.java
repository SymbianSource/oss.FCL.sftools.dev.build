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
package com.nokia.helium.logger.ant.listener;

import java.util.Vector;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.SubBuildListener;
import org.apache.tools.ant.Project;

/**
 * <code>StatusAndLogListener</code> implements {@link BuildListener} and
 * listens to build events in particularly for activities such as ant logging
 * and displaying build stage summary at the end of build process.
 * 
 */
public class StatusAndLogListener implements BuildListener, SubBuildListener {

    private static Vector<Handler> handlers = new Vector<Handler>();
    private static Project project;
    
    /**
     * Default constructor
     */
    public StatusAndLogListener() {
    }

    /**
     * Signals that the last target has finished. This event will still be fired
     * if an error occurred during the build.
     * 
     * @param event
     *            An event with any relevant extra information. Must not be
     *            <code>null</code>.
     * 
     * @see BuildEvent#getException()
     */
    public void buildStarted(BuildEvent event) {
        project = event.getProject();
        for (Handler handler : handlers) {
            handler.handleBuildStarted(event);
        }
        
    }
    /**
     * Signals that a build has started. This event is fired before any targets
     * have started.
     * 
     * @param event
     *            An event with any relevant extra information. Must not be
     *            <code>null</code>.
     */
    public void buildFinished(BuildEvent event) {
        for ( Handler handler : handlers ) {
            handler.handleBuildFinished( event );
        }
    }
    

    /**
     * Signals that a target is starting.
     * 
     * @param event
     *            An event with any relevant extra information. Must not be
     *            <code>null</code>.
     * 
     * @see BuildEvent#getTarget()
     */
    public void targetStarted(BuildEvent event) {
        for (Handler handler : handlers) {
            handler.handleTargetStarted(event);
        }
    }

    /**
     * Signals that a target has finished. This event will still be fired if an
     * error occurred during the build.
     * 
     * @param event
     *            An event with any relevant extra information. Must not be
     *            <code>null</code>.
     * 
     * @see BuildEvent#getException()
     */
    public void targetFinished(BuildEvent event) {
        for (Handler handler : handlers) {
            handler.handleTargetFinished(event);
        }
    }

    /**
     * Signals that a task is starting.
     * 
     * @param event
     *            An event with any relevant extra information. Must not be
     *            <code>null</code>.
     * 
     * @see BuildEvent#getTask()
     */
    public void taskStarted(BuildEvent event) {
        // implement if needed
    }

    /**
     * Signals that a task has finished. This event will still be fired if an
     * error occurred during the build.
     * 
     * @param event
     *            An event with any relevant extra information. Must not be
     *            <code>null</code>.
     * 
     * @see BuildEvent#getException()
     */
    public void taskFinished(BuildEvent event) {
        // implement if needed
    }
    
    /**
     * Signals that a subbuild has started. This event is fired before any targets have started. 
     * @param event
     */
    public void subBuildStarted(BuildEvent event) {
         
    }
    
    /**
     * Signals that the last target has finished. This event will still be fired if an error occurred during the build. 
     * @param event
     */
    
    public void subBuildFinished(BuildEvent event) {
        
    }
    
    

    /**
     * Signals a message logging event.
     * 
     * @param event
     *            An event with any relevant extra information. Must not be
     *            <code>null</code>.
     * 
     * @see BuildEvent#getMessage()
     * @see BuildEvent#getException()
     * @see BuildEvent#getPriority()
     */
    public void messageLogged(BuildEvent event) {
        // implement if needed

    }

    /**
     * Register the given handler.
     * 
     * @param handler
     *            is the handler to register
     */
    public static void register ( Handler handler ) {
        handlers.add( handler );
    }
    
    /**
     * Return root project name.
     * @return
     */
    public static Project getProject() {
      return project;   
    }
    
    
    /**
     * Check and return required type handler.
     * @param handlerType
     * @return
     */
    public static Handler getHandler(Class handlerType) {
        for (Handler handler : handlers) {
            if (handlerType.isInstance(handler)) {
                return handler;
            }
        }
        return null;
    }

}
