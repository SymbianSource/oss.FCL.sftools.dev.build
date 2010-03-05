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
 * ANT wrapper task for the GSCM rebaseline.pl script.
 * 
 * @ant.task category="SCM"
 */
public class RebaselineTask extends RBTTask {
  // The attributes of this task
  private Boolean disableTaskRebadging;

  /**
   * Return disableTaskRebadging
   * 
   * @return the disableTaskRebadging.
   */
  public Boolean getDisableTaskRebadging() {
    return disableTaskRebadging;
  }

  /**
   * Set whether to disable task rebadging (incompatible with
   * 'rebadgeObjectVersions' attribute) in the rebaseline.pl script.
   * 
   * @param disableTaskRebadging
   * @ant.not-required Default is no.
   */
  public void setdisableTaskRebadging(Boolean disableTaskRebadging) {
    this.disableTaskRebadging = disableTaskRebadging;
    log("Set disableTaskRebadging to " + disableTaskRebadging);
  }

  /**
   * Set the execution script.
   * 
   */
  protected void setExecutionScript() {
    append2CommandString("rebaseline.pl");
  }

  /**
   * Build a command list consisting of all the required and optional command
   * arguments of the current task.
   */
  protected void buildCommandList() {
    addCommandArg("database", "-d", true, getDatabase());
    addCommandArg("password", "-P", true, getPassword());
    addCommandArg("ccmProject", "-p", true, getCcmProject());
    addCommandArg("release", "-r", getRelease());
    addCommandArg("baseline", "-B", getBaseline());
    addCommandArg("version", "-v", getVersion());
    addCommandArg("newBaselineName", "-n", getNewBaselineName());
    addCommandArg("releaseBaseline", "-R", getReleaseBaseline());
    addCommandArg("leaveFolderswritable", "-w", getLeaveFoldersWritable());
    addCommandArg("disableTaskRebadging", "-x", getDisableTaskRebadging());
    addCommandArg("rebadgeObjectVersions", "-a", getRebadgeObjectVersions());
    addCommandArg("useBranchReleaseMethodology", "-b", getUseBranchReleaseMethodology());
    addCommandArg("createBaselineForRollingReleaseTag", "-i", getCreateBaselineForRollingReleaseTag());
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
    default:
      raiseError("Verbosity level is not recognised. "
          + "Legal values are: 0 - quiet, 1 - verbose.");
    }
    return cmd;
  }

  /**
   * Method validates the given arguments.
   */
  protected void validateArguments() {
    // Do nothing
  }
  
}