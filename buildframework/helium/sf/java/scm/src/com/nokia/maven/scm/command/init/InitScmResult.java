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


package com.nokia.maven.scm.command.init;

import org.apache.maven.scm.ScmResult;

/**
 * Class to store the result of the init command.  
 *
 */
public class InitScmResult extends ScmResult {
    
    /**
     * {@inheritDoc}
     */
    public InitScmResult(String commandLine, String providerMessage,
            String commandOutput, boolean success) {
        super(commandLine, providerMessage, commandOutput, success);
    }
}
