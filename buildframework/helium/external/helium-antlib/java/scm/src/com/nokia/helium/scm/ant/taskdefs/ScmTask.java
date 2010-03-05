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

import java.util.ArrayList;
import java.util.List;
import org.apache.maven.scm.manager.NoSuchScmProviderException;
import org.apache.maven.scm.manager.ScmManager;
import org.apache.maven.scm.repository.ScmRepository;
import org.apache.maven.scm.repository.ScmRepositoryException;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;

import com.nokia.maven.scm.manager.BasicExtendedScmManager;
import com.nokia.maven.scm.manager.ExtendedScmManager;
import com.nokia.maven.scm.provider.hg.HgScmProviderExt;

/**
 * This provides Ant support for a range of common SCM operations. They should work on 
 * any Maven based SCM e.g. SVN, Mercurial, synergy.  The
 * underlying SCM tool is defined by the URL format.
 *
 * <pre>
 * &lt;hlm:scm verbose="true" scmUrl="scm:hg:${pkg_detail.source}"&gt;
 *    &lt;hlm:checkout basedir="${build.drive}${pkg_detail.dst}"/&gt;
 *    &lt;hlm:tags basedir="${build.drive}${pkg_detail.dst}" reference="hg.tags.id${refid}"/&gt;
 *    &lt;hlm:update basedir="${build.drive}${pkg_detail.dst}"&gt;
 *        &lt;hlm:latestTag pattern="${pkg_detail.tag}"&gt;
 *            &lt;hlm:tagSet refid="hg.tags.id${refid}" /&gt;
 *        &lt;/hlm:latestTag&gt;
 *    &lt;/hlm:update&gt;
 * &lt;/hlm:scm&gt;
 * </pre>
 * 
 * @ant.task name="scm" category="SCM"
 */
public class ScmTask extends Task {

    private ExtendedScmManager scmManager;

    private String username;

    private String password;

    private String scmUrl;

    private String basedir;

    private List<ScmAction> actions = new ArrayList<ScmAction>();

    private boolean verbose;
    
    private boolean failonerror = true;
    

    public ScmTask() {
        setTaskName("scm");

        scmManager = new BasicExtendedScmManager();

        // Add all SCM providers we want to use
        scmManager.setScmProvider("hg", new HgScmProviderExt());
    }

    public ScmManager getScmManager() {
        return scmManager;
    }

    /**
     * Set if the task should use verbose output on Maven SCM framework.
     * 
     * @param value
     * @ant.not-required Default is false
     */
    public void setVerbose(boolean value) {
        verbose = value;
    }

    /**
     * Set the username, this field is required while user requires to be
     * authenticated.
     * 
     * @param username
     *            The user login
     * @ant.not-required
     */
    public void setUsername(String username) {
        this.username = username;
    }

    /**
     * Set the password, this field is required while user requires to be
     * authenticated.
     * 
     * @param password
     *            The user password
     * @ant.not-required
     */
    public void setPassword(String password) {
        this.password = password;
    }
    
    /**
     * Set if the build should keep going while any exception.
     * 
     * @param failonerror
     * @ant.not-required Default is true
     */
    public void setFailonerror(boolean failonerror) {
        this.failonerror = failonerror;
    }

    public String getScmUrl() {
        return scmUrl;
    }

    /**
     * Sets the SCM URL so the task knows what repository to use.
     * 
     * @param scmUrl
     *            The URL to connect to
     * @ant.required
     */
    public void setScmUrl(String scmUrl) {
        this.scmUrl = scmUrl;
    }

    /**
     * Add an SCM add action.
     * 
     * @param action
     *            The add action.
     * @ant.optional
     */
    public void addAdd(AddAction action) {
        addAction(action);
    }

    public void addChangelog(ChangelogAction action) {
        addAction(action);
    }

    public void addBranch(BranchAction action) {
        addAction(action);
    }

    public void addCheckin(CheckinAction action) {
        addAction(action);
    }

    public void addCheckout(CheckoutAction action) {
        addAction(action);
    }

    public void addDiff(DiffAction action) {
        addAction(action);
    }

    public void addRemove(RemoveAction action) {
        addAction(action);
    }

    public void addStatus(StatusAction action) {
        addAction(action);
    }

    public void addUpdate(UpdateAction action) {
        addAction(action);
    }

    public ScmAction[] getActions() {
        return (ScmAction[]) actions.toArray(new ScmAction[0]);
    }

    // Additional actions not supported by the core Maven API

    public void addPull(PullAction action) {
        addAction(action);
    }

    public void addTag(TagAction action) {
        addAction(action);
    }

    public void addTags(TagsAction action) {
        addAction(action);
    }
    
    public void addInfo(InfoAction action) {
        addAction(action);
    }

    public void addInit(InitAction action) {
        addAction(action);
    }

    public void addExport(ExportAction action) {
        addAction(action);
    }

    private void addAction(ScmAction action) {
        action.setTask(this);
        actions.add(action);
    }

    public void add(ScmAction action) {
        addAction(action);
    }

    @Override
    public final void execute() {        
        try {
            log("scm url: " + scmUrl);
            ScmRepository repository = scmManager.makeScmRepository(scmUrl);
            // Process all scm commands
            for (ScmAction action : actions) {
                action.execute(repository);
            }
        } catch (NoSuchScmProviderException ex) {
            throw new BuildException("Could not find a provider.");
        } catch (ScmRepositoryException ex) {
            throw new BuildException(
                    "Error while connecting to the repository: " + ex.getMessage());
        } catch (Exception e) {
          if ( failonerror ) {
            e.printStackTrace();
            throw new BuildException(e.getMessage());
            }
          else {
            e.printStackTrace();
            }
        }
    }
}
