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
package com.nokia.helium.core.ant;

import org.apache.tools.ant.Project;

/**
 * This interface defines the API of an HeliumExecutor task. The Sub classes
 * performing any pre build actions should implement this interface.
 * 
 */
public interface PreBuildAction {

    /**
     * Method executes a pre build action.
     * 
     * @param project
     *            is the ant project.
     * @param targetNames
     *            an array of target names.
     */
    void executeOnPreBuild(Project project, String[] targetNames);
}
