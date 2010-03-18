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
import org.apache.maven.scm.command.remove.RemoveScmResult;
import org.apache.maven.scm.manager.ScmManager;
import org.apache.maven.scm.repository.ScmRepository;
import org.apache.tools.ant.BuildException;

/**
 * Remove a set of file(s) from SCM control.
 * 
 * <pre>
 * &lt;hlm:scm verbose="true" scmUrl="scm:${repo.type}:${repo.dir}/test1"&gt;
 *    &lt;hlm:remove message="Nothing to remove..."&gt;
 *        &lt;fileset dir="${repo.dir}/test1"&gt;
 *            &lt;include name="not_in_repo.txt" /&gt;
 *        &lt;/fileset&gt;
 *    &lt;/hlm:remove&gt;
 * &lt;/hlm:scm&gt;
 * </pre>
 *
 * @ant.type name="remove" category="SCM"
 */
public class RemoveAction extends BaseDirectoryScmAction {
    private String message;

    public String getMessage() {
        return message;
    }

    /**
     * @param message
     *            the message associated to the change
     * @ant.required
     */
    public void setMessage(String message) {
        this.message = message;
    }

    @Override
    public void execute(ScmRepository repository) throws ScmException {
        if (message == null)
            throw new BuildException("message attribute has not been defined.");
        // if (getBasedir() == null)
        // throw new BuildException("basedir attribute has not been defined.");

        ScmManager scmManager = getTask().getScmManager();
        RemoveScmResult result;
        try {
            result = scmManager.remove(repository, getScmFileSet(), message);
        } catch (ScmException e) {
            throw new BuildException("SCM remove action failed: " + e);
        }

        if (!result.isSuccess()) {
            throw new BuildException("SCM remove action failed.");
        }
    }
}
