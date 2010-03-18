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

 
package com.nokia.maven.scm.command.pull;

import org.apache.maven.scm.CommandParameter;
import org.apache.maven.scm.CommandParameters;
import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.ScmResult;
import org.apache.maven.scm.ScmTag;
import org.apache.maven.scm.ScmVersion;
import org.apache.maven.scm.command.AbstractCommand;
import org.apache.maven.scm.provider.ScmProviderRepository;

/**
 * Abstract class to representing a pull command.
 * This functionality is mainly targeted for distributed 
 * repository like Git or Mercurial.  
 */
public abstract class AbstractPullCommand extends AbstractCommand
{
    
    /**
     * {@inheritDoc}
     */
    @Override
    public ScmResult executeCommand(ScmProviderRepository repository, ScmFileSet fileSet,
            CommandParameters parameters) throws ScmException
    {
        return executePullCommand(repository, fileSet, parameters.getScmVersion(CommandParameter.SCM_VERSION, new ScmTag("tip")));
    }
    
    /**
     * Implements the pull functionality.
     * @param repository the reporsitory.
     * @param fileSet
     * @param scmVersion what revision to pull.
     * @return
     * @throws ScmException
     */
    protected abstract PullScmResult executePullCommand(ScmProviderRepository repository, ScmFileSet fileSet, ScmVersion scmVersion) throws ScmException;

}
