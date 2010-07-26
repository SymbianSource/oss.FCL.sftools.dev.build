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


package com.nokia.maven.scm.command.info;

import org.apache.maven.scm.ScmResult;

/**
 * A result provided by the 'hg info' command.
 */
public class InfoScmResult extends ScmResult {
    private String scmRevision = new String();
    
    public InfoScmResult(String commandLine, String providerMessage,
            String commandOutput, boolean success) {
        super(commandLine, providerMessage, commandOutput, success);
    }

    public InfoScmResult(String commandLine, String providerMessage,
            String commandOutput, boolean success,
            String scmRevision) {
        super(commandLine, providerMessage, commandOutput, success);        
        this.scmRevision = scmRevision;
        }
    
    public String getRevision() {
        return scmRevision;
    }

}

