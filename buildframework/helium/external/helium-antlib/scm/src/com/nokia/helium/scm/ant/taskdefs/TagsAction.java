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
import java.util.List;

import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmTag;
import org.apache.maven.scm.repository.ScmRepository;
import org.apache.tools.ant.BuildException;

import com.nokia.helium.scm.ant.types.TagSet;
import com.nokia.maven.scm.command.tags.TagsScmResult;
import com.nokia.maven.scm.manager.ExtendedScmManager;

public class TagsAction extends BaseDirectoryScmAction {

    private String reference;

    public void setReference(String reference) {
        this.reference = reference;
    }

    @Override
    public void execute(ScmRepository repository) throws ScmException {
        TagsScmResult result;
        try {
            ExtendedScmManager scmManager = (ExtendedScmManager) getTask()
                    .getScmManager();
            result = scmManager.tags(repository, new File(this.getBasedir()));
            if (!result.isSuccess()) {
                throw new BuildException("SCM tags action error: "
                        + result.getProviderMessage());
            }

            // Creating a TagSet
            List<ScmTag> tags = result.getTags();
            TagSet tagSet = new TagSet();
            tagSet.setProject(getProject());
            getTask().log("Tag list:");
            for (ScmTag tag : tags) {
                tagSet.createTag().setName(tag.getName());
                getTask().log(" * " + tag.getName());
            }
            // Creating new reference
            if (reference != null) {
                getTask().log("Creating reference: " + reference);
                getProject().addReference(reference, tagSet);
            }

        } catch (ScmException e) {
            throw new BuildException("SCM tags action failed: "
                    + e.getMessage());
        }

    }
}
