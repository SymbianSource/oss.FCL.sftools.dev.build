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


package com.nokia.helium.core.ant.types;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.ant.HlmDefinition;

/**
 * Implement an abstract pre-action.
 */
public class HlmPreDefImpl extends DataType implements HlmDefinition {
    /**
     * Do nothing.
     */
    public void execute(Project prj, String module, String[] targetNames) {
        // empty will implemented by the sub classes.
    }
}