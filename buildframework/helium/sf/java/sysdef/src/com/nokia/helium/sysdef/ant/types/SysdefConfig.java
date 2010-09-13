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
package com.nokia.helium.sysdef.ant.types;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.ProjectComponent;
import org.apache.tools.ant.taskdefs.ExecTask;

import com.nokia.helium.core.FileUtils;
import com.nokia.helium.sysdef.ant.taskdefs.FilterTask;
import com.nokia.helium.sysdef.ant.taskdefs.SysdefUtils;

/**
 * This type configure the Feature based filtering, by accepting 
 * a HRH file parameter and a set of include path as input. 
 *
 */
public class SysdefConfig extends ProjectComponent implements Filter {
    private File file;
    private String includes;
  
    /**
     * The configuration file. (e.g bldvariant.hrh)
     * @param file
     * @ant.required
     */
    public void setFile(File file) {
        this.file = file;
    }
        
    /**
     * Set a list of include path separated by current os separator character (; or :)
     * @param includes
     * @ant.not-required
     */
    public void setIncludes(String includes) {
        this.includes = includes;
    }
    
    /**
     * Get the list of include path as a list of File objet.
     * Include will be considered as relative to basedir if they
     * are not absolute.
     * @return a list of directories.
     */
    protected List<File> getIncludes() {
        List<File> includeFiles = new ArrayList<File>();
        if (includes != null) {
            for (String include : includes.split(File.pathSeparator)) {
                includeFiles.add(getProject().resolveFile(include));
            }
        }
        return includeFiles;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void filter(FilterTask task, File src, File dest) {
        String[] pathDirs = {SysdefUtils.getSysdefHome(task.getProject(), task.getEpocroot()).toString()};
        File script = FileUtils.findExecutableOnPath("joinsysdef", pathDirs);
        if (script == null) {
            throw new BuildException("Could not find the joinsysdef tool.");           
        }
        ExecTask exec = new ExecTask();
        exec.bindToOwner(task);
        exec.setDir(task.getEpocroot());
        exec.setExecutable(script.toString());
        exec.createArg().setValue("-config");
        exec.createArg().setFile(file);
        exec.createArg().setValue("-output");
        exec.createArg().setFile(dest);
        for (File include : getIncludes()) {
            exec.createArg().setValue("-I" + include.toString());            
        }
        exec.createArg().setFile(src);
        exec.execute();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void validate() {
        if (file == null) {
            throw new BuildException("'file' attribute is not defined.");
        }
        if (!file.exists()) {
            throw new BuildException("Could not find file: " + file.getAbsolutePath());
        }
    }
    
}
