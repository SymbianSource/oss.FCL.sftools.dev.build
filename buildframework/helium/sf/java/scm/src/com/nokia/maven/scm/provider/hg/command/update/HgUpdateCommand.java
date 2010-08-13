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

package com.nokia.maven.scm.provider.hg.command.update;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFile;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.ScmFileStatus;
import org.apache.maven.scm.ScmResult;
import org.apache.maven.scm.ScmVersion;
import org.apache.maven.scm.command.update.UpdateScmResult;
import org.apache.maven.scm.command.update.UpdateScmResultWithRevision;
import org.apache.maven.scm.provider.ScmProviderRepository;
import org.apache.maven.scm.provider.hg.HgUtils;
import org.apache.maven.scm.provider.hg.command.HgCommandConstants;
import org.apache.maven.scm.provider.hg.command.HgConsumer;
import org.apache.maven.scm.provider.hg.command.diff.HgDiffConsumer;
import org.codehaus.plexus.util.StringUtils;

import com.nokia.maven.scm.provider.hg.HgUtilsInternal;

/**
 */
public class HgUpdateCommand extends
    org.apache.maven.scm.provider.hg.command.update.HgUpdateCommand {

    /** {@inheritDoc} */
    @SuppressWarnings("unchecked")
    protected UpdateScmResult executeUpdateCommand(ScmProviderRepository repo, ScmFileSet fileSet,
        ScmVersion tag) throws ScmException {
        File workingDir = fileSet.getBasedir();

        // Find changes from last revision
        long previousRevision = HgUtilsInternal.getCurrentRevisionNumber(getLogger(), workingDir);
        // Update branch
        String[] updateCmd = new String[] { "update", HgCommandConstants.REVISION_OPTION,
            tag != null && !StringUtils.isEmpty(tag.getName()) ? tag.getName() : "tip" };
        ScmResult updateResult = HgUtils.execute(new HgConsumer(getLogger()), getLogger(), workingDir, updateCmd);

        if (!updateResult.isSuccess()) {
            return new UpdateScmResult(null, null, updateResult);
        }

        // Find changes from last revision
        long currentRevision = HgUtilsInternal.getCurrentRevisionNumber(getLogger(),
                workingDir);
                
        // No point of calculating a delta if nothing has been updated.
        getLogger().debug("Changeset before update: " + String.format("%012x", previousRevision));
        getLogger().debug("Changeset after update: " + String.format("%012x", currentRevision));
        if (previousRevision == currentRevision) {
            return new UpdateScmResultWithRevision(new ArrayList<ScmFile>(), new ArrayList(), String
                    .valueOf(currentRevision), updateResult);            
        }
        
        List<ScmFile> updatedFiles = new ArrayList<ScmFile>();
        List changes = new ArrayList();
        String[] diffCmd = null;
        if (currentRevision == 0) {
            diffCmd = new String[] { HgCommandConstants.DIFF_CMD, "-c", "" + String.format("%012x", currentRevision)};
        } else {
            diffCmd = new String[] { HgCommandConstants.DIFF_CMD,
                HgCommandConstants.REVISION_OPTION, "" + String.format("%012x", previousRevision),
                HgCommandConstants.REVISION_OPTION, "" + String.format("%012x", currentRevision)};
        }
        HgDiffConsumer diffConsumer = new HgDiffConsumer(getLogger(), workingDir);
        updateResult = HgUtils.execute(diffConsumer, getLogger(), workingDir, diffCmd);

        // Now translate between diff and update file status
        List<ScmFile> diffFiles = diffConsumer.getChangedFiles();
        Map diffChanges = diffConsumer.getDifferences();
        for (ScmFile diffFile : diffFiles) {
            changes.add(diffChanges.get(diffFile.getPath()));
            if (diffFile.getStatus() == ScmFileStatus.MODIFIED) {
                updatedFiles.add(new ScmFile(diffFile.getPath(), ScmFileStatus.PATCHED));
            } else {
                updatedFiles.add(diffFile);
            }
        }

        return new UpdateScmResultWithRevision(updatedFiles, changes, String
                .valueOf(currentRevision), new ScmResult(updateResult.getCommandLine(),
                        updateResult.getCommandOutput(), updateResult.getProviderMessage(), true));
    }

}
