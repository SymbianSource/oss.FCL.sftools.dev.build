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

import org.apache.log4j.Logger;
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
    private static StatusAndLogListener self;
    
    private Vector<BuildEventHandler> buildHandlers = new Vector<BuildEventHandler>();
    private Vector<TargetEventHandler> targetHandlers = new Vector<TargetEventHandler>();
    private Vector<TaskEventHandler> taskHandlers = new Vector<TaskEventHandler>();
    private Vector<MessageEventHandler> messageHandlers = new Vector<MessageEventHandler>();
    private Vector<SubBuildEventHandler> subBuildHandlers = new Vector<SubBuildEventHandler>();
    private Project project;
    private Logger log = Logger.getLogger(getClass());

    /**
     * Default constructor
     */
    public StatusAndLogListener() {
        self = this;
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
    public synchronized void buildStarted(BuildEvent event) {
        project = event.getProject();
        for (BuildEventHandler handler : buildHandlers) {
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
    public synchronized void buildFinished(BuildEvent event) {
        for ( BuildEventHandler handler : buildHandlers ) {
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
    public synchronized void targetStarted(BuildEvent event) {
        for (TargetEventHandler handler : targetHandlers) {
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
    public synchronized void targetFinished(BuildEvent event) {
        for (TargetEventHandler handler : targetHandlers) {
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
    public synchronized void taskStarted(BuildEvent event) {
        for (TaskEventHandler handler : taskHandlers) {
            handler.handleTaskStarted(event);
        }
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
    public synchronized void taskFinished(BuildEvent event) {
        for (TaskEventHandler handler : taskHandlers) {
            handler.handleTaskFinished(event);
        }
    }
    
    /**
     * Signals that a subbuild has started. This event is fired before any targets have started. 
     * @param event
     */
    public synchronized void subBuildStarted(BuildEvent event) {
        for (SubBuildEventHandler handler : subBuildHandlers) {
            handler.handleSubBuildStarted(event);
        }
    }
    
    /**
     * Signals that the last target has finished. This event will still be fired if an error occurred during the build. 
     * @param event
     */
    
    public synchronized void subBuildFinished(BuildEvent event) {
        for (SubBuildEventHandler handler : subBuildHandlers) {
            handler.handleSubBuildStarted(event);
        }
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
    public synchronized void messageLogged(BuildEvent event) {
        for (MessageEventHandler handler : messageHandlers) {
            handler.handleMessageLogged(event);
        }
    }

    /**
     * Register the given handler.
     * 
     * @param handler
     *            is the handler to register
     */
    public synchronized void register ( Handler handler ) {
        Vector<BuildEventHandler> tmpBuildHandlers = new Vector<BuildEventHandler>(buildHandlers);
        tmpBuildHandlers.add( handler );
        buildHandlers = tmpBuildHandlers;
        Vector<TargetEventHandler> tmpTargetHandlers = new Vector<TargetEventHandler>(targetHandlers);
        tmpTargetHandlers.add( handler );
        targetHandlers  = tmpTargetHandlers;
    }
    
    /**
     * Register the given handler.
     * 
     * @param handler
     *            is the handler to register
     */
    public synchronized void remove ( Handler handler ) {
        Vector<BuildEventHandler> tmpBuildHandlers = new Vector<BuildEventHandler>(buildHandlers);
        tmpBuildHandlers.remove( handler );
        buildHandlers = tmpBuildHandlers;
        Vector<TargetEventHandler> tmpTargetHandlers = new Vector<TargetEventHandler>(targetHandlers);
        tmpTargetHandlers.remove( handler );
        targetHandlers  = tmpTargetHandlers;
    }

    /**
     * Register the given handler.
     * 
     * @param handler
     *            is the handler to register
     */
    public synchronized void register ( BuildEventHandler handler ) {
        Vector<BuildEventHandler> tmp = new Vector<BuildEventHandler>(buildHandlers);
        tmp.add( handler );
        buildHandlers = tmp;
    }
    
    /**
     * Remove the given handler.
     * 
     * @param handler
     *            is the handler to register
     */
    public synchronized void remove ( BuildEventHandler handler ) {
        Vector<BuildEventHandler> tmp = new Vector<BuildEventHandler>(buildHandlers);
        tmp.remove( handler );
        buildHandlers = tmp;
    }
    
    /**
     * Register the given handler.
     * 
     * @param handler
     *            is the handler to register
     */
    public synchronized void register ( TargetEventHandler handler ) {
        Vector<TargetEventHandler> tmp = new Vector<TargetEventHandler>(targetHandlers);
        tmp.add( handler );
        targetHandlers  = tmp;
    }
    
    /**
     * Remove the given handler.
     * 
     * @param handler
     *            is the handler to register
     */
    public synchronized void remove ( TargetEventHandler handler ) {
        Vector<TargetEventHandler> tmp = new Vector<TargetEventHandler>(targetHandlers);
        tmp.remove( handler );
        targetHandlers  = tmp;
    }
    
    
    /**
     * Register the given SubBuildEventHandler.
     * 
     * @param handler
     *            is the handler to register
     */
    public synchronized void register ( SubBuildEventHandler handler ) {
        Vector<SubBuildEventHandler> tmp = new Vector<SubBuildEventHandler>(subBuildHandlers);
        tmp.add( handler );
        subBuildHandlers  = tmp;
    }

    /**
     * Remove the given SubBuildEventHandler.
     * 
     * @param handler
     *            is the handler to register
     */
    public synchronized void remove ( SubBuildEventHandler handler ) {
        Vector<SubBuildEventHandler> tmp = new Vector<SubBuildEventHandler>(subBuildHandlers);
        tmp.remove( handler );
        subBuildHandlers  = tmp;
    }

    /**
     * Register the given MessageEventHandler.
     * 
     * @param handler
     *            is the handler to register
     */
    public synchronized void register ( MessageEventHandler handler ) {
        Vector<MessageEventHandler> tmp = new Vector<MessageEventHandler>(messageHandlers);
        tmp.add( handler );
        messageHandlers  = tmp;
    }
    
    /**
     * Remove the given MessageEventHandler.
     * 
     * @param handler
     *            is the handler to register
     */
    public synchronized void remove ( MessageEventHandler handler ) {
        Vector<MessageEventHandler> tmp = new Vector<MessageEventHandler>(messageHandlers);
        tmp.remove( handler );
        messageHandlers  = tmp;
    }

    /**
     * Register the given TaskEventHandler.
     * 
     * @param handler
     *            is the handler to register
     */
    public synchronized void register ( TaskEventHandler handler ) {
        Vector<TaskEventHandler> tmp = new Vector<TaskEventHandler>(taskHandlers);
        tmp.add( handler );
        taskHandlers  = tmp;
    }
    
    /**
     * Remove the given TaskEventHandler.
     * 
     * @param handler
     *            is the handler to register
     */
    public synchronized void remove ( TaskEventHandler handler ) {
        Vector<TaskEventHandler> tmp = new Vector<TaskEventHandler>(taskHandlers);
        tmp.remove( handler );
        taskHandlers  = tmp;
    }


    /**
     * Return root project.
     * @return
     */
    public Project getProject() {
      return project;   
    }
    
    /**
     * Get the main StatusAndLogListener.
     * @return
     */
    public static StatusAndLogListener getStatusAndLogListener() {
        return self;
    }
    
    /**
     * Check and return required type handler.
     * @param handlerType
     * @return
     */
    public synchronized Handler getHandler(Class<?> handlerType) {
        for (BuildEventHandler handler : buildHandlers) {
            if (handlerType.isInstance(handler)) {
                return (Handler)handler;
            }
        }
        return null;
    }

}
