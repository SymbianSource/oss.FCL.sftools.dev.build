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

package com.nokia.maven.scm.provider.hg.command.tag;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFile;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.ScmFileStatus;
import org.apache.maven.scm.ScmResult;
import org.apache.maven.scm.command.Command;
import org.apache.maven.scm.command.tag.AbstractTagCommand;
import org.apache.maven.scm.command.tag.TagScmResult;
import org.apache.maven.scm.provider.ScmProviderRepository;
import org.apache.maven.scm.provider.hg.HgUtils;
import org.apache.maven.scm.provider.hg.command.HgCommandConstants;
import org.apache.maven.scm.provider.hg.command.HgConsumer;
import org.apache.maven.scm.provider.hg.command.inventory.HgListConsumer;
import org.apache.maven.scm.provider.hg.command.tag.HgTagConsumer;
import org.apache.maven.scm.provider.hg.repository.HgScmProviderRepository;
import org.codehaus.plexus.util.StringUtils;

/**
 * Tag
 * 
 * @author <a href="mailto:ryan@darksleep.com">ryan daum</a>
 * @version $Id: HgTagCommand.java 686566 2008-08-16 21:52:46Z olamy $
 */
public class HgTagCommand extends AbstractTagCommand implements Command {
    /** {@inheritDoc} */
    @SuppressWarnings("unchecked")
    protected ScmResult executeTagCommand(
            ScmProviderRepository scmProviderRepository, ScmFileSet fileSet,
            String tag, String level) throws ScmException {
        if (tag == null || StringUtils.isEmpty(tag.trim())) {
            throw new ScmException("tag must be specified");
        }

        if (fileSet.getFileList().size() != 0) {
            throw new ScmException(
                    "This provider doesn't support tagging subsets of a directory");
        }

        File workingDir = fileSet.getBasedir();

        // build the command
        String[] tagCmd;
        if (level.equals(new String("local"))) {
            tagCmd = new String[] { HgCommandConstants.TAG_CMD, "--local",
                    HgCommandConstants.MESSAGE_OPTION,
                    "[maven-scm] copy for tag " + tag, tag };
        } else {
            tagCmd = new String[] { HgCommandConstants.TAG_CMD,
                    HgCommandConstants.MESSAGE_OPTION,
                    "[maven-scm] copy for tag " + tag, tag };
        }
        // keep the command about in string form for reporting
        StringBuffer cmd = joinCmd(tagCmd);

        HgTagConsumer consumer = new HgTagConsumer(getLogger());
        ScmResult result = HgUtils.execute(consumer, getLogger(), workingDir,
                tagCmd);
        HgScmProviderRepository repository = (HgScmProviderRepository) scmProviderRepository;
        if (result.isSuccess()) {
            // now push
            // Push to parent branch if any
            if (!repository.getURI().equals(
                    fileSet.getBasedir().getAbsolutePath())) {
                String[] pushCmd = new String[] { HgCommandConstants.PUSH_CMD,
                        repository.getURI() };
                result = HgUtils.execute(new HgConsumer(getLogger()),
                        getLogger(), fileSet.getBasedir(), pushCmd);
            }
        } else {
            throw new ScmException("Error while executing command "
                    + cmd.toString());
        }

        // do an inventory to return the files tagged (all of them)
        String[] listCmd = new String[] { HgCommandConstants.INVENTORY_CMD };
        HgListConsumer listconsumer = new HgListConsumer(getLogger());
        result = HgUtils.execute(listconsumer, getLogger(), fileSet
                .getBasedir(), listCmd);
        if (result.isSuccess()) {
            List<ScmFile> files = listconsumer.getFiles();
            ArrayList<ScmFile> fileList = new ArrayList<ScmFile>();
            for (ScmFile scmFile : files) {
                
                if (!scmFile.getPath().endsWith(".hgtags")) {
                    fileList
                            .add(new ScmFile(scmFile.getPath(), ScmFileStatus.TAGGED));
                }
            }

            return new TagScmResult(fileList, result);
        } else {
            throw new ScmException("Error while executing command "
                    + cmd.toString());
        }
    }

    private StringBuffer joinCmd(String[] cmds) {
        StringBuffer result = new StringBuffer();
        int i = 0;
        for (String cmd : cmds) {
            String s = cmd;
            result.append(s);
            if (i < cmds.length - 1) {
                result.append(" ");
            }
            i += 1;
        }
        return result;
    }
}
