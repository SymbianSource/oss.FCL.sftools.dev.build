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

import java.util.ArrayList;
import java.util.List;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.SubBuildListener;

/**
 * <code>CommonListener</code> implements {@link BuildListener} and listens to build events in
 * particularly for activities such as ant logging and displaying build stage summary at the end of
 * build process.
 * 
 */
public class CommonListener implements BuildListener, SubBuildListener {
    private static CommonListener self;
    private boolean initialized;

    private List<BuildEventHandler> buildHandlers = new ArrayList<BuildEventHandler>();
    private List<TargetEventHandler> targetHandlers = new ArrayList<TargetEventHandler>();
    private List<TaskEventHandler> taskHandlers = new ArrayList<TaskEventHandler>();
    private List<MessageEventHandler> messageHandlers = new ArrayList<MessageEventHandler>();
    private List<SubBuildEventHandler> subBuildHandlers = new ArrayList<SubBuildEventHandler>();
    private Project project;

    /**
     * Default constructor
     */
    public CommonListener() {
        // Declaring ourself globally.
        self = this;
    }

    /**
     * Signals that the last target has finished. This event will still be fired if an error
     * occurred during the build.
     * 
     * @param event An event with any relevant extra information. Must not be <code>null</code>.
     * 
     * @see BuildEvent#getException()
     */
    public synchronized void buildStarted(BuildEvent event) {
        project = event.getProject();
        for (BuildEventHandler handler : buildHandlers) {
            handler.buildStarted(event);
        }
    }

    /**
     * Signals that a build has started. This event is fired before any targets have started.
     * 
     * @param event An event with any relevant extra information. Must not be <code>null</code>.
     */
    public synchronized void buildFinished(BuildEvent event) {
        for (BuildEventHandler handler : buildHandlers) {
            handler.buildFinished(event);
        }
    }

    /**
     * Signals that a target is starting.
     * 
     * @param event An event with any relevant extra information. Must not be <code>null</code>.
     * 
     * @see BuildEvent#getTarget()
     */
    public synchronized void targetStarted(BuildEvent event) {
        if (!initialized) {
            // Let's introspect current project for registarable objects
            for (Object entry : getProject().getReferences().values()) {
                if (entry instanceof CommonListenerRegister) {
                    ((CommonListenerRegister) entry).register(this);
                    if (entry instanceof BuildEventHandler) {
                        ((BuildEventHandler)entry).buildStarted(new BuildEvent(getProject()));
                    }
                }
            }
            initialized = true;
        }
        for (TargetEventHandler handler : targetHandlers) {
            handler.targetStarted(event);
        }
    }

    /**
     * Signals that a target has finished. This event will still be fired if an error occurred
     * during the build.
     * 
     * @param event An event with any relevant extra information. Must not be <code>null</code>.
     * 
     * @see BuildEvent#getException()
     */
    public synchronized void targetFinished(BuildEvent event) {
        for (TargetEventHandler handler : targetHandlers) {
            handler.targetFinished(event);
        }
    }

    /**
     * Signals that a task is starting.
     * 
     * @param event An event with any relevant extra information. Must not be <code>null</code>.
     * 
     * @see BuildEvent#getTask()
     */
    public synchronized void taskStarted(BuildEvent event) {
        for (TaskEventHandler handler : taskHandlers) {
            handler.taskStarted(event);
        }
    }

    /**
     * Signals that a task has finished. This event will still be fired if an error occurred during
     * the build.
     * 
     * @param event An event with any relevant extra information. Must not be <code>null</code>.
     * 
     * @see BuildEvent#getException()
     */
    public synchronized void taskFinished(BuildEvent event) {
        for (TaskEventHandler handler : taskHandlers) {
            handler.taskFinished(event);
        }
    }

    /**
     * Signals that a subbuild has started. This event is fired before any targets have started.
     * 
     * @param event
     */
    public synchronized void subBuildStarted(BuildEvent event) {
        for (SubBuildEventHandler handler : subBuildHandlers) {
            handler.subBuildStarted(event);
        }
    }

    /**
     * Signals that the last target has finished. This event will still be fired if an error
     * occurred during the build.
     * 
     * @param event
     */

