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

import java.io.File;

import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.repository.ScmRepository;
import org.apache.tools.ant.BuildException;

import com.nokia.maven.scm.command.pull.PullScmResult;
import com.nokia.maven.scm.manager.ExtendedScmManager;

/**
 * Retrieve a set of changes from a remote database. This action is only
 * supported in distributed SCM such as Mercurial or Git.
 * 
 * @ant.type name="pull" category="SCM"
 */
public class PullAction extends BaseDirectoryScmAction {
    @Override
    public void execute(ScmRepository repository) throws ScmException {
        PullScmResult result;
        try {
            ExtendedScmManager scmManager = (ExtendedScmManager) getTask()
                    .getScmManager();
            result = scmManager.pull(repository, new File(this.getBasedir()));
            if (!result.isSuccess()) {
                throw new BuildException("SCM pull action error: "
                        + result.getProviderMessage());
            }
        } catch (ScmException e) {
            throw new BuildException("SCM pull action failed: "
                    + e.getMessage());
        }

    }
}
