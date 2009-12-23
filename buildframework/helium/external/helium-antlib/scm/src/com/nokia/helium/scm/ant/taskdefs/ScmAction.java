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

package com.nokia.helium.scm.ant.taskdefs;

import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.repository.ScmRepository;
import org.apache.tools.ant.ProjectComponent;

/**
 * Abstract class which implements common setting between
 * ScmAction implementations.
 * 
 * Any implementing action must implement the execute method as
 * a execution of the action. The owning task should be used
 * to log message to the user.  
 */
public abstract class ScmAction extends ProjectComponent {
    private ScmTask scmtask;

    /**
     * @return the task
     */
    public ScmTask getTask() {
        return scmtask;
    }

    /**
     * @param task
     *            the task to set
     */
    public void setTask(ScmTask task) {
        this.scmtask = task;
    }

    /**
     * Get the action name based on the classname.
     * @return the lowercase class name. 
     */
    public String getName() {
        String className = getClass().getName();
        String commandName = className
                .substring(className.lastIndexOf('.') + 1).toLowerCase();
        return commandName;
    }

    /**
     * This method needs to be implemented by your subclass.
     * It is executed during the Task execute to achieve
     * the relevant action.
     * @param repository
     * @throws ScmException
     */
    public abstract void execute(ScmRepository repository) throws ScmException;
}
