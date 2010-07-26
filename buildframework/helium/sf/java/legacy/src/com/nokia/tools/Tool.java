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
 
package com.nokia.tools;

import com.nokia.helium.core.ant.types.VariableSet;
import org.apache.tools.ant.Project;
/**
 * Common interface for the command line tool wrapper
 */
public interface Tool {

    /**
     * Create a task which can be executed based on the input
     * command line variables set using setVariables()
     * @return the task to execute
     */
    void execute(VariableSet varSet, Project prj)throws ToolsProcessException;
}