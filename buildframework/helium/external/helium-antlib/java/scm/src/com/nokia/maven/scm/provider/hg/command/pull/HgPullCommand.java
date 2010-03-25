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


package com.nokia.maven.scm.provider.hg.command.pull;

import java.io.File;

import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.ScmResult;
import org.apache.maven.scm.ScmVersion;
import org.apache.maven.scm.provider.ScmProviderRepository;
import org.apache.maven.scm.provider.hg.HgUtils;
import org.apache.maven.scm.provider.hg.command.HgCommandConstants;
import org.apache.maven.scm.provider.hg.command.HgConsumer;

import com.nokia.maven.scm.command.pull.AbstractPullCommand;
import com.nokia.maven.scm.command.pull.PullScmResult;

/**
 * 'hg pull' command.
 */
public class HgPullCommand extends AbstractPullCommand
{

    @Override
    protected PullScmResult executePullCommand(ScmProviderRepository repository,
            ScmFileSet fileSet, ScmVersion scmVersion) throws ScmException {

        File workingDir = fileSet.getBasedir();

        // Update branch
        String[] updateCmd = new String[] {
            HgCommandConstants.PULL_CMD,
        };
        ScmResult pullResult = HgUtils.execute( new HgConsumer( getLogger() ), getLogger(), workingDir, updateCmd );

        if ( !pullResult.isSuccess() )
        {
            return new PullScmResult(pullResult.getCommandLine(), pullResult.getProviderMessage(), pullResult.getCommandOutput(), pullResult.isSuccess() );
        }
        
        this.getLogger().info(pullResult.getCommandOutput());
        return new PullScmResult(pullResult.getCommandLine(), pullResult.getProviderMessage(), pullResult.getCommandOutput(), pullResult.isSuccess() );
    }
}


