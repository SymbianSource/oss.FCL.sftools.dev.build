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

/**
 *  Class to store the result from the tags operation.
 *
 */
public class TagsScmResult extends ScmResult {
    private List<ScmTag> scmVersions = new ArrayList<ScmTag>();

    /**
     * Default constructor.
     * @param commandLine
     * @param providerMessage
     * @param commandOutput
     * @param success
     */
    public TagsScmResult(String commandLine, String providerMessage,
            String commandOutput, boolean success) {
        super(commandLine, providerMessage, commandOutput, success);
    }

    /**
     * This constructor stores also the ScmTag retrieved.
     * @param commandLine
     * @param providerMessage
     * @param commandOutput
     * @param success
     * @param scmVersions
     */
    public TagsScmResult(String commandLine, String providerMessage,
            String commandOutput, boolean success,
            Enumeration<ScmTag> scmVersions) {
        super(commandLine, providerMessage, commandOutput, success);
        while (scmVersions.hasMoreElements()) {
            ScmTag scmVersion = scmVersions.nextElement();
            this.scmVersions.add(scmVersion);
        }
    }

    /**
     * Get the list of tags from the command.
     * @return
     */
    public List<ScmTag> getTags() {
        return scmVersions;
    }

}
