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
import org.apache.maven.scm.ScmRevision;
import org.apache.maven.scm.command.diff.DiffScmResult;
import org.apache.maven.scm.manager.ScmManager;
import org.apache.maven.scm.repository.ScmRepository;
import org.apache.tools.ant.BuildException;

/**
 * Display the difference of the working copy with the latest copy in the
 * configured scm url.
 *
 * <pre>
 * &lt;hlm:scm verbose="true" scmUrl="scm:${repo.type}:${repo.dir}/test1"&gt;
 *    &lt;hlm:diff&gt;
 *        &lt;fileset dir="${repo.dir}/test1"&gt;
 *            &lt;include name="**" /&gt;
 *            &lt;exclude name="** /.${repo.type}/**" /&gt;
 *        &lt;/fileset&gt;
 *    &lt;/hlm:diff&gt;
 * &lt;/hlm:scm&gt;
 * </pre>
 *
 * @ant.type name="diff" category="SCM"
 */
public class DiffAction extends BaseDirectoryScmAction {
    private String startVersion;
    private String endVersion;

    public String getStartVersion() {
        return startVersion;
    }

    public void setStartVersion(String startVersion) {
        this.startVersion = startVersion;
    }

    public String getEndVersion() {
        return endVersion;
    }

    public void setEndVersion(String endVersion) {
        this.endVersion = endVersion;
    }

    @Override
    public void execute(ScmRepository repository) throws ScmException {

        ScmManager scmManager = getTask().getScmManager();
        DiffScmResult result;

        try {
            result = scmManager.diff(repository, getScmFileSet(),
                    new ScmRevision(startVersion), new ScmRevision(endVersion));
        } catch (ScmException e) {
            throw new BuildException("SCM diff action failed." + e.getMessage());
        }

        if (!result.isSuccess()) {
            throw new BuildException("SCM diff action failed."
                    + result.getProviderMessage());
        }

        // Output diff information
        log(result.getPatch());
    }
}
