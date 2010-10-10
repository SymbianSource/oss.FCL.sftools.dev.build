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
 * Implements search results parsing.
 *
 */
public class SearchStreamConsumer implements StreamConsumer  {
    private static final String SEPARATOR = " - ";
    private List<String> results = new ArrayList<String>();
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void consumeLine(String line) {
        if (line.contains(SEPARATOR)) {
            results.add(line.substring(0, line.indexOf(SEPARATOR)));
        }
    }
    
    /**
     * Get the search result list.
     * @return
     */
    public List<String> getSearchResults() {
        return results;
    }

}
