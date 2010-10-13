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
package com.nokia.helium.blocks.ant.types;

import java.util.ArrayList;
import java.util.List;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.ProjectComponent;
import org.apache.tools.ant.types.DataType;

/**
 * Ant type holding a set of repository definitions.
 *
 * Example of use:
 * <pre>
 *      &lt;hlm:blocksRepositorySet id=&quot;my.repo.list.ref.id&quot; &gt;
 *          &lt;repository  name=&quot;repo1&quot; url=&quot;file:e:/repo1&quot;/&gt;
 *          &lt;repository  name=&quot;repo2&quot; url=&quot;file:e:/repo2&quot;/&gt;
 *      &lt;/hlm:blocksRepositorySet&gt; 
 * </pre>
 * 
 * @ant.type name="blocksRepositorySet" category="Blocks"
 */
public class RepositorySet extends DataType {

    private List<Repository> repositories = new ArrayList<Repository>();

    /**
     * Element representing a repository definition.
     *
     */
    public class Repository extends ProjectComponent {
        private String name;
        private String url;
        
        /**
         * The name of the repository.
         * @param name
         */
        public void setName(String name) {
            this.name = name;
        }
        
        public String getName() {
            return name;
        }
        
        /**
         * The location of the repository.
         * @param name
         */
        public void setUrl(String url) {
            this.url = url;
        }
        
        public String getUrl() {
            return url;
        }
    }

    /**
     * Create a nested repository element.
     * @return
     */
    public Repository createRepository() {
        Repository repo = new Repository();
        repositories.add(repo);
        return repo;
    }
    
    /**
     * Get the list of repository definitions.
     * @return
     */
    public List<Repository> getRepositories() {
        if (this.isReference()) {
            if (this.getRefid().getReferencedObject() instanceof RepositorySet) {
                return ((RepositorySet)this.getRefid().getReferencedObject()).getRepositories();
            } else {
                throw new BuildException("The type referenced by " + 
                        this.getRefid().getRefId() + " is not of RepositorySet type.");
            }
        } else {
            return this.repositories;
        }
    }
}
