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


/**
 * ANT wrapper task for the GSCM deconfigure.pl script.
 * 
 * @ant.task category="SCM"
 */
public class DeconfigureTask extends AbstractScmBaseTask {
  // The attributes of this task
  private Boolean considerBranchReleases;

  /**
   * Return the considerBranchReleases.
   * 
   * @return the considerBranchReleases.
   */
  public Boolean getConsiderBranchReleases() {
    return considerBranchReleases;
  }

  /**
   * Set if we want deconfigure.pl script to check for branch differences
   * based on the 'included_releases' attribute of project.
   * 
   * @param considerBranchReleases
   * @ant.not-required Default is no.
   */
  public void setconsiderBranchReleases(Boolean considerBranchReleases) {
    this.considerBranchReleases = considerBranchReleases;
    log("Set considerBranchReleases to " + considerBranchReleases);
  }

  /**
   * Build a command list consisting of all the required and optional command
   * arguments of the current task.
   */
  protected void buildCommandList() {
    addCommandArg("database", "-d", true, getDatabase());
    addCommandArg("password", "-P", true, getPassword());
    addCommandArg("ccmProject", "-p", true, getCcmProject());
    addCommandArg("considerBranchReleases", "-b", getConsiderBranchReleases());
  }

  /**
   * Method validates the given arguments.
   */
  protected void validateArguments() {
    // Do nothing
  }

  /**
   * Set the execution script.
   * 
   */
  protected void setExecutionScript() {
    append2CommandString("deconfigure.pl");
  }

  /**
   * Method returns the correct verbosity level for the input choice.
   * 
   * @param choice
   *            is the verbosity choice set by user.
   * @return the verbosity level to set.
   */
  protected String getVerbosity(int choice) {
    String cmd = "";
    switch (choice) {
    case 0:
      cmd = "-q ";
      break;
    case 1:
      cmd = "-V ";
      break;
    case 2:
      cmd = "-W ";
      break;
    default:
      raiseError("Verbosity level is not recognised. "
          + "Legal values are: 0 - quiet, 1 - verbose or 2 - very verbose");
    }
    return cmd;
  }
  
}