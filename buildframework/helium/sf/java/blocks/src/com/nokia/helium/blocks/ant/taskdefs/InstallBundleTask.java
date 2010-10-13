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
package com.nokia.helium.blocks.ant.taskdefs;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.PatternSet;

import com.nokia.helium.blocks.Blocks;
import com.nokia.helium.blocks.BlocksException;
import com.nokia.helium.blocks.Group;
import com.nokia.helium.blocks.ant.AbstractBlocksTask;

/**
 * Installing a bundle under a workspace.
 * 
 * The bundle &quot;my-bundle-name&quot; will be installed under the workspace 1:
 * <pre>
 * &lt;hlm:blocksInstallBundle wsid=&quot;1&quot; bundle=&quot;my-bundle-name&quot; /&gt; 
 * </pre>
 * 
 * The bundles matching the &quot;my-bundle-name.*&quot; pattern will be installed under the workspace 1:
 * <pre>
 * &lt;hlm:blocksInstallBundle wsid=&quot;1&quot;&gt;
 *      &lt;bundleFilterSet&gt;
 *          &lt;include name=&quot;my-bundle-name.*&quot; /&gt;
 *          &lt;include name=&quot;.*src.*&quot; /&gt;
 *      &lt;/bundleFilterSet&gt; 
 * &lt;/hlm:blocksInstallBundle&gt;
 * </pre>
 * 
 * The groups matching the &quot;.*bin.*&quot; pattern will be installed under the workspace 1:
 * <pre>
 * &lt;hlm:blocksInstallBundle wsid=&quot;1&quot;&gt;
 *      &lt;groupFilterSet&gt;
 *          &lt;include name=&quot;.*bin.*&quot; /&gt;
 *      &lt;/groupFilterSet&gt; 
 * &lt;/hlm:blocksInstallBundle&gt;
 * </pre>
 * 
 * bundleFilterSet and groupFilterSet are regular patternset, so any reference to patternset 
 * will be working:
 * <pre>
 * &lt;patternset id=&quot;my.patternset&quot; /&gt;
 * ...
 *    &lt;groupFilterSet refid=&quot;my.patternset&quot; /&gt;
 * ...
 * </pre>
 * 
 * @ant.task name="blocksInstallBundle" category="Blocks"
 */
public class InstallBundleTask extends AbstractBlocksTask {
    private String group;
    private String bundle;
    private List<PatternSet> bundlePatternSets = new ArrayList<PatternSet>();
    private List<PatternSet> groupPatternSets = new ArrayList<PatternSet>();

    protected void validate() {
        if ((bundle != null && (!bundlePatternSets.isEmpty() || group != null || !groupPatternSets.isEmpty()))
                || (group != null && (!bundlePatternSets.isEmpty() || bundle != null || !groupPatternSets.isEmpty()))
                || (!bundlePatternSets.isEmpty() && (group != null || bundle != null || !groupPatternSets.isEmpty()))
                || (!groupPatternSets.isEmpty() && (group != null || bundle != null || !bundlePatternSets.isEmpty()))
                || (bundle == null && bundlePatternSets.isEmpty() && group == null && groupPatternSets.isEmpty())) {
            throw new BuildException("You can either use the bundle attribute or the group attribute or use nested groupfilterset or bundlefilterset.");
        }        
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void execute() {
        validate();
        try {
            if (bundle != null) {
                log("Installing bundle " + bundle + " under workspace " + this.getWsid() + ".");
                getBlocks().installBundle(this.getWsid(), bundle);
            } else if (!bundlePatternSets.isEmpty()) {
                for (String bundle : getBlocks().search(this.getWsid(), Blocks.SEARCH_ALL_BUNDLES_EXPRESSION)) {
                    if (shouldInstall(bundlePatternSets, bundle)) {
                        log("Installing " + bundle + " under workspace " + this.getWsid() + ".");
                        getBlocks().installBundle(this.getWsid(), bundle);
                    } else {
                        log("Skipping bundle " + bundle, Project.MSG_DEBUG);
                    }
                }                
            } else if (group != null) {
                log("Installing group " + group + " under workspace " + this.getWsid() + ".");
                getBlocks().installGroup(this.getWsid(), group);
            } else if (!groupPatternSets.isEmpty()) {
                for (Group group : getBlocks().listGroup(this.getWsid())) {
                    if (shouldInstall(groupPatternSets, group.getName())) {
                        log("Installing group " + group.getName() + " under workspace " + this.getWsid() + ".");
                        getBlocks().installGroup(this.getWsid(), group.getName());
                    } else {
                        log("Skipping group " + bundle, Project.MSG_DEBUG);
                    }
                }
            }                
        } catch (BlocksException e) {
            throw new BuildException(e.getMessage(), e);
        }
    }

    /**
     * Defines the bundle name to install.
     * @param bundle
     * @ant.required
     */
    public void setBundle(String bundle) {
        this.bundle = bundle;
    }    

    /**
     * Defines the bundle name to install.
     * @param bundle
     * @ant.required
     */
    public void setGroup(String group) {
        this.group = group;
    }    
    
    /**
     * Add a nested patternset. Then bundle attribute cannot be used.
     * @param patternSet
     */
    public PatternSet createBundleFilterSet() {
        PatternSet patternSet = new PatternSet(); 
        bundlePatternSets.add(patternSet);
        return patternSet;
    }

    /**
     * Add a nested patternset. Then bundle attribute cannot be used.
     * @param patternSet
     */
    public PatternSet createGroupFilterSet() {
        PatternSet patternSet = new PatternSet(); 
        groupPatternSets.add(patternSet);
        return patternSet;
    }
    
    /**
     * Should the bundle be installed based on the patternsets config.
     * @param patternSets a list of patternset elements
     * @param name the name to validate
     * @return 
     */
    protected boolean shouldInstall(List<PatternSet> patternSets, String name) {
        int includes = 0;
        for (PatternSet patternSet : patternSets) {
            if (patternSet.getExcludePatterns(getProject()) != null) {
                for (String pattern : patternSet.getExcludePatterns(getProject())) {
                    if (Pattern.matches(pattern, name)) {
                        return false;
                    }
                }
            }
            if (patternSet.getIncludePatterns(getProject()) != null) {
                for (String pattern : patternSet.getIncludePatterns(getProject())) {
                    includes ++;
                    if (Pattern.matches(pattern, name)) {
                        return true;
                    }
                }
            }
        }
        return includes == 0;
    }
}
