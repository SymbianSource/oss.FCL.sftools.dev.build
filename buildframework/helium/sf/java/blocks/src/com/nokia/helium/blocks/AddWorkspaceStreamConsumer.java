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

import org.codehaus.plexus.util.cli.StreamConsumer;

/**
 * Implements a parser of add workspace calls. 
 *
 */
public class AddWorkspaceStreamConsumer implements StreamConsumer {

    public static final String MARKER = "Workspace id: ";
    private int wsid;
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void consumeLine(String line) {
        // Workspace id: 2
        if (line.startsWith(MARKER)) {
            wsid = Integer.valueOf(line.substring(MARKER.length()));
        }
    }
    
    /**
     * Get the discovered workspace ID.
     * @return the workspace ID. Zero value means an invalid ID.
     */
    public int getWsid() {
        return wsid;
    }

}
