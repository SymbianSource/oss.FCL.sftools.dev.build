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

import java.io.File;
import java.util.List;

import com.nokia.helium.core.plexus.CommandBase;

/**
 * This class is the base abstraction layer for invoking
 * Blocks commands.
 *
 */
public class Blocks extends CommandBase<BlocksException> {
    public static final String SEARCH_ALL_BUNDLES_EXPRESSION = ".";
    private String executable = "blocks";
    
    /**
     * Default constructor.
     */
    public Blocks() {
    }

    /**
     * New blocks instance with proper blocks script location. 
     * @param executable
     */
    public Blocks(String executable) {
        this.executable = executable;
    }
      
    /**
     * Add a new Blocks workspace.
     * @param location the location of the workspace
     * @param name the name of the workspace 
     * @return a Workspace object
     * @throws BlocksException
     */
    public Workspace addWorkspace(File location, String name) throws BlocksException {
        String[] args = new String[3];
        args[0] = "workspace-add";
        args[1] = location.getAbsolutePath();
        args[2] = "--name=" + name;
        AddWorkspaceStreamConsumer consumer = new AddWorkspaceStreamConsumer();
        execute(args, consumer);
        
        Workspace workspace = new Workspace();
        workspace.setWsid(consumer.getWsid());
        workspace.setLocation(location);
        workspace.setName(name);
        return workspace;
    }

    /**
     * Remove a workspace.
     * @param wsid the id of the workspace to remove.
     * @throws BlocksException
     */
    public void removeWorkspace(int wsid) throws BlocksException {
        String[] args = new String[3];
        args[0] = "--force";
        args[1] = "workspace-remove";
        args[2] = "" + wsid;
        execute(args);
    }

    /**
     * List all existing workspaces.
     * @return an array of Workspace objects.
     * @throws BlocksException
     */
    public Workspace[] listWorkspaces() throws BlocksException {
        String[] args = new String[1];
        args[0] = "workspace-list";
        WorkspaceListStreamConsumer consumer = new WorkspaceListStreamConsumer();
        execute(args, consumer);
        return consumer.getWorkspaces();
    }

    /**
     * Search for a bundles matching the expression.
     * @param expression the expression to match
     * @return a list of string representing the list of bundles.
     * @throws BlocksException in case of execution errors.
     */
    public List<String> search(int wsid, String expression) throws BlocksException {
        String[] args = new String[3];
        args[0] = "--wsid=" + wsid;
        args[1] = "search";
        args[2] = expression;
        SearchStreamConsumer consumer = new SearchStreamConsumer();
        execute(args, consumer);
        return consumer.getSearchResults();        
    }

    /**
     * Installing a bundles defines by a name.
     * @param bundleName the name of the bundle to install
     * @throws BlocksException
     */
    public void installBundle(int wsid, String bundleName) throws BlocksException {
        String[] args = new String[4];
        args[0] = "--wsid=" + wsid;
        args[1] = "--force";
        args[2] = "bundle-install";
        args[3] = bundleName;
        execute(args);
    }
    
    /**
     * Installing a bundles defines by a group name.
     * @param groupName the group name to install
     * @throws BlocksException
     */
    public void installGroup(int wsid, String groupName) throws BlocksException {
        String[] args = new String[4];
        args[0] = "--wsid=" + wsid;
        args[1] = "--force";
        args[2] = "group-install";
        args[3] = groupName;
        execute(args);
    }
    
    /**
     * Get the list of groups available.
     * @return
     * @throws BlocksException
     */
    public List<Group> listGroup(int wsid) throws BlocksException {
        String[] args = new String[2];
        args[0] = "--wsid=" + wsid;
        args[1] = "group-list";
        GroupListStreamConsumer consumer = new GroupListStreamConsumer();
        execute(args, consumer);
        return consumer.getGroups();        
    }
    
    /**
     * Add a repository to a workspace, using a generated name.
     * @param wsid
     * @param url
     * @throws BlocksException
     */
    public void addRepository(int wsid, String url) throws BlocksException {
        String[] args = new String[4];
        args[0] = "--wsid=" + wsid;
        args[1] = "--force";
        args[2] = "repo-add";
        args[3] = url;
        execute(args);
    }

    /**
     * Add a repository to a workspace, using a given name.
     * @param wsid the workspace id
     * @param name the repository name
     * @param url the repository location.
     * @throws BlocksException
     */
    public void addRepository(int wsid, String name, String url) throws BlocksException {
        String[] args = new String[5];
        args[0] = "--wsid=" + wsid;
        args[1] = "--force";
        args[2] = "repo-add";
        args[3] = "--name=" + name;
        args[4] = url;
        execute(args);
    }

    /**
     * Remove a repository base on its id.
     * @param wsid the workspace id
     * @param id the repository id to remove
     * @throws BlocksException
     */
    public void removeRepository(int wsid, int id) throws BlocksException {
        String[] args = new String[4];
        args[0] = "--wsid=" + wsid;
        args[1] = "--force";
        args[2] = "repo-remove";
        args[3] = "" + id;
        execute(args);
    }

    /**
     * Remove a repository base on its name.
     * @param wsid the workspace id
     * @param name the repository name to remove
     * @throws BlocksException
     */
    public void removeRepository(int wsid, String name) throws BlocksException {
        String[] args = new String[3];
        args[0] = "--wsid=" + wsid;
        args[1] = "repo-remove";
        args[2] = name;
        execute(args);
    }

    /**
     * Get the repository list for current workspace.
     * @param wsid the current workspace id.
     * @return the repository list
     * @throws BlocksException
     */
    public List<Repository> listRepository(int wsid) throws BlocksException {
        String[] args = new String[2];
        args[0] = "--wsid=" + wsid;
        args[1] = "repo-list";        
        RepositoryListStreamConsumer consumer = new RepositoryListStreamConsumer();
        execute(args, consumer);
        return consumer.getRepositories();
    }

    /**
     * Updating the workspace pointed by wsid.
     * @param wsid the workspace id to update
     * @throws BlocksException 
     */
    public void update(int wsid) throws BlocksException {
        String[] args = new String[3];
        args[0] = "--wsid=" + wsid;
        args[1] = "--force";
        args[2] = "update";        
        execute(args);
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    protected String getExecutable() {
        return executable;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    protected void throwException(String message, Throwable t) throws BlocksException {
        throw new BlocksException(message, t);
    }
}
