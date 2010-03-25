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


package com.nokia.maven.scm.provider.hg.command.tags;

import java.io.File;

import org.apache.maven.scm.CommandParameters;
import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.ScmResult;
import org.apache.maven.scm.provider.ScmProviderRepository;
import org.apache.maven.scm.provider.hg.HgUtils;

import com.nokia.maven.scm.command.tags.AbstractTagsCommand;
import com.nokia.maven.scm.command.tags.TagsScmResult;

/**
 * 'hg tags' command.
 */
public class HgTagsCommand extends AbstractTagsCommand
{

    @Override
    protected TagsScmResult executeTagsCommand(ScmProviderRepository repository, ScmFileSet fileSet, CommandParameters parameters) throws ScmException {

        File workingDir = fileSet.getBasedir();
        // Update branch
        String[] updateCmd = new String[] {
            "tags",
        };
        HgTagsConsumer consumer = new HgTagsConsumer( getLogger() );
        ScmResult tagsResult = HgUtils.execute(consumer , getLogger(), workingDir, updateCmd );

        if ( !tagsResult.isSuccess() )
        {
            return new TagsScmResult(tagsResult.getCommandLine(), tagsResult.getProviderMessage(), tagsResult.getCommandOutput(), tagsResult.isSuccess() );
        }
        
        this.getLogger().info(tagsResult.getCommandOutput());
        return new TagsScmResult(tagsResult.getCommandLine(), tagsResult.getProviderMessage(), tagsResult.getCommandOutput(), tagsResult.isSuccess(), consumer.getTags());
    }
}


