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


package com.nokia.maven.scm.provider;

import java.io.File;

import org.apache.maven.scm.CommandParameters;
import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.ScmResult;
import org.apache.maven.scm.repository.ScmRepository;

import com.nokia.maven.scm.command.pull.PullScmResult;
import com.nokia.maven.scm.command.tags.TagsScmResult;
import com.nokia.maven.scm.command.info.InfoScmResult;

/**
 * This interface describe additional functionalities provider could implement 
 * compare to the default ScmProvider interface
 *  
 */
public interface ScmProviderExt {

    /**
     * Create a new repository.
     * @param repository the repository to create.
     * @return ScmResult result.
     * @throws ScmException
     */
    ScmResult init(ScmRepository repository) throws ScmException;

    /**
     * Pull changes, this function is target for distributed SCM file Hg or Git.
     * @param repository
     * @param path the location of the checkout.
     * @return a PullScmResult result object.
     * @throws ScmException
     */
    PullScmResult pull(ScmRepository repository, File path)
            throws ScmException;

    /**
     * Get a list of tags from a repository.
     * @param repository the repository
     * @param fileSet
     * @param parameters
     * @return a TagsScmResult with the list of tags if successful.
     * @throws ScmException
     */
    TagsScmResult tags(ScmRepository repository, ScmFileSet fileSet, CommandParameters parameters)
            throws ScmException;

    /**
     * Get information about current revision.
     * @param repository
     * @param fileSet
     * @param parameters
     * @return a InfoScmResult with current revision if successful.
     * @throws ScmException
     */
    InfoScmResult info(ScmRepository repository, ScmFileSet fileSet, CommandParameters parameters)
            throws ScmException;
}
