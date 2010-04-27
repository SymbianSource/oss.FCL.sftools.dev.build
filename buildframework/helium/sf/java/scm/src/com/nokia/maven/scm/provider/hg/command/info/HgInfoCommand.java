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


package com.nokia.maven.scm.provider.hg.command.info;

import java.io.File;

import org.apache.maven.scm.CommandParameters;
import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.ScmResult;
import org.apache.maven.scm.provider.ScmProviderRepository;
import org.apache.maven.scm.provider.hg.HgUtils;
import org.apache.maven.scm.provider.hg.command.HgCommandConstants;

import com.nokia.maven.scm.command.info.AbstractInfoCommand;
import com.nokia.maven.scm.command.info.InfoScmResult;

/**
 * 'hg info' command implementation.
 */
public class HgInfoCommand extends AbstractInfoCommand
{
    @Override
    protected InfoScmResult executeInfoCommand(ScmProviderRepository repository, ScmFileSet fileSet, CommandParameters parameters) throws ScmException {

        File workingDir = fileSet.getBasedir();
        // Update branch
        String[] updateCmd = new String[] {
            HgCommandConstants.REVNO_CMD
        };
        
        HgInfoConsumer consumer = new HgInfoConsumer( getLogger() );
        
        ScmResult infoResult = HgUtils.execute(consumer , getLogger(), workingDir, updateCmd );

        if ( !infoResult.isSuccess() )
        {
            return new InfoScmResult(infoResult.getCommandLine(), infoResult.getProviderMessage(), infoResult.getCommandOutput(), infoResult.isSuccess() );
        }
        
        this.getLogger().info(infoResult.getCommandOutput());
        return new InfoScmResult(infoResult.getCommandLine(), infoResult.getProviderMessage(), infoResult.getCommandOutput(), infoResult.isSuccess(), consumer.getRevision());
        
    }
}


