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

import org.apache.maven.scm.provider.hg.command.HgConsumer;
import org.apache.maven.scm.log.ScmLogger;
import org.apache.maven.scm.ScmFileStatus;

/**
 * Consumer of 'hg info' command output.
 */
public class HgInfoConsumer
    extends HgConsumer
{
    private String scmRevision = new String();
    public HgInfoConsumer( ScmLogger logger )
    {
        super( logger );
    }

    /** {@inheritDoc} */
    public void doConsume( ScmFileStatus status, String trimmedLine )
    {
        String[] tagging = trimmedLine.split(" ");
        if (tagging.length == 2) {
            this.scmRevision = tagging[0];            
            }
    }
    
    public String getRevision()
    {
        return scmRevision;
    }
}
