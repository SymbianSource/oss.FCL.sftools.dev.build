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
import org.apache.maven.scm.command.branch.BranchScmResult;
import org.apache.maven.scm.manager.ScmManager;
import org.apache.maven.scm.repository.ScmRepository;
import org.apache.tools.ant.BuildException;

/**
 * This action will create new branch using a specific name.
 *
 * <pre>
 * &lt;hlm:scm verbose="true" scmUrl="scm:${repo.type}:${repo.dir}/test1"&gt;
 *    &lt;hlm:branch baseDir="${repo.dir}/test1" name="test branch 1.0" /&gt;
 * &lt;/hlm:scm&gt;
 * </pre>
 *
 * @ant.type name="branch" category="SCM"
 */
public class BranchAction extends BaseDirectoryScmAction {

    private String name;

    /**
     * Sets the branch name
     * 
     * @param name
     * @ant.required
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void execute(ScmRepository repository) {

        if (name == null)
            throw new BuildException("'name' attribute is not defined.");

        ScmManager scmManager = getTask().getScmManager();
        BranchScmResult result;

        try {
            result = scmManager.branch(repository, getScmFileSet(), name);
            if (!result.isSuccess()) {
                throw new BuildException("SCM branch action error: "
                        + result.getProviderMessage());
            }
            getTask().log(
                    "Branch '" + name + "' has been created successfully.");
        } catch (ScmException e) {
            throw new BuildException("SCM Branch action failed: "
                    + e.toString());
        }

    }
}
