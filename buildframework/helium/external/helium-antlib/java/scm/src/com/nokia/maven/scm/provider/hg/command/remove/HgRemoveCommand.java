/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

/* Portion Copyright (c) 2007-2008 Nokia Corporation and/or its subsidiary(-ies). All rights reserved.*/

package com.nokia.maven.scm.provider.hg.command.remove;

import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.ScmResult;
import org.apache.maven.scm.command.Command;
import org.apache.maven.scm.command.remove.AbstractRemoveCommand;
import org.apache.maven.scm.command.remove.RemoveScmResult;
import org.apache.maven.scm.provider.ScmProviderRepository;
import org.apache.maven.scm.provider.hg.HgUtils;
import org.apache.maven.scm.provider.hg.command.HgCommandConstants;
import org.apache.maven.scm.provider.hg.command.remove.HgRemoveConsumer;

import java.io.File;

/**
 * Branch version of the remove command, to fix the command line generation.
 */
public class HgRemoveCommand
    extends AbstractRemoveCommand
    implements Command
{
    /** {@inheritDoc} */
    protected ScmResult executeRemoveCommand( ScmProviderRepository repository, ScmFileSet fileSet, String message )
        throws ScmException
    {

        String[] command = new String[] { HgCommandConstants.REMOVE_CMD };
        command = HgUtils.expandCommandLine( command, fileSet );

        File workingDir = fileSet.getBasedir();
        HgRemoveConsumer consumer = new HgRemoveConsumer( getLogger(), workingDir );

        ScmResult result = HgUtils.execute( consumer, getLogger(), workingDir, command );
        return new RemoveScmResult( consumer.getRemovedFiles(), result );
    }
}
