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


package com.nokia.maven.scm.command.tags;

import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;

import org.apache.maven.scm.ScmResult;
import org.apache.maven.scm.ScmTag;

public class TagsScmResult extends ScmResult {
    private List<ScmTag> scmVersions = new ArrayList<ScmTag>();

    public TagsScmResult(String commandLine, String providerMessage,
            String commandOutput, boolean success) {
        super(commandLine, providerMessage, commandOutput, success);
    }

    public TagsScmResult(String commandLine, String providerMessage,
            String commandOutput, boolean success,
            Enumeration<ScmTag> scmVersions) {
        super(commandLine, providerMessage, commandOutput, success);
        while (scmVersions.hasMoreElements()) {
            ScmTag scmVersion = scmVersions.nextElement();
            this.scmVersions.add(scmVersion);
        }
    }

    public List<ScmTag> getTags() {
        return scmVersions;
    }

}
