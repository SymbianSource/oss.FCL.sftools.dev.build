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

package com.nokia.maven.scm.provider.hg.command.log;


import com.nokia.maven.scm.provider.hg.VersionChangeSet;

import org.apache.maven.scm.ScmBranch;
import org.apache.maven.scm.ScmVersion;
import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.ScmResult;
import org.apache.maven.scm.command.Command;
import org.apache.maven.scm.command.changelog.AbstractChangeLogCommand;
import org.apache.maven.scm.command.changelog.ChangeLogScmResult;
import org.apache.maven.scm.command.changelog.ChangeLogSet;
import org.apache.maven.scm.provider.ScmProviderRepository;
import org.apache.maven.scm.provider.hg.HgUtils;
import org.apache.maven.scm.provider.hg.command.HgCommandConstants;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * 'hg changelog' command.
 */
public class HgChangeLogCommand
    extends AbstractChangeLogCommand
    implements Command
{
    /** {@inheritDoc} */
    @SuppressWarnings("unchecked")
    @Override
    protected ChangeLogScmResult executeChangeLogCommand( ScmProviderRepository scmProviderRepository,
                                                          ScmFileSet fileSet, Date startDate, Date endDate,
                                                          ScmBranch branch, String datePattern )
        throws ScmException
    {
        String[] cmd = new String[] { HgCommandConstants.LOG_CMD, HgCommandConstants.VERBOSE_OPTION };
        com.nokia.maven.scm.provider.hg.command.log.HgChangeLogConsumer consumer = new com.nokia.maven.scm.provider.hg.command.log.HgChangeLogConsumer( getLogger(), datePattern );
        ScmResult result = HgUtils.execute( consumer, getLogger(), fileSet.getBasedir(), cmd );

        List<VersionChangeSet> logEntries = consumer.getModifications();
        List<VersionChangeSet> inRangeAndValid = new ArrayList<VersionChangeSet>();
        startDate = startDate == null ? new Date( 0 ) : startDate; // From 1. Jan 1970
        endDate = endDate == null ? new Date() : endDate; // Upto now

        for ( VersionChangeSet logEntry : logEntries )
        {
            if ( logEntry.getFiles().size() > 0 )
            {
                if ( !logEntry.getDate().before( startDate ) && !logEntry.getDate().after( endDate ) )
                {
                    inRangeAndValid.add( logEntry );
                }
            }
        }

        ChangeLogSet changeLogSet = new ChangeLogSet( inRangeAndValid, startDate, endDate );
        return new ChangeLogScmResult( changeLogSet, result );
    }
    
    /** {@inheritDoc} */
    @SuppressWarnings("unchecked")
    @Override
    protected ChangeLogScmResult executeChangeLogCommand( ScmProviderRepository repository, ScmFileSet fileSet,
                                                      ScmVersion startVersion, ScmVersion endVersion,
                                                      String datePattern )
        throws ScmException
    {
        String param = "" + startVersion.getName() + ":" + ((endVersion.getName() != null) ? endVersion.getName() : "");
        String[] cmd = new String[] { HgCommandConstants.LOG_CMD, HgCommandConstants.VERBOSE_OPTION, HgCommandConstants.REVISION_OPTION, param};
        com.nokia.maven.scm.provider.hg.command.log.HgChangeLogConsumer consumer = new com.nokia.maven.scm.provider.hg.command.log.HgChangeLogConsumer( getLogger(), datePattern );
        ScmResult result = HgUtils.execute( consumer, getLogger(), fileSet.getBasedir(), cmd );
        List<VersionChangeSet> logEntries = consumer.getModifications();
        Date startDate = new Date( 0 ); // From 1. Jan 1970
        Date endDate = new Date(); // Upto now
        ChangeLogSet changeLogSet = new ChangeLogSet(logEntries,startDate,endDate);
        return new ChangeLogScmResult( changeLogSet, result );
    }
}
