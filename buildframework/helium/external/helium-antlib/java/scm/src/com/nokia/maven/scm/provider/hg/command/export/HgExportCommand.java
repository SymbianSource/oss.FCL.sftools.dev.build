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


package com.nokia.maven.scm.provider.hg.command.export;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.ScmResult;
import org.apache.maven.scm.ScmVersion;
import org.apache.maven.scm.command.export.AbstractExportCommand;
import org.apache.maven.scm.command.export.ExportScmResult;
import org.apache.maven.scm.provider.ScmProviderRepository;
import org.apache.maven.scm.provider.hg.HgUtils;

/**
 * Implements the export command base on the Mercurial archiving functionality.
 *
 */
public class HgExportCommand extends AbstractExportCommand {
    @Override
    protected ExportScmResult executeExportCommand(
            ScmProviderRepository repository, ScmFileSet fileSet,
            ScmVersion version, String outputDir) throws ScmException {
        File workingDir = fileSet.getBasedir();
        File outputDirFile = new File(outputDir);
        if (!outputDirFile.isDirectory()) {
            throw new ScmException("Could not find directory: " + outputDirFile);
        }
        if (outputDirFile.list().length > 0) {
            throw new ScmException("Output directory must be empty.");
        }

        // Create command
        List<String> exportCmd = new ArrayList<String>();
        exportCmd.add("archive");
        exportCmd.add("--no-decode");
        exportCmd.add("-t");
        exportCmd.add("files");

        // Which revision
        exportCmd.add("-r");
        exportCmd.add((version != null) ? version.getName() : "tip");

        // Target dir
        exportCmd.add(outputDirFile.getAbsolutePath());

        getLogger().debug(
                "hg:export:workingDir: " + workingDir.getAbsolutePath());
        getLogger().debug(
                "hg:export:outputDir: " + outputDirFile.getAbsolutePath());
        ScmResult exportResult = HgUtils.execute(workingDir, exportCmd
                .toArray(new String[exportCmd.size()]));

        if (!exportResult.isSuccess()) {
            return new ExportScmResult(exportResult.getCommandLine(),
                    exportResult.getProviderMessage(), exportResult
                            .getCommandOutput(), exportResult.isSuccess());
        }

        return new ExportScmResult(exportResult.getCommandLine(),
                getFiles(outputDirFile));
    }

    protected List<String> getFiles(File dir) {
        List<String> files = new ArrayList<String>();
        for (File f : dir.listFiles()) {
            if (f.isFile()) {
                files.add(f.getAbsolutePath());
            } else if (f.isDirectory()) {
                files.addAll(getFiles(f));
            }
        }
        return files;
    }
}
