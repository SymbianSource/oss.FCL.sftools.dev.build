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
package com.nokia.helium.scm.ant;

import org.apache.maven.scm.log.ScmLogger;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;

/**
 * This class provides an implementation of 
 * an ScmLogger using Ant logging for
 * reporting issues.
 *
 */
public class AntScmLogger implements ScmLogger {

    private Task task;
    
    /**
     * Creating an AntScmLogger instance using
     * a task to log messages.
     * @param task
     */
    public AntScmLogger(Task task) {
        this.task = task;
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void debug(String message) {
        task.log(message, Project.MSG_DEBUG);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void debug(Throwable cause) {
        task.log(cause.toString(), Project.MSG_DEBUG);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void debug(String message, Throwable cause) {
        task.log(message + " " + cause.toString(), Project.MSG_DEBUG);        
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void error(String message) {
        task.log(message, Project.MSG_ERR);        
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void error(Throwable cause) {
        task.log(cause.toString(), Project.MSG_ERR);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void error(String message, Throwable cause) {
        task.log(message + " " + cause.toString(), Project.MSG_ERR);        
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void info(String message) {
        task.log(message, Project.MSG_INFO);        
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void info(Throwable cause) {
        task.log(cause.toString(), Project.MSG_INFO);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void info(String message, Throwable cause) {
        task.log(message + " " + cause.toString(), Project.MSG_INFO);        
    }

    @Override
    public boolean isDebugEnabled() {
        return true;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public boolean isErrorEnabled() {
        return true;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public boolean isInfoEnabled() {
        return true;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public boolean isWarnEnabled() {
        return true;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void warn(String message) {
        task.log(message, Project.MSG_WARN);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void warn(Throwable cause) {
        task.log(cause.toString(), Project.MSG_WARN);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void warn(String message, Throwable cause) {
        task.log(message + " " + cause.toString(), Project.MSG_WARN);
    }

}
