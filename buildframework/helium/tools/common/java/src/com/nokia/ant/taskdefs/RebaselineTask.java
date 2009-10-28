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
 * ANT wrapper task for the GSCM rebaseline.pl script.
 * @ant.task category="SCM"
 */
public class RebaselineTask extends Task
{
    // The attributes of this task
    private String database;
    private String projectName;
    private String password;
    private String release;   
    private String baseline;
    private String version;
    private Boolean releaseBaseline;
    private Boolean leaveFolderswritable;   
    private Boolean disableTaskRebadging;   
    private Boolean rebadgeObjectVersions;
    private String baselineName;
    private Boolean useBranchReleaseMethodology;
    private Boolean createBaselineForRollingReleaseTag;
    private Integer verbosity;

    /**
     * Set Synergy Database name to be used by rebaseline.pl script.
     * @param database
     * @ant.required
     */
    public void setdatabase(String database) {
        this.database = database;
        log("Set database to " + database, Project.MSG_DEBUG); 
    }

    /**
     * Set Synergy Project Name to be used by rebaseline.pl script.
     * @param projectName
     * @ant.required
     */
    public void setprojectName(String projectName) {
        this.projectName = projectName;
        log("Set projectName to " + projectName, Project.MSG_DEBUG); 
    }

    /**
     * Set Synergy Password to be used by rebaseline.pl script.
     * @param password
     * @ant.required
     */    
    public void setpassword(String password) {
        this.password = password;
        log("Set password to " + password, Project.MSG_DEBUG);
    }

    /**
     * Set release tag (Two-part name) for the release project created by reconfigure.pl script.
     * @param release
     * @ant.not-required
     */    
    public void setrelease(String release) {
        this.release = release;
        log("Set release to " + release, Project.MSG_DEBUG);
    }

    /**
     * Set four-part name of existing baseline (incompatible with 'projectName' and 'baselineName' attributes) to be used by rebaseline.pl script.
     * @param baseline 
     * @ant.not-required
     */    
    public void setbaseline(String baseline) {
        this.baseline = baseline;
        log("Set baseline to " + baseline, Project.MSG_DEBUG);
    }

    /**
     * Set version of new project created by rebaseline.pl script.
     * @param version
     * @ant.not-required
     */    
    public void setversion(String version) {
        this.version = version;
        log("Set version to " + version, Project.MSG_DEBUG);
    }

    /**
     * Set whether to release the baseline project created by rebaseline.pl script.
     * @param releaseBaseline
     * @ant.not-required Default is no.
     */    
    public void setreleaseBaseline(Boolean releaseBaseline) {
        this.releaseBaseline = releaseBaseline;
        log("Set releaseBaseline to " + releaseBaseline, Project.MSG_DEBUG);
    }

    /**
     * Set whether to leave the folders writable in the baseline project created by rebaseline.pl script.
     * @param leaveFolderswritable
     * @ant.not-required  Default is no.
     */    
    public void setleaveFolderswritable(Boolean leaveFolderswritable) {
        this.leaveFolderswritable = leaveFolderswritable;
        log("Set leaveFolderswritable to " + leaveFolderswritable, Project.MSG_DEBUG);
    }

    /**
     * Set whether to disable task rebadging (incompatible with 'rebadgeObjectVersions' attribute) in the rebaseline.pl script.
     * @param disableTaskRebadging
     * @ant.not-required  Default is no.
     */    
    public void setdisableTaskRebadging(Boolean disableTaskRebadging) {
        this.disableTaskRebadging = disableTaskRebadging;
        log("Set disableTaskRebadging to " + disableTaskRebadging, Project.MSG_DEBUG);
    }

    /**
     * Set whether to rebadge object versions in the rebaseline.pl script.
     * @param password Synergy Password
     * @ant.not-required Default is no.
     */    
    public void setrebadgeObjectVersions(Boolean rebadgeObjectVersions) {
        this.rebadgeObjectVersions = rebadgeObjectVersions;
        log("Set rebadgeObjectVersions to " + rebadgeObjectVersions, Project.MSG_DEBUG);
    }

    /**
     * Set new baseline name to use in rebaseline.pl script.
     * @param baselineName
     * @ant.not-required
     */    
    public void setbaselineName(String baselineName) {
        this.baselineName = baselineName;
        log("Set baselineName to " + baselineName, Project.MSG_DEBUG);
    }

    /**
     * Set whether to utilize branch release methodology in the rebaseline.pl script.
     * @param useBranchReleaseMethodology
     * @ant.not-required Default is no.
     */    
    public void setuseBranchReleaseMethodology(Boolean useBranchReleaseMethodology) {
        this.useBranchReleaseMethodology = useBranchReleaseMethodology;
        log("Set useBranchReleaseMethodology to " + useBranchReleaseMethodology, Project.MSG_DEBUG);
    }

    /**
     * Set whether to create additional integration baseline for rolling-release tag.
     * @param createBaselineForRollingReleaseTag
     * @ant.not-required Default is no.
     */    
    public void setcreateBaselineForRollingReleaseTag(Boolean createBaselineForRollingReleaseTag) {
        this.createBaselineForRollingReleaseTag = createBaselineForRollingReleaseTag;
        log("Set createBaselineForRollingReleaseTag to " + createBaselineForRollingReleaseTag, Project.MSG_DEBUG);
    }

   /**
     * Set verbosity level to be used by rebaseline.pl script. Verbosity level ( 0 - quiet, 1 - verbose). Exception will be raised for any other value.
     * @param verbosity 
     * @ant.not-required
     */     
    public void setverbosity(Integer verbosity) {
        this.verbosity = verbosity;
        log("Set verbosity to " + verbosity, Project.MSG_DEBUG);
    }
    
    public void execute() {
        String missingArgs = "";
        String commandArgs = "cmd /c rebaseline.pl ";

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
        if (release != null)
             commandArgs += "-r " + release + " "; 

        if (baseline != null)
             commandArgs += "-B " + baseline + " "; 

        if (version != null)
             commandArgs += "-v " + version + " "; 

        if (baselineName != null)
             commandArgs += "-n " + baselineName + " "; 

        if (releaseBaseline != null)
            if (releaseBaseline)
                commandArgs += "-R ";

        if (leaveFolderswritable != null)
            if (leaveFolderswritable)
                commandArgs += "-w ";
                
        if (disableTaskRebadging != null)
            if (disableTaskRebadging)
                commandArgs += "-x ";

        if (rebadgeObjectVersions != null)
            if (rebadgeObjectVersions)
                commandArgs += "-a ";

        if (useBranchReleaseMethodology != null)
            if (useBranchReleaseMethodology)
                commandArgs += "-b ";

        if (createBaselineForRollingReleaseTag != null)
            if (createBaselineForRollingReleaseTag)
                commandArgs += "-i ";

        if (verbosity != null)
            switch(verbosity) {
              case 0: commandArgs += "-q ";
                      break;
              case 1: commandArgs += "-V ";
                      break;
              default: throw new BuildException("[" + getTaskName() + "] Error: Verbosity level is not recognised. Legal values are: 0 - quiet, 1 - verbose.");
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