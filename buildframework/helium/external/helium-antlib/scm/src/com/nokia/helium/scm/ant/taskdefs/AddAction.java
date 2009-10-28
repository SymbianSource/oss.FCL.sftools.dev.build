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
import org.apache.maven.scm.command.add.AddScmResult;
import org.apache.maven.scm.manager.ScmManager;
import org.apache.maven.scm.repository.ScmRepository;
import org.apache.tools.ant.BuildException;

/**
 * Adding a set of files into SCM control.
 *
 * <pre>
 * &lt;hlm:scm verbose="true" scmUrl="scm:${repo.type}:${repo.dir}/test1"&gt;
 *   &lt;hlm:add&gt;
 *      &lt;fileset dir="${repo.dir}/test1"&gt;
 *         &lt;include name="**" /&gt;
 *         &lt;exclude name="** /.${repo.type}/**" /&gt;
 *      &lt;/fileset&gt;
 *   &lt;/hlm:add&gt;
 * &lt;/hlm:scm&gt;
 *
 * </pre>
 * 
 * @ant.type name="add" category="SCM"
 */
public class AddAction extends BaseDirectoryScmAction {

    /**
     * {@inheritDoc}
     * @throws ScmException 
     */
    @Override
    public void execute(ScmRepository repository) throws ScmException {
        ScmManager scmManager = getTask().getScmManager();

        AddScmResult result = scmManager.add(repository, getScmFileSet());

        if (!result.isSuccess()) {
            throw new BuildException("SCM add action failed.");
        }
    }

}
