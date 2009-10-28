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

package com.nokia.ant.taskdefs;

import org.apache.tools.ant.Task;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.taskdefs.Execute;

/**
 * ANT wrapper task for the GSCM deconfigure.pl script.
 * @ant.task category="SCM"
 */
public class DeconfigureTask extends Task
{
    // The attributes of this task
    private String database;
    private String projectName;
    private String password;
    private Boolean considerBranchReleases;
    private Integer verbosity;

    /**
     * Set Synergy Database name to be used by deconfigure.pl script.
     * @param database
     * @ant.required
     */
    public void setdatabase(String database) {
        this.database = database;
        log("Set database to " + database, Project.MSG_DEBUG); 
    }

    /**
     * Set Synergy Project Name to be used by deconfigure.pl script.
     * @param projectName
     * @ant.required
     */
    public void setprojectName(String projectName) {
        this.projectName = projectName;
        log("Set projectName to " + projectName, Project.MSG_DEBUG); 
    }

    /**
     * Set Synergy Password to be used by deconfigure.pl script.
     * @param password
     * @ant.required
     */    
    public void setpassword(String password) {
        this.password = password;
        log("Set password to " + password, Project.MSG_DEBUG);
    }

    /**
     * Set if we want deconfigure.pl script to check for branch differences based on the 'included_releases' attribute of project.
     * @param considerBranchReleases 
     * @ant.not-required  Default is no.
     */    
    public void setconsiderBranchReleases(Boolean considerBranchReleases) {
        this.considerBranchReleases = considerBranchReleases;
        log("Set considerBranchReleases to " + considerBranchReleases, Project.MSG_DEBUG);
    }

   /**
     * Set verbosity level to be used by deconfigure.pl script. Verbosity level ( 0 - quiet, 1 - verbose, 2 - very verbose). Exception will be raised for any other value.
     * @param verbosity
     * @ant.not-required
     */     
    public void setverbosity(Integer verbosity) {
        this.verbosity = verbosity;
        log("Set verbosity to " + verbosity, Project.MSG_DEBUG);
    }
    
    public void execute() {
        String missingArgs = "";
        String commandArgs = "cmd /c deconfigure.pl ";

        /* Handle mandatory arguments */
        if (database == null)
            missingArgs += "database ";
        else
            commandArgs += "-d " + database + " "; 

        if (projectName == null)
            missingArgs += "projectName ";
        else
            commandArgs += "-p " + projectName + " "; 

        if (password == null)
            missingArgs += "password ";
        else
            commandArgs += "-P " + password + " "; 

        if (!missingArgs.equals(""))
            throw new BuildException("[" + getTaskName() + "] Error: mandatory attributes are not defined - " + missingArgs);

        /* Handle optional arguments */
        if (considerBranchReleases != null)
            if (considerBranchReleases)
                commandArgs += "-b ";

        if (verbosity != null)
            switch(verbosity) {
              case 0: commandArgs += "-q ";
                      break;
              case 1: commandArgs += "-V ";
                      break;
              case 2: commandArgs += "-W ";
                      break;
              default: throw new BuildException("[" + getTaskName() + "] Error: Verbosity level is not recognised. Legal values are: 0 - quiet, 1 - verbose or 2 - very verbose");
            }

        try {
            Execute exe = new Execute();
            exe.runCommand(this, commandArgs.split(" "));
        } catch (BuildException e) {
            throw new BuildException("[" + getTaskName() + "] Error: Script execution failure.");
        }
        log("Completed successfully.");
    }
}