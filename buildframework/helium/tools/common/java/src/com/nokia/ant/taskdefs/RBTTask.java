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
 * ANT wrapper task for the GSCM rbt.pl script.
 * 
 * <pre>
 * Deconfigure Only:
 * 
 * Usage: &lt;hlm:rebaseanddeconf database=&quot;${dbname}&quot;
 *                              password=&quot;${UNIX-password}&quot; 
 *                              verbosity=&quot;${0-3}&quot;
 *                              ccmProject=&quot;${ccm.project.name}&quot; 
 *                              release=&quot;${release.name}&quot;
 *                              deconfigure=&quot;yes&quot; /&gt;
 * </pre>
 * 
 * <pre>
 * Rebaseline Only:
 * 
 * Usage:   &lt;hlm:rebaseanddeconf database=&quot;${dbname}&quot;
 *                              password=&quot;${UNIX-password}&quot; 
 *                              verbosity=&quot;${0-3}&quot;
 *                              ccmProject=&quot;${ccm.project.name}&quot;
 *                              release=&quot;${release.name}&quot; 
 *                              releaseBaseline=&quot;yes&quot; 
 *                              skipDeconfigure=&quot;yes&quot; /&gt;
 * </pre>
 * 
 * <pre>
 * Rebaseline with deconfigure:
 * 
 * Usage:   &lt;hlm:rebaseanddeconf database=&quot;${dbname}&quot;
 *                              password=&quot;${UNIX-password}&quot; 
 *                              verbosity=&quot;${0-3}&quot;
 *                              ccmProject=&quot;${ccm.project.name}&quot;
 *                              release=&quot;${release.name}&quot; 
 *                              releaseBaseline=&quot;yes&quot; 
 *                              deconfigure=&quot;yes&quot; /&gt;
 * </pre>
 * 
 * @ant.task category="SCM"
 */
public class RBTTask extends AbstractScmBaseTask {

  // The attributes of this task
  private String baseline; // -B baselinename = Four-part name of existing
  // baseline (incompatible with -p and -n)
  private String version; // -v version = New project hierarchy version
  private String release; // -r release = New release object name (Two-part
  // name)
  private String newBaselineName; // -n name = New baseline name

  private Boolean releaseBaseline; // -R = Release the newly created baseline
  private Boolean publish; // -P = Publish the newly created baseline
  private Boolean deconfigure; // -s = Replace subprojects only (NO
  // REBASELINE)
  private Boolean leaveFoldersWritable; // -F = Don't freeze folders (Leave
  // folders writable)
  private Boolean enableTaskRebadgingGenericRelease; // -t = Enable task
  // rebadging (associated
  // modifiable tasks with
  // generic release only)
  private Boolean enableTaskRebadging; // -T = Enable task rebadging (all
  // associated modifiable tasks)
  private Boolean rebadgeObjectVersions; // -o = Rebadge object versions
  // (requires ccm_admin)
  private Boolean createBaselineForRollingReleaseTag; // -i = Create
  // additional
  // integration baseline
  // for rolling-release
  // tag
  private Boolean skipDeconfigure; // -S = Do NOT replace subprojects (NO
  // DECONFIGURE)
  private Boolean active; // -a = Specified release remains active
  private Boolean useBranchReleaseMethodology; // -b = Utilize branch release

  // methodology

  /**
   * Return the baseline.
   * 
   * @return the baseline.
   */
  public String getBaseline() {
    return baseline;
  }

  /**
   * Set four-part name of existing baseline (incompatible with 'projectName'
   * and 'baselineName' attributes) to be used by rebaseline.pl script.
   * 
   * @param baseline
   *            is the baseline to set
   * @ant.not-required
   */
  public void setBaseline(String baseline) {
    this.baseline = baseline;
    log("Set baseline to " + baseline);
  }

  /**
   * Return the version.
   * 
   * @return the version.
   */
  public String getVersion() {
    return version;
  }

  /**
   * Set version of new project created.
   * 
   * @param version
   *            is the version to set.
   * @ant.not-required
   */
  public void setVersion(String version) {
    this.version = version;
    log("Set version to " + version);
  }

  /**
   * Return the leaveFoldersWritable.
   * 
   * @return the leaveFoldersWritable.
   */
  public Boolean getLeaveFoldersWritable() {
    return leaveFoldersWritable;
  }

  /**
   * Set whether to leave the folders writable in the baseline project
   * created.
   * 
   * @param leaveFoldersWritable
   *            indicates whether to leave folders writable.
   * @ant.not-required Default is no.
   */
  public void setLeaveFoldersWritable(Boolean leaveFoldersWritable) {
    this.leaveFoldersWritable = leaveFoldersWritable;
    log("Set leaveFoldersWritable to " + leaveFoldersWritable);
  }

