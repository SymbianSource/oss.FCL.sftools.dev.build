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

 
package com.nokia.maven.scm.command.info;

import org.apache.maven.scm.CommandParameters;
import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.command.AbstractCommand;
import org.apache.maven.scm.provider.ScmProviderRepository;

/**
 * The 'hg info' command.
 */
public abstract class AbstractInfoCommand extends AbstractCommand
{
    
    public InfoScmResult executeCommand(ScmProviderRepository repository, ScmFileSet fileSet,
            CommandParameters parameters) throws ScmException
    {
        return executeInfoCommand(repository, fileSet, parameters);
    }
    
    protected abstract InfoScmResult executeInfoCommand(ScmProviderRepository repository, ScmFileSet fileSetCommand, CommandParameters parameters) throws ScmException;

}