    public synchronized void subBuildFinished(BuildEvent event) {
        for (SubBuildEventHandler handler : subBuildHandlers) {
            handler.subBuildStarted(event);
        }
    }

    /**
     * Signals a message logging event.
     * 
     * @param event An event with any relevant extra information. Must not be <code>null</code>.
     * 
     * @see BuildEvent#getMessage()
     * @see BuildEvent#getException()
     * @see BuildEvent#getPriority()
     */
    public synchronized void messageLogged(BuildEvent event) {
        for (MessageEventHandler handler : messageHandlers) {
            handler.messageLogged(event);
        }
    }

    /**
     * Register the given handler.
     * 
     * @param handler is the handler to register
     */
    public synchronized void register(Object handler) {
        if (handler instanceof BuildEventHandler) {
            // The duplication of the list prevents concurrent modification exception.
            List<BuildEventHandler> temp = new ArrayList<BuildEventHandler>(buildHandlers); 
            temp.add((BuildEventHandler)handler);
            buildHandlers = temp;
        }
        if (handler instanceof TargetEventHandler) {
            List<TargetEventHandler> temp = new ArrayList<TargetEventHandler>(targetHandlers); 
            temp.add((TargetEventHandler)handler);
            targetHandlers = temp;
        }
        if (handler instanceof TaskEventHandler) {
            List<TaskEventHandler> temp = new ArrayList<TaskEventHandler>(taskHandlers); 
            temp.add((TaskEventHandler)handler);
            taskHandlers = temp;
        }
        if (handler instanceof MessageEventHandler) {
            List<MessageEventHandler> temp = new ArrayList<MessageEventHandler>(messageHandlers); 
            temp.add((MessageEventHandler)handler);
            messageHandlers = temp;
        }
    }

    /**
     * Register the given handler.
     * 
     * @param handler is the handler to register
     */
    public synchronized void unRegister(Object handler) {
        if (handler instanceof BuildEventHandler) {
            List<BuildEventHandler> temp = new ArrayList<BuildEventHandler>(buildHandlers); 
            temp.remove((BuildEventHandler)handler);
            buildHandlers = temp;
        }
        if (handler instanceof TargetEventHandler) {
            List<TargetEventHandler> temp = new ArrayList<TargetEventHandler>(targetHandlers); 
            temp.remove((TargetEventHandler)handler);
            targetHandlers = temp;
        }
        if (handler instanceof TaskEventHandler) {
            List<TaskEventHandler> temp = new ArrayList<TaskEventHandler>(taskHandlers); 
            temp.remove((TaskEventHandler)handler);
            taskHandlers = temp;
        }
        if (handler instanceof MessageEventHandler) {
            List<MessageEventHandler> temp = new ArrayList<MessageEventHandler>(messageHandlers); 
            temp.remove((MessageEventHandler)handler);
            messageHandlers = temp;
        }
    }
    
    /**
     * Return root project.
     * 
     * @return
     */
    public Project getProject() {
        return project;
    }

    /**
     * Get the main StatusAndLogListener.
     * 
     * @return
     */
    public static CommonListener getCommonListener() {
        return self;
    }

    /**
     * Check and return required type handler.
     * 
     * @param handlerType
     * @return
     */
    @SuppressWarnings("unchecked")
    public synchronized <T> T getHandler(Class<T> handlerType) {
        for (BuildEventHandler handler : buildHandlers) {
            if (handlerType.isInstance(handler)) {
                return (T)handler;
            }
        }
        for (TargetEventHandler handler : targetHandlers) {
            if (handlerType.isInstance(handler)) {
                return (T)handler;
            }
        }
        for (TaskEventHandler handler : taskHandlers) {
            if (handlerType.isInstance(handler)) {
                return (T)handler;
            }
        }
        for (MessageEventHandler handler : messageHandlers) {
            if (handlerType.isInstance(handler)) {
                return (T)handler;
            }
        }
        for (SubBuildEventHandler handler : subBuildHandlers) {
            if (handlerType.isInstance(handler)) {
                return (T)handler;
            }
        }
        return null;
    }

}
