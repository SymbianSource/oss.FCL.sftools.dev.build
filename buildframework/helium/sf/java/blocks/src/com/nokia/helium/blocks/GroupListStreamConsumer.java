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
package com.nokia.helium.blocks;

import java.util.ArrayList;
import java.util.List;

import org.codehaus.plexus.util.cli.StreamConsumer;

/**
 * Implements group-list results parsing.
 *
 */
public class GroupListStreamConsumer implements StreamConsumer {
    private List<Group> groups = new ArrayList<Group>();

    @Override
    public void consumeLine(String line) {
        if (line.trim().length() > 0) {
            groups.add(new Group(line.trim()));
        }
    }
    
    /**
     * Get the group list from blocks output.
     * @return a list of Group instance.
     */
    public List<Group> getGroups() {
        return groups;
    }
}
