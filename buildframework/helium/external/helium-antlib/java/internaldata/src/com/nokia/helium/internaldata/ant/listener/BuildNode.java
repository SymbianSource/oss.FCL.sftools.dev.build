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

package com.nokia.helium.internaldata.ant.listener;

import org.apache.tools.ant.Project;
/**
 * Keeps data for a build node.
 *
 */
public class BuildNode extends DataNode {
    
    private boolean successful = true;
    private String name;
    
    public BuildNode(DataNode parent, Project project) {
        super(parent, project);
        name = project.getName();
    }

    public String getName() {
        if (name != null)
            return name;
        return "build";
    } 

    public boolean getSuccessful() {
        return successful;
    }

    public void setSuccessful(boolean successful) {
        this.successful = successful;
    }

}
