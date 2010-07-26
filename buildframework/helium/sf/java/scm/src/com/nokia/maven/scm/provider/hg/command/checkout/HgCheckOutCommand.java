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


package com.nokia.maven.scm.provider.hg.command.checkout;

import org.apache.maven.scm.provider.ScmProviderRepository;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.command.checkout.CheckOutScmResult;
import org.apache.maven.scm.ScmResult;
import org.apache.maven.scm.ScmVersion;
import org.apache.maven.scm.ScmException;

/**
 */
public class HgCheckOutCommand
    extends org.apache.maven.scm.provider.hg.command.checkout.HgCheckOutCommand
{
    /** {@inheritDoc} */
    protected CheckOutScmResult executeCheckOutCommand( ScmProviderRepository repo, ScmFileSet fileSet,
                                                        ScmVersion scmVersion )
        throws ScmException
    {
           CheckOutScmResult result = super.executeCheckOutCommand(repo, fileSet, scmVersion);
           if (result.getCheckedOutFiles().size() == 0 && !result.isSuccess() && result.getProviderMessage().contains("locate failed with exit code: 1.")) {
               getLogger().info("Fixing locate calls which returns 1 when no files are found.");
               result = new CheckOutScmResult(result.getCheckedOutFiles(), new ScmResult(result.getCommandLine(), result.getProviderMessage(), result.getCommandOutput(), true));
           }
           return result;
    }
       
}
