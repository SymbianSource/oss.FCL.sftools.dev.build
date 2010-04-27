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
 * This interface defines the API of an HeliumExecutor task. 
 */
public interface HlmDefinition {
    
    /**
     * This method will implement the action to be performed by the 
     * HeliumExecutor plugin. 
     * @param prj
     * @param module
     */
    void execute(Project prj, String module, String[] targetNames);
}