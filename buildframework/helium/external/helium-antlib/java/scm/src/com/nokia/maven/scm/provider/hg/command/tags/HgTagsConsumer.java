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

import org.apache.maven.scm.provider.hg.command.HgConsumer;
import org.apache.maven.scm.log.ScmLogger;
import org.apache.maven.scm.ScmFileStatus;
import org.apache.maven.scm.ScmRevision;
import org.apache.maven.scm.ScmTag;

import java.util.Enumeration;
import java.util.Hashtable;

/**
 */
public class HgTagsConsumer
    extends HgConsumer
{

    private Hashtable<ScmTag, ScmRevision> tagMapping = new Hashtable<ScmTag, ScmRevision>();

    public HgTagsConsumer( ScmLogger logger )
    {
        super( logger );
    }

    /** {@inheritDoc} */
    public void doConsume( ScmFileStatus status, String trimmedLine )
    {
        String[] tagging = trimmedLine.split("\\s+");
        if (tagging.length == 2) {
            tagMapping.put(new ScmTag( tagging[0] ), new ScmRevision( tagging[1] ));
        }
    }

    public Enumeration<ScmTag> getTags()
    {
        return tagMapping.keys();
    }

    public Hashtable<ScmTag, ScmRevision> getMapping()
    {
        return tagMapping;
    }
}