  /**
   * Return the rebadgeObjectVersions
   * 
   * @return the rebadgeObjectVersions.
   */
  public Boolean getRebadgeObjectVersions() {
    return rebadgeObjectVersions;
  }

  /**
   * Set whether to rebadge object versions in the rebaseline.pl script.
   * 
   * @param rebadgeObjectVersions
   *            indicates whether to rebadge object versions to a given release tag.
   * @ant.not-required Default is no.
   */
  public void setRebadgeObjectVersions(Boolean rebadgeObjectVersions) {
    this.rebadgeObjectVersions = rebadgeObjectVersions;
    log("Set rebadgeObjectVersions to " + rebadgeObjectVersions);
  }

  /**
   * Return the releaseBaseline.
   * 
   * @return the releaseBaseline.
   */
  public Boolean getReleaseBaseline() {
    return releaseBaseline;
  }

  /**
   * Set whether to release the newly created baseline or not.
   * 
   * @param releaseBaseline
   *            indicates whether to release the newly created baseline 
   */
  public void setReleaseBaseline(Boolean releaseBaseline) {
    this.releaseBaseline = releaseBaseline;
    log("Set releaseBaseline to " + releaseBaseline);
  }

  /**
   * Return the publish.
   * 
   * @return the publish.
   */
  public Boolean getPublish() {
    return publish;
  }

  /**
   * Set whether to publish the newly created baseline or not.
   * 
   * @param publish
   *            the publish to set
   */
  public void setPublish(Boolean publish) {
    this.publish = publish;
    log("Set publish to " + publish);
  }

  /**
   * Return the createBaselineForRollingReleaseTag.
   * 
   * @return the createBaselineForRollingReleaseTag.
   */
  public Boolean getCreateBaselineForRollingReleaseTag() {
    return createBaselineForRollingReleaseTag;
  }

  /**
   * Set whether to create additional integration baseline for rolling-release
   * tag.
   * 
   * @param createBaselineForRollingReleaseTag
   * @ant.not-required Default is no.
   */
  public void setCreateBaselineForRollingReleaseTag(
      Boolean createBaselineForRollingReleaseTag) {
    this.createBaselineForRollingReleaseTag = createBaselineForRollingReleaseTag;
    log("Set createBaselineForRollingReleaseTag to "
        + createBaselineForRollingReleaseTag);
  }

  /**
   * Return the enableTaskRebadgingGenericRelease.
   * 
   * @return the enableTaskRebadgingGenericRelease.
   */
  public Boolean getEnableTaskRebadgingGenericRelease() {
    return enableTaskRebadgingGenericRelease;
  }

  /**
   * Set enable task rebadging (associated modifiable tasks with generic
   * release only). Not supported in rebaseline.pl
   * 
   * @param enableTaskRebadgingGenericRelease
   *            the enableTaskRebadgingGenericRelease to set
   */
  public void setEnableTaskRebadgingGenericRelease(
      Boolean enableTaskRebadgingGenericRelease) {
    this.enableTaskRebadgingGenericRelease = enableTaskRebadgingGenericRelease;
    log("Set enableTaskRebadgingGenericRelease to "
        + enableTaskRebadgingGenericRelease);
  }

  /**
   * Return the enableTaskRebadging
   * 
   * @return the enableTaskRebadging.
   */
  public Boolean getEnableTaskRebadging() {
    return enableTaskRebadging;
  }

  /**
   * Set enable task rebadging (all associated modifiable tasks). Not supported in rebaseline.pl
   * 
   * @param enableTaskRebadging
   *            the enableTaskRebadging to set
   */
  public void setEnableTaskRebadging(Boolean enableTaskRebadging) {
    this.enableTaskRebadging = enableTaskRebadging;
    log("Set enableTaskRebadging to " + enableTaskRebadging);
  }

  /**
   * Return the skipDeconfigure.
   * 
   * @return the skipDeconfigure.
   */
  public Boolean getSkipDeconfigure() {
    return skipDeconfigure;
  }

  /**
   * Set to skip deconfigure.
   * 
   * @param skipDeconfigure
   *            the skipDeconfigure to set
   */
  public void setSkipDeconfigure(Boolean skipDeconfigure) {
    this.skipDeconfigure = skipDeconfigure;
    log("Set skipDeconfigure to " + skipDeconfigure);
  }

  /**
   * Return the deconfigure
   * 
   * @return the deconfigure.
   */
  public Boolean getDeconfigure() {
    return deconfigure;
  }

  /**
   * Set deconfigure.
   * 
   * @param deconfigure
   *            the deconfigure to set
   */
  public void setDeconfigure(Boolean deconfigure) {
    this.deconfigure = deconfigure;
    log("Set deconfigure to " + deconfigure);
  }

  /**
   * Return the active.
   * 
   * @return the active.
   */
  public Boolean getActive() {
    return active;
  }

  /**
   * Set whether the current release is active or not.
   * 
   * @param active
   *            the active to set
   */
  public void setActive(Boolean active) {
    this.active = active;
    log("Set active to " + active);
  }

