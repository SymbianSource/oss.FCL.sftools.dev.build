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
package com.nokia.helium.blocks;

import java.util.ArrayList;
import java.util.List;

import org.codehaus.plexus.util.cli.StreamConsumer;

/**
 * Implements repo-list results parsing.
 *
 */
public class RepositoryListStreamConsumer implements StreamConsumer  {
    private List<Repository> repositories = new ArrayList<Repository>();
    private Repository repository;
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void consumeLine(String line) {
        if (repository == null && line.matches("^\\d+\\*?$")) {
            repository = new Repository();
            repository.setId(Integer.parseInt(line.trim().replaceAll("\\*", "")));
        } else if (repository != null && line.matches("^\\s+Name:\\s+.+$")) {
            repository.setName(line.split("Name:")[1].trim());
        } else if (repository != null && line.matches("^\\s+URI:\\s+.+$")) {
            repository.setUrl(line.split("URI:")[1].trim());
            repositories.add(repository);
            repository = null;
        }
    }
    
    /**
     * Get the list of repositories found.
     * @return the list of repositories.
     */
    public List<Repository> getRepositories() {
        return repositories;
    }

}
