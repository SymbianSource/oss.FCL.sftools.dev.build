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
import org.apache.log4j.Logger;

import com.nokia.helium.core.ant.HeliumExecutor;
import com.nokia.helium.core.ant.HlmDefinition;

/**
 * Implement an abstract post-action.
 */
public class HlmPostDefImpl extends DataType implements HlmDefinition {
    private Logger log = Logger.getLogger(HeliumExecutor.class);

    /**
     * Do nothing.
     */
    public void execute(Project prj, String module, String[] targetNames) {
        // Empty method. Implemented by extending classes.
    }
}