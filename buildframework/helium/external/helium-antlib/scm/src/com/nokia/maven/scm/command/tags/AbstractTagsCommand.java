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

 
package com.nokia.maven.scm.command.tags;

import org.apache.maven.scm.CommandParameters;
import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.command.AbstractCommand;
import org.apache.maven.scm.provider.ScmProviderRepository;

/**
 * Abstract class representing a tags command. 
 * Tags consist in retrieving existing tags for a particular repository.
 * 
 */
public abstract class AbstractTagsCommand extends AbstractCommand
{
    /**
     * {@inheritDoc} 
     */
    public TagsScmResult executeCommand(ScmProviderRepository repository, ScmFileSet fileSet,
            CommandParameters parameters) throws ScmException
    {
        return executeTagsCommand(repository, fileSet, parameters);
    }
    
    
    /**
     * Execute the tags operation on the repository.
     * @param repository the repository to use for the action
     * @param fileSetCommand 
     * @param parameters
     * @return a TagsScmResult representing the output of the command.
     * @throws ScmException
     */
    protected abstract TagsScmResult executeTagsCommand(ScmProviderRepository repository, ScmFileSet fileSetCommand, CommandParameters parameters) throws ScmException;

}
