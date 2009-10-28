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

import com.nokia.maven.scm.command.info.InfoScmResult;
import com.nokia.maven.scm.manager.ExtendedScmManager;

/**
 * This action will display the global revision id for the repository.
 *
 * <pre>
 * &lt;hlm:scm verbose="true" scmUrl="scm:${repo.type}:${repo.dir}/test1"&gt;
 *    &lt;hlm:checkout baseDir="${repo.dir}/info" /&gt;
 *    &lt;hlm:info baseDir="${repo.dir}/info"/&gt;
 * &lt;/hlm:scm&gt;
 * </pre>
 *
 * @ant.type name="info" category="SCM"
 */ 
public class InfoAction extends BaseDirectoryScmAction {

    
    @Override
    public void execute(ScmRepository repository) throws ScmException {
        InfoScmResult result;
        try {
            ExtendedScmManager scmManager = (ExtendedScmManager) getTask()
                    .getScmManager();
            result = scmManager.info(repository, new File(this.getBasedir()));
            
            if (!result.isSuccess()) {
                throw new BuildException("SCM tags action error: "
                        + result.getProviderMessage());
            }
            getTask().log(result.getRevision());
            
        } catch (ScmException e) {
            throw new BuildException("SCM info action failed: "
                    + e.getMessage());
        }

    }
}
