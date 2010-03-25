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
import org.apache.maven.scm.command.checkout.CheckOutScmResult;
import org.apache.maven.scm.manager.ScmManager;
import org.apache.maven.scm.repository.ScmRepository;
import org.apache.tools.ant.BuildException;
import org.apache.maven.scm.ScmRevision;
import org.apache.maven.scm.ScmTag;

import com.nokia.helium.scm.ant.types.Tag;
import com.nokia.helium.scm.ant.types.Revision;

import java.util.ArrayList;
import java.util.List;

/**
 * Checkout the defined project. Depending on the kind of repository used this
 * can mean for example the cloning of a repository in the case of Mercurial or the copying of 
 * a repository in the case of SVN.
 *
 * <pre>
 * &lt;hlm:scm verbose="true" scmUrl="scm:${repo.type}:${repo.dir}/test3"&gt;
 *     &lt;hlm:checkout baseDir="${repo.dir}/cloned" /&gt;
 * &lt;/hlm:scm&gt;
 * </pre>
 *
 * @ant.type name="checkout" category="SCM"
 */
public class CheckoutAction extends BaseDirectoryScmAction {
    private List<Tag> tags = new ArrayList<Tag>();
    private List<Revision> revisions = new ArrayList<Revision>();

    public Tag createTag() {
        Tag tag = new Tag();
        add(tag);
        return tag;
    }

    public void add(Tag tag) {
        tags.add(tag);
    }

    public Revision createRevision() {
        Revision revision = new Revision();
        add(revision);
        return revision;
    }

    public void add(Revision revision) {
        revisions.add(revision);
    }

    @Override
    public void execute(ScmRepository repository) throws ScmException {
        ScmManager scmManager = getTask().getScmManager();

        if (tags.size() > 1)
            throw new ScmException(
                    "You can only specify one tag nested element.");

        if (revisions.size() > 1)
            throw new ScmException(
                    "You can only specify one revision nested element.");

        if ((tags.size() == 1) && (revisions.size() == 1)) {
            throw new ScmException(
                    "You can not specify nested element 'revision' and 'tag' together.");
        }

        CheckOutScmResult result;
        try {
            if (tags.size() == 1) {
                result = scmManager.checkOut(repository, getScmFileSet(),
                        new ScmTag(tags.get(0).getName()));
            } else if (revisions.size() == 1) {
                result = scmManager.checkOut(repository, getScmFileSet(),
                        new ScmRevision(revisions.get(0).getName()));
            } else {
                result = scmManager.checkOut(repository, getScmFileSet());
            }
        } catch (ScmException e) {
            throw new BuildException("SCM checkout action failed: " + e);
        }

        if (!result.isSuccess()) {
            throw new BuildException("SCM checkout action failed.");
        }
    }
}
