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


package com.nokia.maven.scm.manager;

import java.io.File;

import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.manager.ScmManager;
import org.apache.maven.scm.repository.ScmRepository;

import com.nokia.maven.scm.command.pull.PullScmResult;
import com.nokia.maven.scm.command.tags.TagsScmResult;
import com.nokia.maven.scm.command.info.InfoScmResult;

/**
 * Extended verison of the Maven ScmManager
 */
public interface ExtendedScmManager extends ScmManager
{
    String ROLE = ExtendedScmManager.class.getName();

    /**
     * Download changes from remote repository.
     *
     * @param repository  the source control system
     * @param path     location of your local copy
     * @return
     * @throws ScmException if any
     */
    PullScmResult pull(ScmRepository repository, File path)
        throws ScmException;

    /**
     * Get the tag list.
     *
     * @param repository  the source control system
     * @param path     location of your local copy
     * @return
     * @throws ScmException if any
     */
    TagsScmResult tags(ScmRepository repository, File path)
        throws ScmException;

    /**
     * Get the global revision number for the repository.
     *
     * @param repository  the source control system
     * @param path     location of your local copy
     * @return
     * @throws ScmException if any
     */
    InfoScmResult info(ScmRepository repository, File path)
        throws ScmException;
}
