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
import org.apache.maven.scm.command.status.StatusScmResult;
import org.apache.maven.scm.manager.ScmManager;
import org.apache.maven.scm.repository.ScmRepository;
import org.apache.tools.ant.BuildException;

/**
 * Status will execute status action on the relevant repository, and reports
 * basedir, or a specific set of file status.
 *
 * <pre>
 * &lt;hlm:scm verbose="true" scmUrl="scm:${repo.type}:${repo.dir}/test1"&gt;
 *    &lt;hlm:status&gt;
 *       &lt;fileset dir="${repo.dir}/test1"&gt;
 *          &lt;include name="**" /&gt;
 *          &lt;exclude name="** /.${repo.type}/**" /&gt;
 *       &lt;/fileset&gt;
 *    &lt;/hlm:status&gt;
 * &lt;/hlm:scm &gt;
 * </pre>
 * 
 * @ant.type name="status" category="SCM"
 */
public class StatusAction extends BaseDirectoryScmAction {

    @Override
    public void execute(ScmRepository repository) throws ScmException {
        ScmManager scmManager = getTask().getScmManager();

        StatusScmResult result = scmManager.status(repository, getScmFileSet());

        if (!result.isSuccess()) {
            throw new BuildException("SCM status action failed: "
                    + result.getProviderMessage());
        }
    }

}
