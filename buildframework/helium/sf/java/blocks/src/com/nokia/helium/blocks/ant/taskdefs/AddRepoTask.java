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

import org.apache.tools.ant.BuildException;

import com.nokia.helium.blocks.BlocksException;
import com.nokia.helium.blocks.ant.AbstractBlocksTask;
import com.nokia.helium.blocks.ant.types.RepositorySet;
import com.nokia.helium.blocks.ant.types.RepositorySet.Repository;

/**
 * Adding repository to a workspace.
 * 
 * Adding a repository with generated name:
 * <pre>
 * &lt;hlm:blocksAddRepository wsid=&quot;1&quot; url=&quot;file:e:/repo&quot; /&gt; 
 * </pre>
 * 
 * Adding repository with a given name:
 * <pre>
 * &lt;hlm:blocksAddRepository wsid=&quot;1&quot; name=&quot;repo1&quot; url=&quot;file:e:/repo1&quot; /&gt; 
 * </pre>
 * 
 * Adding several repositories using nested repositorySet elements:
 * <pre>
 * &lt;hlm:blocksAddRepository wsid=&quot;1&quot;&gt;
 *      &lt;repositorySet&gt;
 *          &lt;repository  name=&quot;repo1&quot; url=&quot;file:e:/repo1&quot;/&gt;
 *          &lt;repository  name=&quot;repo2&quot; url=&quot;file:e:/repo2&quot;/&gt;
 *      &lt;/repositorySet&gt; 
 * &lt;/hlm:blocksAddRepository&gt;
 * </pre>

 * @ant.task name="blocksAddRepository" category="Blocks"
 */
public class AddRepoTask extends AbstractBlocksTask {
    private String url;
    private String name;
    private List<RepositorySet> repositorySets = new ArrayList<RepositorySet>();
    
    /**
     * Add this repository URL to the 
     * workspace.
     * @param url
     */
    public void setUrl(String url) {
        this.url = url;
    }
    
    /**
     * Name of this repository. 
     * @param name
     * @ant.not-required Blocks will generate a name.
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * Adding a nested RepositorySet element.
     * @return a new RepositorySet instance.
     */
    public RepositorySet createRepositorySet() {
        RepositorySet repositorySet = new RepositorySet();
        this.add(repositorySet);
        return repositorySet;
    }

    /**
     * Adding a nested RepositorySet element.
     * @param repositorySet
     */
    public void add(RepositorySet repositorySet) {
        repositorySets.add(repositorySet);
    }
    
    /**
     * {@inheritDoc}
     */
    public void execute() {
        if (url == null && repositorySets.isEmpty()) {
            throw new BuildException("'url' attribute has not been defined.");            
        }
        if (url != null && !repositorySets.isEmpty()) {
            throw new BuildException("'url' attribute and nested repositorySet element cannot be used at the same time.");
        }
        try {
            if (url != null) {
                if (name == null) {
                    getBlocks().addRepository(getWsid(), url);
                    log("The repository " + url + " has been added successfully to workspace " + getWsid() + ".");
                } else {
                    getBlocks().addRepository(getWsid(), name, url);
                    log("The repository " + name + " => " + url +
                        " has been added successfully to workspace " + getWsid() + ".");
                }
            } else {
                for (RepositorySet repositorySet : repositorySets) {
                    for (Repository repository : repositorySet.getRepositories()) {
                        if (repository.getName() == null || repository.getUrl() == null) {
                            throw new BuildException("Either name or url attribute missing at " + repository.getLocation());
                        }
                        getBlocks().addRepository(getWsid(), repository.getName(), repository.getUrl());                        
                    }
                }
            }
        } catch (BlocksException e) {
            throw new BuildException(e.getMessage(), e);
        }
    }
    

}
