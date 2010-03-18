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

package com.nokia.helium.ant.data.taskdefs;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.DirectoryScanner;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.FileSet;
import org.apache.tools.ant.types.ResourceCollection;
import com.nokia.helium.ant.data.Database;

/**
 * Reads the current Ant project and any additional filesets and generates a xml
 * file with a summary of targets, macros and properties.
 * 
 * @ant.task name="database"
 */
public class DatabaseTask extends Task {
    private File outputFile;
    // private boolean excludeParsedFiles
    private String scope = "public";

    private List<ResourceCollection> rcs = new ArrayList<ResourceCollection>();

    public DatabaseTask() {
        setTaskName("database");
    }

    /**
     * Add a set of files to copy.
     * 
     * @param set a set of files to copy.
     */
    public void addFileset(FileSet set) {
        add(set);
    }

    /**
     * Add a collection of files to copy.
     * 
     * @param res a resource collection to copy.
     * @since Ant 1.7
     */
    public void add(ResourceCollection res) {
        rcs.add(res);
    }

    public void setOutput(File outputFile) {
        this.outputFile = outputFile;
    }

    /**
     * Defines what level of visibility to display Ant objects at.
     * 
     * @param scope The visibility level, either public, protected or private.
     */
    public void setScope(String scope) {
        this.scope = scope;
    }

    public void execute() {
        if (outputFile == null) {
            throw new BuildException("'output' must be defined.");
        }
        log("Building Ant project database", Project.MSG_DEBUG);

        // Get additional Ant file paths
        try {
            List<String> antFilePaths = new ArrayList<String>();
            // Only filesets are supported currently
            for (ResourceCollection rc : rcs) {
                if (rc instanceof FileSet) {
                    FileSet fs = (FileSet) rc;
                    DirectoryScanner ds = fs.getDirectoryScanner(getProject());
                    String[] srcFiles = ds.getIncludedFiles();
                    String basedir = ds.getBasedir().getPath();
                    for (int i = 0; i < srcFiles.length; i++) {
                        String fileName = basedir + File.separator + srcFiles[i];
                        antFilePaths.add(fileName);
                    }
                }
            }

            // Output the database file
            Database db = new Database(getProject());
            db.setScopeFilter(scope);
            db.addAntFilePaths(antFilePaths);
            FileWriter out = new FileWriter(outputFile);
            db.toXML(out);
            out.close();
        }
        catch (IOException e) {
            e.printStackTrace();
            throw new BuildException("Not able to build the ANT project Database " + e.getMessage());
        }
    }
}
