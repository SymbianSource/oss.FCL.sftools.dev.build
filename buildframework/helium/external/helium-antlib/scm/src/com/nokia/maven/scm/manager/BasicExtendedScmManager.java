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

import org.apache.maven.scm.CommandParameters;
import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.manager.BasicScmManager;
import org.apache.maven.scm.repository.ScmRepository;

import com.nokia.maven.scm.command.pull.PullScmResult;
import com.nokia.maven.scm.command.tags.TagsScmResult;
import com.nokia.maven.scm.command.info.InfoScmResult;
import com.nokia.maven.scm.provider.ScmProviderExt;

/**
 * Extended SCM manager which implements the additional functionalities
 * defined by the ExtendedScmManager.
 *
 */
public class BasicExtendedScmManager extends BasicScmManager implements
        ExtendedScmManager {

    /**
     * {@inheritDoc}
     */
    @Override
    public PullScmResult pull(ScmRepository repository, File path)
            throws ScmException {
        try {
            ScmProviderExt provider = (ScmProviderExt) this
                    .getProviderByRepository(repository);
            return provider.pull(repository, path);
        } catch (ClassCastException exc) {
            throw new ScmException("The " + repository.getProvider().toString()
                    + " does not support extended functionalities.");
        }
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public TagsScmResult tags(ScmRepository repository, File path) throws ScmException {
        try {
            ScmProviderExt provider = (ScmProviderExt) this
                    .getProviderByRepository(repository);
            return provider.tags(repository, new ScmFileSet(path), new CommandParameters());
        } catch (ClassCastException exc) {
            throw new ScmException("The " + repository.getProvider().toString()
                    + " does not support extended functionalities.");
        }
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public InfoScmResult info(ScmRepository repository, File path) throws ScmException {
        try {
            ScmProviderExt provider = (ScmProviderExt) this
                    .getProviderByRepository(repository);
            return provider.info(repository, new ScmFileSet(path), new CommandParameters());
        } catch (ClassCastException exc) {
            throw new ScmException("The " + repository.getProvider().toString()
                    + " does not support extended functionalities.");
        }
    }

}
