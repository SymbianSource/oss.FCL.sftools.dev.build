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
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.command.tag.TagScmResult;
import org.apache.maven.scm.repository.ScmRepository;
import org.apache.tools.ant.BuildException;

import com.nokia.maven.scm.manager.ExtendedScmManager;

/**
 * This action will tag current repository revision using a specific name.
 * 
 * <pre>
 * &lt;hlm:scm verbose="true" scmUrl="scm:${repo.type}:${repo.dir}/test1"&gt;
 *     &lt;hlm:tag baseDir="${repo.dir}/test1" name="0.0.1" /&gt;
 * &lt;/hlm:scm&gt;
 * </pre>
 *
 * @ant.type name="tag" category="SCM"
 */
public class TagAction extends BaseDirectoryScmAction {
    private String name;
    private String level = "normal";

    /**
     * String that will be used to tag the current revision.
     * 
     * @param name
     *            Name of the tag
     * @ant.required
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * String that will be used to determine tag types, eg. local.
     * 
     * @param level
     *            Level of the tag eg.local
     * @ant.not-required
     */
    public void setLevel(String level) {
        this.level = level;
    }

    @Override
    public void execute(ScmRepository repository) throws ScmException {
        TagScmResult result;

        if (name == null)
            throw new BuildException("'name' attribute is not defined.");

        if (getBasedir() == null)
            throw new BuildException("'basedir' attribute is not defined.");

        try {
            ExtendedScmManager scmManager = (ExtendedScmManager) getTask()
                    .getScmManager();
            if (level.equals(new String("local"))) {
                result = scmManager.tag(repository, new ScmFileSet(new File(
                        getBasedir())), name, level);
            } else {
                result = scmManager.tag(repository, new ScmFileSet(new File(
                        getBasedir())), name);
            }

            if (!result.isSuccess()) {
                throw new BuildException("SCM tag action error: "
                        + result.getProviderMessage());
            }
            getTask().log("Tag '" + name + "' has been created successfully.");
        } catch (ScmException e) {
            throw new BuildException("SCM tag action failed: " + e.toString());
        }

    }
}
