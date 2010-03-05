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

import java.util.List;

import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFile;
import org.apache.maven.scm.ScmTag;
import org.apache.maven.scm.command.update.UpdateScmResult;
import org.apache.maven.scm.manager.ScmManager;
import org.apache.maven.scm.repository.ScmRepository;
import org.apache.tools.ant.BuildException;
import org.apache.maven.scm.ScmRevision;

import com.nokia.helium.scm.ant.types.Tag;
import com.nokia.helium.scm.ant.types.Revision;

/**
 * Update the defined project for a specific revision or tag.
 * 
 * <pre>
 * &lt;hlm:scm verbose="true" scmUrl="scm:${repo.type}:${repo.dir}/test1"&gt;
 *     &lt;hlm:update basedir="${repo.dir}/test1" /&gt;
 * &lt;/hlm:scm&gt;
 *</pre>
 *
 * @ant.type name="update" category="SCM"
 */
public class UpdateAction extends BaseDirectoryScmAction {

    private Tag tag;
    private Revision revision;

    public void add(Tag tag) {
        this.tag = tag;
    }

    public Tag createTag() {
        this.tag = new Tag();
        return this.tag;
    }

    public void add(Revision revision) {
        this.revision = revision;
    }

    public Revision createRevision() {
        this.revision = new Revision();
        return this.revision;
    }

    @Override
    @SuppressWarnings("unchecked")
    public void execute(ScmRepository repository) throws ScmException {
        ScmManager scmManager = getTask().getScmManager();

        UpdateScmResult result;
        try {
            if (tag != null) {
                result = scmManager.update(repository, getScmFileSet(),
                        new ScmTag(tag.getName()));
            } else if (revision != null) {
                result = scmManager.update(repository, getScmFileSet(),
                        new ScmRevision(revision.getName()));
            } else {
                result = scmManager.update(repository, getScmFileSet());
            }

            if (!result.isSuccess()) {
                throw new BuildException("SCM update action error: "
                        + result.getProviderMessage());
            }

            List<ScmFile> files = result.getUpdatedFiles();
            for (ScmFile scmFile : files) {
                getTask().log(scmFile.toString());
            }
        } catch (RuntimeException e) {
            throw new BuildException("SCM update action failed: "
                    + e.getMessage());
        }

    }

}
