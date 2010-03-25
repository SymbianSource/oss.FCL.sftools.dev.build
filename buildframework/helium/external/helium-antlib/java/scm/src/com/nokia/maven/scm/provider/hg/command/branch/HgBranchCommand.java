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

package com.nokia.maven.scm.provider.hg.command.branch;

import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.ScmResult;
import org.apache.maven.scm.command.branch.AbstractBranchCommand;
import org.apache.maven.scm.command.branch.BranchScmResult;
import org.apache.maven.scm.provider.ScmProviderRepository;
import org.apache.maven.scm.provider.hg.HgUtils;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

/**
 * Branch command to create a new branch
 */
public class HgBranchCommand
    extends AbstractBranchCommand    
{
    /** {@inheritDoc} */
    protected ScmResult executeBranchCommand( ScmProviderRepository repository, ScmFileSet fileSet, String name, String message )
        throws ScmException
    {
        // Create command
        File workingDir = fileSet.getBasedir();
        List<String> branchCmd = new ArrayList<String>();
        
        //branch command
        branchCmd.add("branch");
        branchCmd.add(name);
        
        ScmResult branchResult = HgUtils.execute(workingDir, branchCmd.toArray(new String[branchCmd.size()]));

        return new BranchScmResult(branchResult.getCommandLine(),
                    branchResult.getProviderMessage(), branchResult
                            .getCommandOutput(), branchResult.isSuccess());
    }
}
