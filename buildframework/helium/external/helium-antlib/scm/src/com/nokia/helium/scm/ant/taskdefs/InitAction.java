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
import org.apache.maven.scm.manager.ScmManager;
import org.apache.maven.scm.provider.ScmProvider;
import org.apache.maven.scm.repository.ScmRepository;

import com.nokia.maven.scm.provider.ScmProviderExt;

public class InitAction extends BaseDirectoryScmAction {
    @Override
    public void execute(ScmRepository repository) throws ScmException {
        ScmManager scmManager = getTask().getScmManager();
        ScmProvider provider = scmManager.getProviderByUrl(getTask().getScmUrl());

        getTask().log("InitAction: " + repository);
        ScmProviderExt providerExt = (ScmProviderExt) provider;
        providerExt.init(repository);
    }
}