  /**
   * Return useBranchReleaseMethodology.
   * 
   * @return the useBranchReleaseMethodology.
   */
  public Boolean getUseBranchReleaseMethodology() {
    return useBranchReleaseMethodology;
  }

  /**
   * Set whether to utilize branch release methodology or not.
   * 
   * @param useBranchReleaseMethodology
   *            is the boolean value to set.
   * @ant.not-required Default is no.
   */
  public void setUseBranchReleaseMethodology(
      Boolean useBranchReleaseMethodology) {
    this.useBranchReleaseMethodology = useBranchReleaseMethodology;
    log("Set useBranchReleaseMethodology to " + useBranchReleaseMethodology);
  }

  /**
   * Return the release tag.
   * 
   * @return the release tag.
   */
  public String getRelease() {
    return release;
  }

  /**
   * Set release tag (Two-part name) for the release project created.
   * 
   * @param release
   *            is the release tag to set
   * @ant.not-required
   */
  public void setRelease(String release) {
    this.release = release;
    log("Set release to " + release);
  }

  /**
   * Return the newBaselineName.
   * 
   * @return the newBaselineName.
   */
  public String getNewBaselineName() {
    return newBaselineName;
  }

  /**
   * Set new baseline name to use.
   * 
   * @param newBaselineName
   *            is the new baseline name to set.
   * @ant.not-required
   */
  public void setNewBaselineName(String newBaselineName) {
    this.newBaselineName = newBaselineName;
    log("Set newBaselineName to " + newBaselineName);
  }

  /**
   * Set the execution script.
   * 
   */
  protected void setExecutionScript() {
    append2CommandString("rbt.pl");
  }

  /**
   * Build a command list consisting of all the required and optional command
   * arguments of the current task.
   */
  protected void buildCommandList() {
    addCommandArg("database", "-d", true, getDatabase());
    addCommandArg("password", "-U", true, getPassword());
    addCommandArg("ccmProject", "-p", getCcmProject());
    addCommandArg("baseline", "-B", getBaseline());
    addCommandArg("version", "-v", getVersion());
    addCommandArg("releaseBaseline", "-R", getReleaseBaseline());
    addCommandArg("publish", "-P", getPublish());
    addCommandArg("deconfigure", "-s", getDeconfigure());
    addCommandArg("leaveFoldersWritable", "-F", getLeaveFoldersWritable());
    addCommandArg("enableTaskRebadgingGenericRelease", "-t", getEnableTaskRebadgingGenericRelease());
    addCommandArg("enableTaskRebadging", "-T", getEnableTaskRebadging());
    addCommandArg("rebadgeObjectVersions", "-o", getRebadgeObjectVersions());
    addCommandArg("createBaselineForRollingReleaseTag", "-i", getCreateBaselineForRollingReleaseTag());
    addCommandArg("active", "-a", getActive());
    addCommandArg("skipDeconfigure", "-S", getSkipDeconfigure());
    addCommandArg("useBranchReleaseMethodology", "-b", getUseBranchReleaseMethodology());
    addCommandArg("release", "-r", getRelease());
    addCommandArg("newBaselineName", "-n", getNewBaselineName());
  }

  /**
   * Method validates the given arguments.
   */
  protected void validateArguments() {

    if (baseline != null && (getCcmProject() != null || newBaselineName != null)) {
      raiseError("Option 'baseline' cannot be used with 'ccmProject' and 'newBaselineName'");
    }

    if (deconfigure != null && deconfigure && skipDeconfigure != null
        && skipDeconfigure) {
      raiseError("Use option either 'deconfigure' or 'skipDeconfigure'");
    }

    if (deconfigure != null && deconfigure && release == null) {
      raiseError("Option 'release' is mandatory if 'deconfigure' is set");
    }

    if (publish != null && publish && releaseBaseline != null
        && releaseBaseline) {
      raiseError("Use Option either 'publish' or 'releaseBaseline'");
    }

    if (enableTaskRebadging != null && enableTaskRebadging
        && enableTaskRebadgingGenericRelease != null
        && enableTaskRebadgingGenericRelease) {
      raiseError("Use Option either 'enableTaskRebadging' or 'enableTaskRebadgingGenericRelease'");
    }
  }

  /**
   * {@inheritDoc}
   */
  protected String getVerbosity(int choice) {
    String cmd = "";
    switch (choice) {
    case 0:
      cmd = "-Q";
      break;
    case 1:
      cmd = "-V";
      break;
    case 2:
      cmd = "-I";
      break;
    case 3:
      cmd = "-W";
      break;
    default:
      raiseError("Verbosity level is not recognised. "
          + "Legal values are: 0 - quiet, 1 - verbose, 2 - Interactive "
          + "or 3 - Walk-through Rehearsal");
    }
    return cmd;
  }

}
