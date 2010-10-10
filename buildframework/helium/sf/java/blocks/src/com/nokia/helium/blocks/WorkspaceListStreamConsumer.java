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
import java.util.Vector;

import org.codehaus.plexus.util.cli.StreamConsumer;

/**
 * Implements a parser of workspace list calls. 
 *
 */
public class WorkspaceListStreamConsumer implements  StreamConsumer {

    private Workspace workspace;
    private Vector<Workspace> workspaces = new Vector<Workspace>();
    
    @Override
    public void consumeLine(String line) {
        if (workspace == null && line.matches("^\\d+\\*?$")) {
            workspace = new Workspace();
            workspace.setWsid(Integer.parseInt(line.trim().replaceAll("\\*", "")));
        } else if (workspace != null && line.matches("^\\s+name:\\s+.+$")) {
            workspace.setName(line.split("name:")[1].trim());
        } else if (workspace != null && line.matches("^\\s+path:\\s+.+$")) {
            workspace.setLocation(new File(line.split("path:")[1].trim()));
            workspaces.add(workspace);
            workspace = null;
        }
    }
    
    /**
     * Returns the list of found workspaces.
     * @return
     */
    public Workspace[] getWorkspaces() {
        return workspaces.toArray(new Workspace[workspaces.size()]);        
    }
}
