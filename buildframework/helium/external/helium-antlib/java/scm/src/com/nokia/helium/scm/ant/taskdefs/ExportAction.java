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
import java.util.ArrayList;
import java.util.List;

import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmTag;
import org.apache.maven.scm.command.export.ExportScmResult;
import org.apache.maven.scm.manager.ScmManager;
import org.apache.maven.scm.repository.ScmRepository;
import org.apache.tools.ant.BuildException;

import com.nokia.helium.scm.ant.types.Tag;

/**
 * Get a snapshot of a particular revision into a folder.
 *
 * <pre>
 * &lt;hlm:scm verbose="true" scmUrl="scm:${repo.type}:${repo.dir}/test2"&gt;
 *    &lt;hlm:export basedir="${repo.dir}/test2" destpath="${repo.dir}/export" /&gt;
 * &lt;/hlm:scm&gt;
 * </pre>
 *
 * @ant.type name="export" category="SCM"
 */
public class ExportAction extends BaseDirectoryScmAction {

    private File destPath;
    private List<Tag> tags = new ArrayList<Tag>();

    /**
     * Create a tag sub-element.
     * @return the tag element.
     */
    public Tag createTag() {
        Tag tag = new Tag();
        add(tag);
        return tag;
    }

    /**
     * Add a tag.
     * @param tag
     */
    public void add(Tag tag) {
        tags.add(tag);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void execute(ScmRepository repository) throws ScmException {
        ScmManager scmManager = getTask().getScmManager();

        if (getDestPath() == null)
            throw new ScmException("destPath attribute has not been provided.");

        if (tags.size() > 1)
            throw new ScmException(
                    "You can only specify one tag nested element.");

        ExportScmResult result;
        try {
            if (tags.size() == 0) {
                getTask().log(
                        "Exporting " + getScmFileSet().getBasedir() + " under "
                                + getDestPath().getAbsolutePath() + ".");
                result = scmManager.export(repository, getScmFileSet(),
                        getDestPath().getAbsolutePath());
            } else {
                String t = tags.get(0).getName();
                getTask().log(
                        "Exporting revision " + t + " of "
                                + getScmFileSet().getBasedir() + " under "
                                + getDestPath().getAbsolutePath() + ".");
                result = scmManager.export(repository, getScmFileSet(),
                        new ScmTag(t), getDestPath().getAbsolutePath());
            }
        } catch (ScmException e) {
            throw new BuildException("SCM export action failed: " + e);
        }
        if (!result.isSuccess()) {
            throw new BuildException("SCM export action failed: "
                    + result.getProviderMessage());
        }
        // Dump created files.
        for (Object file : result.getExportedFiles().toArray()) {
            getTask().log(file.toString());
        }
    }

    public File getDestPath() {
        return destPath;
    }

    public void setDestPath(File destPath) {
        this.destPath = destPath;
    }

}
