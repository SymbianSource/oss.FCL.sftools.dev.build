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

package com.nokia.helium.scm.ant.taskdefs;

import java.io.File;
import java.util.ArrayList;

import org.apache.maven.scm.ScmFileSet;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.DirectoryScanner;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.FileSet;

/**
 * Handles configuration of directory-based SCM task commands.
 */
public abstract class BaseDirectoryScmAction extends ScmAction {
    private String basedir;

    /**
     * Only one fileset is valid because all the SCM commands work on just one
     * Sdirectory.
     */
    private FileSet fileSet;

    /**
     * Get the basedir.
     * 
     * @return the basedir attribute as a string.
     */
    public String getBasedir() {
        if (fileSet != null) {
            return fileSet.getDir(getProject()).getAbsolutePath();
        }
        return basedir;
    }

    /**
     * Location of the current checkout in most of the case.
     * 
     * @param basedir
     *            the directory to use on the local machine
     * 
     * @ant.required
     */
    public void setBasedir(String basedir) {
        this.basedir = basedir;
    }

    public void addFileset(FileSet set) {
        fileSet = set;
    }

    public ScmFileSet getScmFileSet() {
        ArrayList<File> files = new ArrayList<File>();
        if (fileSet == null) {
            if (basedir == null) {
                throw new BuildException(
                        "Need a fileset or basedir attribute to be defined.");
            }
            return new ScmFileSet(new File(basedir));
        }
        DirectoryScanner scanner = fileSet.getDirectoryScanner(getTask()
                .getProject());
        String[] fileNames = scanner.getIncludedFiles();
        for (String fileName : fileNames) {
            log("ScmFileSet: adding " + fileName, Project.MSG_DEBUG);
            files.add(new File(fileName));
        }
        ScmFileSet scmFileSet = new ScmFileSet(fileSet.getDir(), files);
        return scmFileSet;
    }
}
